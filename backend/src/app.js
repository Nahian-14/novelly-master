import { randomUUID } from 'node:crypto';

import cors from 'cors';
import express from 'express';

const localhostOrigin = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;

/**
 * Browsers (Flutter web) block calls to this API unless it sends CORS headers.
 * `flutter run -d chrome` picks a random localhost port, so any localhost
 * origin is allowed unless `allowLocalhostOrigins` is false. Add your deployed
 * site(s) through `corsOrigins` (the CORS_ORIGINS environment variable).
 * The Android app is not a browser and is not affected by CORS.
 */
function buildCors({ corsOrigins, allowLocalhostOrigins }) {
  const allowed = new Set(corsOrigins);
  return cors({
    origin(origin, callback) {
      if (!origin) return callback(null, true);
      return callback(
        null,
        allowed.has(origin) ||
          (allowLocalhostOrigins && localhostOrigin.test(origin)),
      );
    },
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Authorization', 'Content-Type'],
    maxAge: 600,
  });
}

const allowedRoles = new Set([
  'Writer',
  'Publisher',
  'Cover Artist',
  'Writer and Publisher',
]);

function cleanText(value, maxLength) {
  return typeof value === 'string' ? value.trim().slice(0, maxLength) : '';
}

const publicCollections = new Map([
  ['books', 'books'],
  ['cover-designs', 'coverDesigns'],
  ['publisher-books', 'publisherBooks'],
]);

function parseImage(body, field = 'imageBase64') {
  const encoded = body?.[field];
  if (encoded == null || encoded === '') return {};
  const contentType = body?.[`${field}ContentType`];
  if (!['image/jpeg', 'image/png', 'image/webp'].includes(contentType)) {
    throw new TypeError('Image must be a JPEG, PNG, or WebP file.');
  }
  if (
    typeof encoded !== 'string'
    || !/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(encoded)
  ) {
    throw new TypeError('Image data is invalid.');
  }
  const data = Buffer.from(encoded, 'base64');
  if (data.length === 0 || data.length > 4 * 1024 * 1024) {
    throw new RangeError('Image must be smaller than 4 MB.');
  }
  return { imageData: data, imageContentType: contentType };
}

function storedImageBuffer(value) {
  if (Buffer.isBuffer(value) || value instanceof Uint8Array) {
    return Buffer.from(value);
  }
  if (value && value.buffer instanceof Uint8Array) {
    const length = Number.isInteger(value.position)
      ? value.position
      : value.buffer.byteLength;
    return Buffer.from(value.buffer.buffer, value.buffer.byteOffset, length);
  }
  throw new TypeError('Stored image data is not binary.');
}

function contentResponse(content, collection, { includeImage = false } = {}) {
  const imageData = content.imageData
    ? storedImageBuffer(content.imageData)
    : null;
  return {
    id: content._id,
    creatorUid: content.ownerUid ?? content.authorUid ?? null,
    ...Object.fromEntries(
      Object.entries(content).filter(([key]) =>
        !['_id', 'imageData', 'imageContentType', 'ownerUid'].includes(key),
      ),
    ),
    imageContentType: content.imageContentType ?? null,
    imageUrl: imageData
      ? `/public/media/${collection}/${content._id}`
      : null,
    ...(includeImage && content.imageData
      ? { imageBase64: imageData.toString('base64') }
      : {}),
  };
}

function publicProfile(profile) {
  const allowedFields = [
    'uid',
    'name',
    'role',
    'about',
    'goodreads',
    'facebook',
    'instagram',
    'website',
    'publishers',
    'designSpecialization',
    'artStyle',
    'servicesOffered',
    'yearsOfExperience',
    'designTools',
    'workAvailability',
    'acceptsCustomRequests',
    'pricingPackages',
    'averageDeliveryTime',
    'revisionPolicy',
    'publisherProfile',
    'updatedAt',
  ];
  const result = Object.fromEntries(
    allowedFields
      .filter((key) => profile[key] !== undefined)
      .map((key) => [key, profile[key]]),
  );
  if (profile.publisherProfile) {
    const publicPublisherFields = [
      'description',
      'genresPublished',
      'bookFairParticipation',
      'publishingModel',
      'printOnDemand',
      'manuscriptSubmissionGuidelines',
      'manuscriptFeedbackTime',
      'averageBookPublishingTime',
      'inHouseEditorialTeam',
      'isbnSupport',
    ];
    result.publisherProfile = Object.fromEntries(
      publicPublisherFields
        .filter((key) => profile.publisherProfile[key] !== undefined)
        .map((key) => [key, profile.publisherProfile[key]]),
    );
    result.publisherProfile.imageUrl = profile.publisherProfile.imageData
      ? `/public/media/publisher-profiles/${profile.uid}`
      : null;
  }
  return result;
}

