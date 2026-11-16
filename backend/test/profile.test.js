import assert from 'node:assert/strict';
import { once } from 'node:events';
import { test } from 'node:test';

import { createApp } from '../src/app.js';

async function startTestServer(t, { authenticated = true } = {}) {
  const storedProfiles = new Map();
  const profiles = {
    async findOne(filter) {
      return storedProfiles.get(filter._id) ?? null;
    },
    async updateOne(filter, update) {
      if (storedProfiles.has(filter._id)) {
        return { upsertedCount: 0 };
      }
      storedProfiles.set(filter._id, update.$setOnInsert);
      return { upsertedCount: 1 };
    },
  };
  const app = createApp({
    profiles,
    verifyIdToken: async (token) => {
      if (!authenticated || token !== 'valid-token') {
        throw new Error('Invalid test token.');
      }
      return { uid: 'firebase-user-1', email: 'reader@example.com' };
    },
  });
  const server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  t.after(() => new Promise((resolve, reject) => {
    server.close((error) => error ? reject(error) : resolve());
  }));
  return `http://127.0.0.1:${server.address().port}`;
}

test('profile writes require a valid Firebase token', async (t) => {
  const baseUrl = await startTestServer(t, { authenticated: false });
  const response = await fetch(`${baseUrl}/api/profile`, {
    method: 'PUT',
    headers: {
      Authorization: 'Bearer invalid-token',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ name: 'Reader', role: 'Writer' }),
  });

  assert.equal(response.status, 401);
});

test('profile creation uses the verified Firebase UID and does not overwrite roles', async (t) => {
  const baseUrl = await startTestServer(t);
  const headers = {
    Authorization: 'Bearer valid-token',
    'Content-Type': 'application/json',
  };
  const firstResponse = await fetch(`${baseUrl}/api/profile`, {
    method: 'PUT',
    headers,
    body: JSON.stringify({
      uid: 'untrusted-user-id',
      name: '  Sam Reader  ',
      role: 'Writer',
    }),
  });
  const firstProfile = await firstResponse.json();

  assert.equal(firstResponse.status, 201);
  assert.equal(firstProfile.uid, 'firebase-user-1');
  assert.equal(firstProfile.name, 'Sam Reader');

  const getResponse = await fetch(`${baseUrl}/api/profile`, {
    headers: { Authorization: 'Bearer valid-token' },
  });
  const fetchedProfile = await getResponse.json();

  assert.equal(getResponse.status, 200);
  assert.equal(fetchedProfile.uid, 'firebase-user-1');

  const secondResponse = await fetch(`${baseUrl}/api/profile`, {
    method: 'PUT',
    headers,
    body: JSON.stringify({ name: 'Another Name', role: 'Publisher' }),
  });
  const secondProfile = await secondResponse.json();

  assert.equal(secondResponse.status, 200);
  assert.equal(secondProfile.name, 'Sam Reader');
  assert.equal(secondProfile.role, 'Writer');
});

test('profile lookup returns 404 when the account has no MongoDB profile', async (t) => {
  const baseUrl = await startTestServer(t);
  const response = await fetch(`${baseUrl}/api/profile`, {
    headers: { Authorization: 'Bearer valid-token' },
  });

  assert.equal(response.status, 404);
});
