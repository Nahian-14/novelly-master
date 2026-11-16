import assert from 'node:assert/strict';
import { once } from 'node:events';
import { test } from 'node:test';

import { createApp } from '../src/app.js';

function matches(document, filter) {
  return Object.entries(filter).every(([key, expected]) => {
    if (key === '$or') return expected.some((part) => matches(document, part));
    const actual = document[key];
    if (expected && typeof expected === 'object' && !Array.isArray(expected)) {
      if ('$exists' in expected) return (actual !== undefined) === expected.$exists;
      if ('$in' in expected) {
        return expected.$in.includes(actual)
          || (Array.isArray(actual) && actual.some((value) => expected.$in.includes(value)));
      }
    }
    if (Array.isArray(actual)) return actual.includes(expected);
    return actual === expected;
  });
}

class MemoryCollection {
  documents = new Map();

  async findOne(filter, options = {}) {
    const found = [...this.documents.values()].filter((item) => matches(item, filter));
    if (options.sort) {
      const [[field, direction]] = Object.entries(options.sort);
      found.sort((first, second) =>
        (first[field] > second[field] ? 1 : first[field] < second[field] ? -1 : 0)
        * direction,
      );
    }
    return found[0] ?? null;
  }

  async insertOne(document) {
    this.documents.set(document._id, structuredClone(document));
  }

  async updateOne(filter, update, { upsert = false } = {}) {
    const current = await this.findOne(filter);
    if (current) {
      Object.assign(current, update.$setOnInsert ? {} : {}, update.$set ?? {});
      this.documents.set(current._id, current);
      return { upsertedCount: 0 };
    }
    if (!upsert) return { upsertedCount: 0 };
    const document = {
      ...Object.fromEntries(
        Object.entries(filter).filter(([, value]) => typeof value !== 'object'),
      ),
      ...(update.$setOnInsert ?? {}),
      ...(update.$set ?? {}),
    };
    this.documents.set(document._id, document);
    return { upsertedCount: 1 };
  }

  async deleteOne(filter) {
    const found = await this.findOne(filter);
    if (!found) return { deletedCount: 0 };
    this.documents.delete(found._id);
    return { deletedCount: 1 };
  }

  find(filter) {
    let found = [...this.documents.values()].filter((item) => matches(item, filter));
    const cursor = {
      sort: (specification) => {
        const [[field, direction]] = Object.entries(specification);
        found.sort((first, second) =>
          (first[field] > second[field] ? 1 : first[field] < second[field] ? -1 : 0)
          * direction,
        );
        return cursor;
      },
      limit: (count) => {
        found = found.slice(0, count);
        return cursor;
      },
      toArray: async () => found,
    };
    return cursor;
  }
}

async function startTestServer(t, seed = () => {}) {
  const profiles = new MemoryCollection();
  for (const [uid, role] of [
    ['user-1', 'Writer'],
    ['user-2', 'Cover Artist'],
    ['user-3', 'Publisher'],
  ]) {
    profiles.documents.set(uid, {
      _id: uid,
      uid,
      name: `Name ${uid}`,
      email: `${uid}@private.example`,
      role,
      ...(uid === 'user-3'
        ? {
            publisherProfile: {
              description: 'Independent publisher',
              authorRoyaltyTerms: 'Private royalty deal',
              royaltyModel: 'Negotiated',
              salesReportsForAuthors: 'Private reporting terms',
              contractDuration: 'Private contract duration',
            },
          }
        : {}),
    });
  }
  const collections = {
    profiles,
    books: new MemoryCollection(),
    coverDesigns: new MemoryCollection(),
    publisherBooks: new MemoryCollection(),
    publisherWorkspaces: new MemoryCollection(),
    conversations: new MemoryCollection(),
    messages: new MemoryCollection(),
  };
  seed(collections);
  const app = createApp({
    ...collections,
    verifyIdToken: async (token) => {
      const uid = token.replace(/-token$/, '');
      if (!collections.profiles.documents.has(uid)) throw new Error('Invalid token.');
      return { uid, email: `${uid}@private.example` };
    },
  });
  const server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  t.after(() => new Promise((resolve, reject) => {
    server.close((error) => error ? reject(error) : resolve());
  }));
  return `http://127.0.0.1:${server.address().port}`;
}

function headers(uid, body) {
  return {
    Authorization: `Bearer ${uid}-token`,
    ...(body ? { 'Content-Type': 'application/json' } : {}),
  };
}

test('public writer lookup returns profile details and only published books', async (t) => {
  const baseUrl = await startTestServer(t, ({ books, profiles }) => {
    profiles.documents.get('user-1').about = 'Writes speculative fiction.';
    books.documents.set('published-book', {
      _id: 'published-book',
      authorUid: 'user-1',
      authorName: 'Name user-1',
      title: 'The Published Story',
      status: 'published',
      createdAt: new Date(),
    });
    books.documents.set('draft-book', {
      _id: 'draft-book',
      authorUid: 'user-1',
      authorName: 'Name user-1',
      title: 'The Private Draft',
      status: 'draft',
      createdAt: new Date(),
    });
  });

  const response = await fetch(`${baseUrl}/api/profiles/user-1`, {
    headers: headers('user-2'),
  });
  const profile = await response.json();

  assert.equal(response.status, 200);
  assert.equal(profile.uid, 'user-1');
  assert.equal(profile.about, 'Writes speculative fiction.');
  assert.equal(profile.publishedBookCount, 1);
  assert.deepEqual(profile.books, [
    { title: 'The Published Story', rating: 0, imageUrl: null },
  ]);
  assert.equal('email' in profile, false);
});