function privateProfile(profile) {
  const {
    profileImageData,
    profileImageContentType,
    ...safeProfile
  } = profile;
  const privatePublisherProfile = profile.publisherProfile
    ? {
        ...profile.publisherProfile,
        imageData: undefined,
        imageUrl: profile.publisherProfile.imageData
          ? `/public/media/publisher-profiles/${profile.uid}`
          : null,
      }
    : undefined;
  return {
    ...safeProfile,
    profileImageUrl: profileImageData
      ? `/public/media/profiles/${profile.uid}`
      : null,
    ...publicProfile(profile),
    ...(privatePublisherProfile
      ? { publisherProfile: privatePublisherProfile }
      : {}),
  };
}

export function createApp({
  profiles,
  books,
  coverDesigns,
  publisherBooks,
  publisherWorkspaces,
  conversations,
  messages,
  verifyIdToken,
  corsOrigins = [],
  allowLocalhostOrigins = true,
}) {
  const app = express();

  app.disable('x-powered-by');
  app.use(buildCors({ corsOrigins, allowLocalhostOrigins }));
  app.use(express.json({ limit: '8mb' }));

  app.get('/health', (_request, response) => {
    response.json({ status: 'ok' });
  });

  app.get('/public/media/:collection/:id', async (request, response) => {
    const { collection: collectionName, id } = request.params;
    const collection = publicCollections.get(collectionName);
    if (collection) {
      const document = await {
        books,
        coverDesigns,
        publisherBooks,
      }[collection].findOne({
        _id: id,
        $or: [{ status: 'published' }, { status: { $exists: false } }],
      });
      if (!document?.imageData) {
        return response.status(404).json({ error: 'Image not found.' });
      }
      response.set('Content-Type', document.imageContentType);
      response.set('Cache-Control', 'public, max-age=300');
      return       response.send(storedImageBuffer(document.imageData));
    }

    if (collectionName === 'profiles') {
      const profile = await profiles.findOne({ _id: id });
      if (!profile?.profileImageData) {
        return response.status(404).json({ error: 'Image not found.' });
      }
      response.set('Content-Type', profile.profileImageContentType);
      response.set('Cache-Control', 'public, max-age=300');
      return response.send(storedImageBuffer(profile.profileImageData));
    }
    if (collectionName === 'publisher-profiles') {
      const profile = await profiles.findOne({ _id: id });
      if (!profile?.publisherProfile?.imageData) {
        return response.status(404).json({ error: 'Image not found.' });
      }
      response.set('Content-Type', profile.publisherProfile.imageContentType);
      response.set('Cache-Control', 'public, max-age=300');
      return response.send(storedImageBuffer(profile.publisherProfile.imageData));
    }

    return response.status(404).json({ error: 'Image not found.' });
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
    return response.json(privateProfile(profile));
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

    return response
      .status(result.upsertedCount === 1 ? 201 : 200)
      .json(privateProfile(profile));
  });

  app.put('/api/profile/public', async (request, response) => {
    const currentProfile = await profiles.findOne({ _id: request.auth.uid });
    if (!currentProfile) {
      return response.status(404).json({ error: 'No database profile exists for this account.' });
    }

    const publicFields = [
      'name',
      'about',
      'goodreads',
      'facebook',
      'instagram',
      'website',
      'publishers',
      'designSpecialization',
      'artStyle',
      'servicesOffered',
      'yearsOfExperience',
      'designTools',
      'workAvailability',
      'acceptsCustomRequests',
      'pricingPackages',
      'averageDeliveryTime',
      'revisionPolicy',
    ];
    const updates = {};
    for (const field of publicFields) {
      if (typeof request.body?.[field] === 'string') {
        updates[field] = cleanText(request.body[field], field === 'about' ? 5000 : 500);
      }
    }
    if (request.body?.publishers != null) {
      if (!Array.isArray(request.body.publishers) || request.body.publishers.length > 50) {
        return response.status(400).json({ error: 'Publisher list is invalid.' });
      }
      updates.publishers = request.body.publishers
        .filter((name) => typeof name === 'string')
        .map((name) => cleanText(name, 100))
        .filter(Boolean);
    }
    try {
      const image = parseImage(request.body, 'profileImageBase64');
      if (image.imageData) {
        updates.profileImageData = image.imageData;
        updates.profileImageContentType = image.imageContentType;
      }
      if (request.body?.removeProfileImage === true) {
        updates.profileImageData = null;
        updates.profileImageContentType = null;
      }
    } catch (error) {
      return response.status(400).json({ error: error.message });
    }

    if (updates.name !== undefined && !updates.name) {
      return response.status(400).json({ error: 'Name must not be empty.' });
    }
    updates.updatedAt = new Date();
    await profiles.updateOne({ _id: request.auth.uid }, { $set: updates });
    const profile = await profiles.findOne({ _id: request.auth.uid });
    return response.json(publicProfile(profile));
  });

  app.get('/api/profiles', async (request, response) => {
    const role = cleanText(request.query.role, 40);
    const query = cleanText(request.query.q, 100);
    const roleQuery = role === 'Cover Artist'
      ? { role: 'Cover Artist' }
      : role === 'Publisher'
        ? { role: { $in: ['Publisher', 'Writer and Publisher'] } }
        : role === 'Writer'
          ? { role: { $in: ['Writer', 'Writer and Publisher'] } }
          : {};
    const profilesFound = await profiles
      .find(roleQuery)
      .sort({ updatedAt: -1 })
      .limit(100)
      .toArray();
    const normalizedQuery = query.toLowerCase();
    const result = profilesFound
      .filter((profile) => !normalizedQuery || [
        profile.name,
        profile.about,
        profile.designSpecialization,
        profile.artStyle,
        profile.publisherProfile?.description,
        profile.publisherProfile?.genresPublished,
      ].some((value) => typeof value === 'string' && value.toLowerCase().includes(normalizedQuery)))
      .map((profile) => ({
        ...publicProfile(profile),
        profileImageUrl: profile.profileImageData
          ? `/public/media/profiles/${profile.uid}`
          : null,
      }));
    return response.json(result);
  });

  app.get('/api/profiles/:uid', async (request, response) => {
    const uid = cleanText(request.params.uid, 128);
    const profile = await profiles.findOne({ _id: uid });
    if (!profile) return response.status(404).json({ error: 'Profile not found.' });

    const writerBooks = ['Writer', 'Writer and Publisher'].includes(profile.role)
      ? await books
          .find({
            $or: [
              { authorUid: uid, status: 'published' },
              { authorUid: uid, status: { $exists: false } },
              { ownerUid: uid, status: 'published' },
              { ownerUid: uid, status: { $exists: false } },
            ],
          })
          .sort({ createdAt: -1 })
          .limit(200)
          .toArray()
      : [];
    return response.json({
      ...publicProfile(profile),
      profileImageUrl: profile.profileImageData
        ? `/public/media/profiles/${profile.uid}`
        : null,
      publishedBookCount: writerBooks.length,
      books: writerBooks.map((book) => ({
        title: cleanText(book.title, 200),
        rating: 0,
        imageUrl: book.imageData
          ? `/public/media/books/${book._id}`
          : null,
      })),
    });
  });

  // Writers' books are private drafts until their owner publishes them.

  app.post('/api/books', async (request, response) => {
    const title = cleanText(request.body?.title, 200);
    if (!title) {
      return response.status(400).json({ error: 'A book title is required.' });
    }

    const pageCount = Number.isInteger(request.body?.pageCount)
      && request.body.pageCount > 0
      && request.body.pageCount <= 100000
      ? request.body.pageCount
      : null;
    const profile = await profiles.findOne(
      { _id: request.auth.uid },
      { projection: { name: 1 } },
    );
    if (!profile) {
      return response.status(404).json({ error: 'No database profile exists for this account.' });
    }
    const roleProfile = await profiles.findOne(
      { _id: request.auth.uid },
      { projection: { role: 1 } },
    );
    if (!['Writer', 'Writer and Publisher'].includes(roleProfile?.role)) {
      return response.status(403).json({ error: 'A writer account is required.' });
    }

    let image;
    try {
      image = parseImage(request.body);
    } catch (error) {
      return response.status(400).json({ error: error.message });
    }
    const book = {
      _id: randomUUID(),
      authorUid: request.auth.uid,
      authorName: profile?.name ?? '',
      status: 'draft',
      title,
      description: cleanText(request.body?.description, 5000),
      pageCount,
      genre: cleanText(request.body?.genre, 80) || null,
      isbn: cleanText(request.body?.isbn, 40),
      publication: cleanText(request.body?.publication, 200),
      goodreadsLink: cleanText(request.body?.goodreadsLink, 500),
      shelfCategory: cleanText(request.body?.shelfCategory, 80),
      createdAt: new Date(),
      ...image,
    };

    await books.insertOne(book);
    return response.status(201).json(contentResponse(book, 'books', { includeImage: true }));
  });

  app.get('/api/books/mine', async (request, response) => {
    const found = await books
      .find({ authorUid: request.auth.uid })
      .sort({ createdAt: -1 })
      .limit(200)
      .toArray();
    return response.json(found.map((book) =>
      contentResponse(book, 'books', { includeImage: true }),
    ));
  });

  app.get('/api/books', async (request, response) => {
    const query = cleanText(request.query.q, 100).toLowerCase();
    const found = await books
      .find({
        $or: [{ status: 'published' }, { status: { $exists: false } }],
      })
      .sort({ createdAt: -1 })
      .limit(200)
      .toArray();
    const filtered = found.filter((book) => !query || [
      book.title,
      book.authorName,
      book.description,
      book.genre,
    ].some((value) => typeof value === 'string' && value.toLowerCase().includes(query)));
    return response.json(filtered.map((book) => contentResponse(book, 'books')));
  });

  app.get('/api/books/:id', async (request, response) => {
    const book = await books.findOne({
      _id: request.params.id,
      $or: [
        { authorUid: request.auth.uid },
        { status: 'published' },
        { status: { $exists: false } },
      ],
    });
    if (!book) return response.status(404).json({ error: 'Book not found.' });
    return response.json(contentResponse(book, 'books', { includeImage: true }));
  });

  app.put('/api/books/:id', async (request, response) => {
    const book = await books.findOne({
      _id: request.params.id,
      authorUid: request.auth.uid,
    });
    if (!book) return response.status(404).json({ error: 'Book not found.' });
    const title = cleanText(request.body?.title, 200);
    if (!title) return response.status(400).json({ error: 'A book title is required.' });
    const pageCount = Number.isInteger(request.body?.pageCount)
      && request.body.pageCount > 0
      && request.body.pageCount <= 100000
      ? request.body.pageCount
      : null;
    let image;
    try {
      image = parseImage(request.body);
    } catch (error) {
      return response.status(400).json({ error: error.message });
    }
    const updates = {
      title,
      authorName: cleanText(request.body?.authorName, 120) || book.authorName,
      description: cleanText(request.body?.description, 5000),
      pageCount,
      genre: cleanText(request.body?.genre, 80) || null,
      isbn: cleanText(request.body?.isbn, 40),
      publication: cleanText(request.body?.publication, 200),
      goodreadsLink: cleanText(request.body?.goodreadsLink, 500),
      shelfCategory: cleanText(request.body?.shelfCategory, 80),
      ...image,
      updatedAt: new Date(),
    };
    await books.updateOne(
      { _id: book._id, authorUid: request.auth.uid },
      { $set: updates },
    );
    return response.json(contentResponse({
      ...book,
      ...updates,
    }, 'books', { includeImage: true }));
  });

  app.patch('/api/books/:id/publish', async (request, response) => {
    const book = await books.findOne({ _id: request.params.id, authorUid: request.auth.uid });
    if (!book) return response.status(404).json({ error: 'Book not found.' });
    await books.updateOne(
      { _id: book._id, authorUid: request.auth.uid },
      { $set: { status: 'published', publishedAt: new Date() } },
    );
    return response.json(contentResponse({
      ...book,
      status: 'published',
      publishedAt: new Date(),
    }, 'books', { includeImage: true }));
  });

  app.delete('/api/books/:id', async (request, response) => {
    const result = await books.deleteOne({
      _id: request.params.id,
      authorUid: request.auth.uid,
    });
    if (result.deletedCount !== 1) {
      return response.status(404).json({ error: 'Book not found.' });
    }
    return response.status(204).end();
  });

  app.post('/api/cover-designs', async (request, response) => {
    const title = cleanText(request.body?.title, 200);
    if (!title) return response.status(400).json({ error: 'A design title is required.' });
    const profile = await profiles.findOne({ _id: request.auth.uid });
    if (!profile || !['Cover Artist'].includes(profile.role)) {
      return response.status(403).json({ error: 'A cover artist account is required.' });
    }
    let image;
    try {
      image = parseImage(request.body);
    } catch (error) {
      return response.status(400).json({ error: error.message });
    }
    if (!image.imageData) {
      return response.status(400).json({ error: 'A cover image is required.' });
    }
    const design = {
      _id: randomUUID(),
      ownerUid: request.auth.uid,
      creator: profile.name,
      title,
      author: cleanText(request.body?.author, 200),
      year: cleanText(request.body?.year, 20),
      color: Number.isInteger(request.body?.color) ? request.body.color : 0xFFC89543,
      status: 'draft',
      createdAt: new Date(),
      ...image,
    };
    await coverDesigns.insertOne(design);
    return response.status(201).json(
      contentResponse(design, 'cover-designs', { includeImage: true }),
    );
  });

  app.get('/api/cover-designs/mine', async (request, response) => {
    const found = await coverDesigns
      .find({ ownerUid: request.auth.uid })
      .sort({ createdAt: -1 })
      .limit(200)
      .toArray();
    return response.json(found.map((design) =>
      contentResponse(design, 'cover-designs', { includeImage: true }),
    ));
  });

  app.get('/api/cover-designs', async (request, response) => {
    const query = cleanText(request.query.q, 100).toLowerCase();
    const ownerUid = cleanText(request.query.ownerUid, 128);
    const found = await coverDesigns
      .find({
        status: 'published',
        ...(ownerUid ? { ownerUid } : {}),
      })
      .sort({ createdAt: -1 })
      .limit(100)
      .toArray();
    return response.json(found.filter((design) => !query || [
      design.title,
      design.creator,
      design.author,
    ].some((value) => typeof value === 'string' && value.toLowerCase().includes(query)))
      .map((design) => contentResponse(design, 'cover-designs')));
  });

  app.put('/api/cover-designs/:id', async (request, response) => {
    const design = await coverDesigns.findOne({
      _id: request.params.id,
      ownerUid: request.auth.uid,
    });
    if (!design) return response.status(404).json({ error: 'Cover design not found.' });
    const title = cleanText(request.body?.title, 200);
    if (!title) return response.status(400).json({ error: 'A design title is required.' });
    let image;
    try {
      image = parseImage(request.body);
    } catch (error) {
      return response.status(400).json({ error: error.message });
    }
    const updates = {
      title,
      author: cleanText(request.body?.author, 200),
      year: cleanText(request.body?.year, 20),
      ...(Number.isInteger(request.body?.color) ? { color: request.body.color } : {}),
      ...image,
      status: request.body?.status === 'published' ? 'published' : 'draft',
      updatedAt: new Date(),
    };
    await coverDesigns.updateOne(
      { _id: design._id, ownerUid: request.auth.uid },
      { $set: updates },
    );
    return response.json(contentResponse({
      ...design,
      ...updates,
    }, 'cover-designs', { includeImage: true }));
  });

  app.delete('/api/cover-designs/:id', async (request, response) => {
    const result = await coverDesigns.deleteOne({
      _id: request.params.id,
      ownerUid: request.auth.uid,
    });
    if (result.deletedCount !== 1) {
      return response.status(404).json({ error: 'Cover design not found.' });
    }
    return response.status(204).end();
  });

  app.patch('/api/cover-designs/:id/publish', async (request, response) => {
    const design = await coverDesigns.findOne({
      _id: request.params.id,
      ownerUid: request.auth.uid,
    });
    if (!design) return response.status(404).json({ error: 'Cover design not found.' });
    await coverDesigns.updateOne(
      { _id: design._id, ownerUid: request.auth.uid },
      { $set: { status: 'published', publishedAt: new Date() } },
    );
    return response.json(contentResponse({
      ...design,
      status: 'published',
      publishedAt: new Date(),
    }, 'cover-designs', { includeImage: true }));
  });

  app.post('/api/publisher-books', async (request, response) => {
    const title = cleanText(request.body?.title, 200);
    if (!title) return response.status(400).json({ error: 'A book title is required.' });
    const profile = await profiles.findOne({ _id: request.auth.uid });
    if (!profile || !['Publisher', 'Writer and Publisher'].includes(profile.role)) {
      return response.status(403).json({ error: 'A publisher account is required.' });
    }
    let image;
    try {
      image = parseImage(request.body);
    } catch (error) {
      return response.status(400).json({ error: error.message });
    }
    const book = {
      _id: randomUUID(),
      ownerUid: request.auth.uid,
      publisherName: profile.name,
      status: 'draft',
      title,
      author: cleanText(request.body?.author, 200),
      year: cleanText(request.body?.year, 20),
      description: cleanText(request.body?.description, 5000),
      genre: cleanText(request.body?.genre, 80),
      pageCount: cleanText(request.body?.pageCount, 20),
      goodreadsLink: cleanText(request.body?.goodreadsLink, 500),
      isbn: cleanText(request.body?.isbn, 40),
      publication: cleanText(request.body?.publication, 200),
      createdAt: new Date(),
      ...image,
    };
    await publisherBooks.insertOne(book);
    return response.status(201).json(
      contentResponse(book, 'publisher-books', { includeImage: true }),
    );
  });

  app.get('/api/publisher-books/mine', async (request, response) => {
    const found = await publisherBooks
      .find({ ownerUid: request.auth.uid })
      .sort({ createdAt: -1 })
      .limit(200)
      .toArray();
    return response.json(found.map((book) =>
      contentResponse(book, 'publisher-books', { includeImage: true }),
    ));
  });

  app.get('/api/publisher-books', async (request, response) => {
    const query = cleanText(request.query.q, 100).toLowerCase();
    const ownerUid = cleanText(request.query.ownerUid, 128);
    const found = await publisherBooks
      .find({
        status: 'published',
        ...(ownerUid ? { ownerUid } : {}),
      })
      .sort({ createdAt: -1 })
      .limit(100)
      .toArray();
    return response.json(found.filter((book) => !query || [
      book.title,
      book.author,
      book.publisherName,
      book.genre,
    ].some((value) => typeof value === 'string' && value.toLowerCase().includes(query)))
      .map((book) => contentResponse(book, 'publisher-books')));
  });

  app.put('/api/publisher-books/:id', async (request, response) => {
    const book = await publisherBooks.findOne({
      _id: request.params.id,
      ownerUid: request.auth.uid,
    });
    if (!book) return response.status(404).json({ error: 'Publisher book not found.' });
    const title = cleanText(request.body?.title, 200);
    if (!title) return response.status(400).json({ error: 'A book title is required.' });
    let image;
    try {
      image = parseImage(request.body);
    } catch (error) {
      return response.status(400).json({ error: error.message });
    }
    const updates = {
      title,
      author: cleanText(request.body?.author, 200),
      year: cleanText(request.body?.year, 20),
      description: cleanText(request.body?.description, 5000),
      genre: cleanText(request.body?.genre, 80),
      pageCount: cleanText(request.body?.pageCount, 20),
      goodreadsLink: cleanText(request.body?.goodreadsLink, 500),
      isbn: cleanText(request.body?.isbn, 40),
      publication: cleanText(request.body?.publication, 200),
      ...(request.body?.status === 'published' ? { status: 'published' } : {}),
      ...image,
      updatedAt: new Date(),
    };
    await publisherBooks.updateOne(
      { _id: book._id, ownerUid: request.auth.uid },
      { $set: updates },
    );
    return response.json(contentResponse({
      ...book,
      ...updates,
    }, 'publisher-books', { includeImage: true }));
  });

  app.patch('/api/publisher-books/:id/publish', async (request, response) => {
    const book = await publisherBooks.findOne({
      _id: request.params.id,
      ownerUid: request.auth.uid,
    });
    if (!book) return response.status(404).json({ error: 'Publisher book not found.' });
    await publisherBooks.updateOne(
      { _id: book._id, ownerUid: request.auth.uid },
      { $set: { status: 'published', publishedAt: new Date() } },
    );
    return response.json(contentResponse({
      ...book,
      status: 'published',
      publishedAt: new Date(),
    }, 'publisher-books', { includeImage: true }));
  });

  app.put('/api/publisher/profile', async (request, response) => {
    const profile = await profiles.findOne({ _id: request.auth.uid });
    if (!profile || !['Publisher', 'Writer and Publisher'].includes(profile.role)) {
      return response.status(403).json({ error: 'A publisher account is required.' });
    }
    const fields = [
      'description',
      'genresPublished',
      'bookFairParticipation',
      'publishingModel',
      'printOnDemand',
      'manuscriptSubmissionGuidelines',
      'manuscriptFeedbackTime',
      'averageBookPublishingTime',
      'inHouseEditorialTeam',
      'isbnSupport',
      'authorRoyaltyTerms',
      'royaltyModel',
      'salesReportsForAuthors',
      'complimentaryCopies',
      'contractDuration',
    ];
    const publisherProfile = { ...(profile.publisherProfile ?? {}) };
    for (const field of fields) {
      if (typeof request.body?.[field] === 'string') {
        publisherProfile[field] = cleanText(request.body[field], 2000);
      }
    }
    try {
      const image = parseImage(request.body, 'publisherImageBase64');
      if (image.imageData) {
        publisherProfile.imageData = image.imageData;
        publisherProfile.imageContentType = image.imageContentType;
      }
    } catch (error) {
      return response.status(400).json({ error: error.message });
    }
    const name = cleanText(request.body?.name, 120);
    if (!name) return response.status(400).json({ error: 'Publisher name is required.' });
    await profiles.updateOne(
      { _id: request.auth.uid },
      { $set: { name, publisherProfile, updatedAt: new Date() } },
    );
    return response.json({ name, ...publisherProfile, imageData: undefined });
  });

  app.post('/api/publisher/workspace', async (request, response) => {
    const profile = await profiles.findOne({ _id: request.auth.uid });
    if (!profile || !['Publisher', 'Writer and Publisher'].includes(profile.role)) {
      return response.status(403).json({ error: 'A publisher account is required.' });
    }
    const workspace = request.body?.workspace;
    if (!workspace || typeof workspace !== 'object' || Array.isArray(workspace)) {
      return response.status(400).json({ error: 'Publisher workspace is invalid.' });
    }
    const safeWorkspace = {
      authors: Array.isArray(workspace.authors) ? workspace.authors.slice(0, 200) : [],
      deals: Array.isArray(workspace.deals) ? workspace.deals.slice(0, 200) : [],
    };
    await publisherWorkspaces.updateOne(
      { _id: request.auth.uid },
      { $set: { ...safeWorkspace, updatedAt: new Date() } },
      { upsert: true },
    );
    return response.json({ saved: true });
  });

  app.get('/api/publisher/workspace', async (request, response) => {
    const workspace = await publisherWorkspaces.findOne({ _id: request.auth.uid });
    return response.json({
      authors: workspace?.authors ?? [],
      deals: workspace?.deals ?? [],
    });
  });

  app.delete('/api/publisher-books/:id', async (request, response) => {
    const result = await publisherBooks.deleteOne({
      _id: request.params.id,
      ownerUid: request.auth.uid,
    });
    if (result.deletedCount !== 1) {
      return response.status(404).json({ error: 'Publisher book not found.' });
    }
    return response.status(204).end();
  });

  app.post('/api/conversations', async (request, response) => {
    const recipientUid = cleanText(request.body?.recipientUid, 128);
    if (!recipientUid || recipientUid === request.auth.uid) {
      return response.status(400).json({ error: 'A valid conversation recipient is required.' });
    }
    const recipient = await profiles.findOne({ _id: recipientUid });
    if (!recipient) return response.status(404).json({ error: 'Recipient not found.' });
    const participants = [request.auth.uid, recipientUid].sort();
    const encodedPair = Buffer.from(participants.join('\u0000')).toString('base64url');
    const conversationId = `direct-${encodedPair}`;
    await conversations.updateOne(
      { _id: conversationId },
      {
        $setOnInsert: {
          _id: conversationId,
          participantUids: participants,
          createdAt: new Date(),
        },
      },
      { upsert: true },
    );
    return response.json({
      id: conversationId,
      participantUids: participants,
      recipient: publicProfile(recipient),
    });
  });

  app.get('/api/conversations', async (request, response) => {
    const found = await conversations
      .find({ participantUids: request.auth.uid })
      .sort({ updatedAt: -1 })
      .limit(100)
      .toArray();
    const result = [];
    for (const conversation of found) {
      const otherUid = conversation.participantUids.find((uid) => uid !== request.auth.uid);
      const other = otherUid ? await profiles.findOne({ _id: otherUid }) : null;
      const lastMessage = await messages.findOne(
        { conversationId: conversation._id },
        { sort: { sentAt: -1 } },
      );
      result.push({
        id: conversation._id,
        userId: otherUid,
        userName: other?.name ?? 'Novelly user',
        lastMessagePreview: lastMessage?.text ?? (lastMessage?.imageData ? 'Photo' : null),
        lastMessageAt: lastMessage?.sentAt ?? null,
      });
    }
    return response.json(result);
  });

  app.get('/api/conversations/:id/messages', async (request, response) => {
    const conversation = await conversations.findOne({
      _id: request.params.id,
      participantUids: request.auth.uid,
    });
    if (!conversation) {
      return response.status(404).json({ error: 'Conversation not found.' });
    }
    const found = await messages
      .find({ conversationId: conversation._id })
      .sort({ sentAt: 1 })
      .limit(500)
      .toArray();
    return response.json(found.map((message) => ({
      id: message._id,
      conversationId: message.conversationId,
      senderId: message.senderUid,
      type: message.imageData ? 'image' : 'text',
      text: message.text ?? null,
      imageBase64: message.imageData?.toString('base64') ?? null,
      sentAt: message.sentAt,
    })));
  });

  app.post('/api/conversations/:id/messages', async (request, response) => {
    const conversation = await conversations.findOne({
      _id: request.params.id,
      participantUids: request.auth.uid,
    });
    if (!conversation) {
      return response.status(404).json({ error: 'Conversation not found.' });
    }
    const text = cleanText(request.body?.text, 5000);
    let image;
    try {
      image = parseImage(request.body);
    } catch (error) {
      return response.status(400).json({ error: error.message });
    }
    if (!text && !image.imageData) {
      return response.status(400).json({ error: 'A message or image is required.' });
    }
    const message = {
      _id: randomUUID(),
      conversationId: conversation._id,
      senderUid: request.auth.uid,
      ...(text ? { text } : {}),
      ...image,
      sentAt: new Date(),
    };
    await messages.insertOne(message);
    await conversations.updateOne(
      { _id: conversation._id },
      { $set: { updatedAt: message.sentAt } },
    );
    return response.status(201).json({
      id: message._id,
      conversationId: message.conversationId,
      senderId: message.senderUid,
      type: message.imageData ? 'image' : 'text',
      text: message.text ?? null,
      imageBase64: message.imageData?.toString('base64') ?? null,
      sentAt: message.sentAt,
    });
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
