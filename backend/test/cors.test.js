import assert from 'node:assert/strict';
import { once } from 'node:events';
import { test } from 'node:test';

import { createApp } from '../src/app.js';

async function startServer(t, options = {}) {
  const app = createApp({
    verifyIdToken: async () => {
      throw new Error('bad token');
    },
    ...options,
  });
  const server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  t.after(() => new Promise((resolve) => server.close(resolve)));
  return `http://127.0.0.1:${server.address().port}`;
}

const allowOrigin = async (baseUrl, origin) =>
  (await fetch(`${baseUrl}/health`, { headers: { Origin: origin } })).headers.get(
    'access-control-allow-origin',
  );

test('CORS allows localhost and configured origins but not strangers', async (t) => {
  const baseUrl = await startServer(t, {
    corsOrigins: ['https://novelly.example.com'],
  });

  assert.equal(await allowOrigin(baseUrl, 'http://localhost:51234'), 'http://localhost:51234');
  assert.equal(
    await allowOrigin(baseUrl, 'https://novelly.example.com'),
    'https://novelly.example.com',
  );
  assert.equal(await allowOrigin(baseUrl, 'https://evil.example.com'), null);
});

test('CORS preflight for an authenticated JSON call succeeds from a browser', async (t) => {
  const baseUrl = await startServer(t);
  const response = await fetch(`${baseUrl}/api/profile`, {
    method: 'OPTIONS',
    headers: {
      Origin: 'http://localhost:51234',
      'Access-Control-Request-Method': 'PUT',
      'Access-Control-Request-Headers': 'authorization,content-type',
    },
  });

  assert.equal(response.status, 204);
  assert.match(response.headers.get('access-control-allow-headers'), /authorization/i);
  assert.match(response.headers.get('access-control-allow-methods'), /PUT/);
});

test('localhost origins can be switched off for production', async (t) => {
  const baseUrl = await startServer(t, { allowLocalhostOrigins: false });
  assert.equal(await allowOrigin(baseUrl, 'http://localhost:3000'), null);
});

test('requests without an Origin header (the Android app) still work', async (t) => {
  const baseUrl = await startServer(t, { allowLocalhostOrigins: false });
  const response = await fetch(`${baseUrl}/health`);
  assert.equal(response.status, 200);
});
