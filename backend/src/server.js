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
    const profiles = mongoClient
      .db(requiredEnv('MONGODB_DB'))
      .collection('users');
    const app = createApp({
      profiles,
      verifyIdToken: (token) => getAuth().verifyIdToken(token),
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