test('books stay private until the owner publishes them', async (t) => {
  const baseUrl = await startTestServer(t);
  const createResponse = await fetch(`${baseUrl}/api/books`, {
    method: 'POST',
    headers: headers('user-1', true),
    body: JSON.stringify({ title: 'Private draft' }),
  });
  const draft = await createResponse.json();

  assert.equal(createResponse.status, 201);
  assert.equal(draft.status, 'draft');
  assert.equal((await (await fetch(`${baseUrl}/api/books`, {
    headers: headers('user-2'),
  })).json()).length, 0);

  const unauthorizedRead = await fetch(`${baseUrl}/api/books/${draft.id}`, {
    headers: headers('user-2'),
  });
  assert.equal(unauthorizedRead.status, 404);

  const publishResponse = await fetch(`${baseUrl}/api/books/${draft.id}/publish`, {
    method: 'PATCH',
    headers: headers('user-1', true),
  });
  assert.equal(publishResponse.status, 200);
  assert.equal((await publishResponse.json()).status, 'published');

  const publicBooks = await (await fetch(`${baseUrl}/api/books?q=private`, {
    headers: headers('user-2'),
  })).json();
  assert.equal(publicBooks.length, 1);
  assert.equal(publicBooks[0].title, 'Private draft');
  assert.equal('ownerUid' in publicBooks[0], false);
});

test('published image media is returned as the original binary bytes', async (t) => {
  const expectedImage = Buffer.from([0, 1, 2, 255, 254, 253]);
  const baseUrl = await startTestServer(t, ({ books }) => {
    books.documents.set('book-image', {
      _id: 'book-image',
      authorUid: 'user-1',
      status: 'published',
      imageData: {
        buffer: Uint8Array.from(expectedImage),
        position: expectedImage.length,
      },
      imageContentType: 'image/png',
    });
  });

  const response = await fetch(`${baseUrl}/public/media/books/book-image`);

  assert.equal(response.status, 200);
  assert.equal(response.headers.get('content-type'), 'image/png');
  assert.deepEqual(Buffer.from(await response.arrayBuffer()), expectedImage);

  const ownerBooks = await fetch(`${baseUrl}/api/books/mine`, {
    headers: headers('user-1'),
  });
  const [book] = await ownerBooks.json();
  assert.equal(book.imageBase64, expectedImage.toString('base64'));
});

test('public profiles omit account email and private publisher terms', async (t) => {
  const baseUrl = await startTestServer(t);
  const response = await fetch(`${baseUrl}/api/profiles?role=Cover%20Artist`, {
    headers: headers('user-1'),
  });
  const results = await response.json();

  assert.equal(response.status, 200);
  assert.equal(results.length, 1);
  assert.equal(results[0].uid, 'user-2');
  assert.equal('email' in results[0], false);

  const publisherResponse = await fetch(`${baseUrl}/api/profiles?role=Publisher`, {
    headers: headers('user-1'),
  });
  const publishers = await publisherResponse.json();
  assert.equal(publishers.length, 1);
  assert.equal(publishers[0].publisherProfile.description, 'Independent publisher');
  assert.equal('email' in publishers[0], false);
  assert.equal('authorRoyaltyTerms' in publishers[0].publisherProfile, false);
  assert.equal('royaltyModel' in publishers[0].publisherProfile, false);
  assert.equal('salesReportsForAuthors' in publishers[0].publisherProfile, false);
  assert.equal('contractDuration' in publishers[0].publisherProfile, false);

  const ownerResponse = await fetch(`${baseUrl}/api/profile`, {
    headers: headers('user-3'),
  });
  const ownerProfile = await ownerResponse.json();
  assert.equal(ownerProfile.publisherProfile.authorRoyaltyTerms, 'Private royalty deal');
  assert.equal(ownerProfile.publisherProfile.contractDuration, 'Private contract duration');
});

test('private messages can only be fetched by conversation participants', async (t) => {
  const baseUrl = await startTestServer(t);
  const opened = await (await fetch(`${baseUrl}/api/conversations`, {
    method: 'POST',
    headers: headers('user-1', true),
    body: JSON.stringify({ recipientUid: 'user-2' }),
  })).json();
  const sentResponse = await fetch(
    `${baseUrl}/api/conversations/${opened.id}/messages`,
    {
      method: 'POST',
      headers: headers('user-1', true),
      body: JSON.stringify({ text: 'Private message' }),
    },
  );
  assert.equal(sentResponse.status, 201);

  const recipientRead = await fetch(
    `${baseUrl}/api/conversations/${opened.id}/messages`,
    { headers: headers('user-2') },
  );
  assert.equal(recipientRead.status, 200);
  assert.equal((await recipientRead.json())[0].text, 'Private message');

  const outsiderRead = await fetch(
    `${baseUrl}/api/conversations/${opened.id}/messages`,
    { headers: headers('user-3') },
  );
  assert.equal(outsiderRead.status, 404);
});
