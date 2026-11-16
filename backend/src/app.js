import express from 'express';

const allowedRoles = new Set([
  'Writer',
  'Publisher',
  'Cover Artist',
  'Writer and Publisher',
]);

export function createApp({ profiles, verifyIdToken }) {
  const app = express();

  app.use(express.json({ limit: '16kb' }));

  app.get('/health', (_request, response) => {
    response.json({ status: 'ok' });
  });

  app.use('/api', async (request, response, next) => {
    const authorization = request.get('authorization') ?? '';
    const match = /^Bearer\s+([^\s]+)$/i.exec(authorization);

    if (!match) {
      return response.status(401).json({ error: 'A Firebase ID token is required.' });
    }

    try {
      request.auth = await verifyIdToken(match[1]);
      if (typeof request.auth?.uid !== 'string' || request.auth.uid.length === 0) {
        return response.status(401).json({ error: 'The Firebase ID token is invalid.' });
      }
      return next();
    } catch {
      return response.status(401).json({ error: 'The Firebase ID token is invalid or expired.' });
    }
  });

  app.get('/api/profile', async (request, response) => {
    const profile = await profiles.findOne(
      { _id: request.auth.uid },
      { projection: { _id: 0 } },
    );

    if (!profile) {
      return response.status(404).json({ error: 'No database profile exists for this account.' });
    }
    return response.json(profile);
  });

  app.put('/api/profile', async (request, response) => {
    const name = typeof request.body?.name === 'string'
      ? request.body.name.trim()
      : '';
    const role = request.body?.role;
    const email = typeof request.auth.email === 'string'
      ? request.auth.email.trim().toLowerCase()
      : '';

    if (!name || name.length > 80) {
      return response.status(400).json({ error: 'Name must be between 1 and 80 characters.' });
    }
    if (!allowedRoles.has(role)) {
      return response.status(400).json({ error: 'Choose a valid account role.' });
    }
    if (!email) {
      return response.status(400).json({ error: 'The Firebase account must have an email address.' });
    }

    const now = new Date();
    const result = await profiles.updateOne(
      { _id: request.auth.uid },
      {
        $setOnInsert: {
          _id: request.auth.uid,
          uid: request.auth.uid,
          name,
          email,
          role,
          createdAt: now,
        },
      },
      { upsert: true },
    );
    const profile = await profiles.findOne(
      { _id: request.auth.uid },
      { projection: { _id: 0 } },
    );

    if (!profile) {
      throw new Error('Profile upsert completed without a readable profile.');
    }

    return response.status(result.upsertedCount === 1 ? 201 : 200).json(profile);
  });

  app.use((error, _request, response, _next) => {
    if (error instanceof SyntaxError && 'body' in error) {
      return response.status(400).json({ error: 'Request body must be valid JSON.' });
    }
    console.error(error);
    return response.status(500).json({ error: 'Internal server error.' });
  });

  return app;
}
