import dotenv from 'dotenv';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { cert, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { MongoClient } from 'mongodb';

import { createApp } from './app.js';

const backendDirectory = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(backendDirectory, '../.env.local') });

function requiredEnv(name) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

async function start() {
  const port = Number(process.env.PORT ?? 3000);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('PORT must be an integer between 1 and 65535.');
  }

  const projectId = requiredEnv('FIREBASE_PROJECT_ID');
  const clientEmail = requiredEnv('FIREBASE_CLIENT_EMAIL');
  const privateKey = requiredEnv('FIREBASE_PRIVATE_KEY').replace(/\\n/g, '\n');
  initializeApp({
    credential: cert({ projectId, clientEmail, privateKey }),
    projectId,
  });

  const mongoClient = new MongoClient(requiredEnv('MONGODB_URI'), {
    serverSelectionTimeoutMS: 10000,
  });

  try {
    await mongoClient.connect();
    const database = mongoClient.db(requiredEnv('MONGODB_DB'));
    const profiles = database.collection('users');
    const books = database.collection('books');
    const coverDesigns = database.collection('coverDesigns');
    const publisherBooks = database.collection('publisherBooks');
    const publisherWorkspaces = database.collection('publisherWorkspaces');
    const conversations = database.collection('conversations');
    const messages = database.collection('messages');
    await books.createIndex({ authorUid: 1, createdAt: -1 });
    await books.createIndex({ status: 1, createdAt: -1 });
    await coverDesigns.createIndex({ ownerUid: 1, createdAt: -1 });
    await coverDesigns.createIndex({ status: 1, createdAt: -1 });
    await publisherBooks.createIndex({ ownerUid: 1, createdAt: -1 });
    await publisherBooks.createIndex({ status: 1, createdAt: -1 });
    await conversations.createIndex({ participantUids: 1, updatedAt: -1 });
    await messages.createIndex({ conversationId: 1, sentAt: 1 });
    const app = createApp({
      profiles,
      books,
      coverDesigns,
      publisherBooks,
      publisherWorkspaces,
      conversations,
      messages,
      verifyIdToken: (token) => getAuth().verifyIdToken(token),
      corsOrigins: (process.env.CORS_ORIGINS ?? '')
        .split(',')
        .map((origin) => origin.trim())
        .filter(Boolean),
      // Set ALLOW_LOCALHOST_ORIGINS=false in production.
      allowLocalhostOrigins: process.env.ALLOW_LOCALHOST_ORIGINS !== 'false',
    });
    const server = app.listen(port, '0.0.0.0', () => {
      console.log(`Novelly API listening on port ${port}`);
    });

    const shutdown = async () => {
      server.close(async (error) => {
        await mongoClient.close();
        if (error) {
          console.error('Error while closing the API server:', error);
          process.exitCode = 1;
        }
      });
    };

    process.once('SIGINT', shutdown);
    process.once('SIGTERM', shutdown);
  } catch (error) {
    await mongoClient.close();
    throw error;
  }
}

start().catch((error) => {
  console.error('Failed to start Novelly API:', error);
  process.exitCode = 1;
});
