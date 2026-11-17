# Novelly backend

This Node.js API verifies Firebase Authentication ID tokens and stores user
profiles in MongoDB Atlas. Flutter must call this API; Atlas credentials belong
only on the server.

## Local setup

1. Install Node.js 20 or newer.
2. In MongoDB Atlas, create a cluster. Under **Database Access**, add a
   dedicated database user and grant it `readWrite` access to the `novelly`
   database only. Under **Network Access**, allow your current public IP for
   local development; do not allow access from `0.0.0.0/0`.
3. In the cluster's **Connect** flow, choose **Drivers** and copy the Node.js
   connection string. Replace its username and password with the database
   user's credentials. If the password contains special characters, URL-encode
   them.
4. Create a Firebase project (or use your new one). Add an Android app with
   package name `com.example.novelly`. In Firebase Console, enable
   **Email/Password** and **Google** under Authentication sign-in providers.
   From the `android` directory, run `.\gradlew signingReport` and add the
   debug variant's SHA-1 and SHA-256 fingerprints to the Android app in Firebase
   project settings. Then download the updated `google-services.json` and
   replace `android/app/google-services.json` in this project.
5. Fill the existing `backend/.env.local` file. Set `MONGODB_URI` to the Atlas
   connection string and `MONGODB_DB` to `novelly`. From the Firebase
   service-account JSON, copy `project_id` into `FIREBASE_PROJECT_ID`,
   `client_email` into `FIREBASE_CLIENT_EMAIL`, and `private_key` into
   `FIREBASE_PRIVATE_KEY`. Keep the private key in double quotes; preserve its
   `\n` sequences as shown in the JSON file.
6. From this directory, run `npm install`, `npm test`, and `npm start`.

Do not send or commit the Atlas connection string, database password, or
Firebase service-account JSON key. Keep them in your local ignored
`backend/.env.local` or outside the repository. The Firebase private key is
secret; do not paste it into chat or commit it.

The API listens on port 3000 by default. `GET /health` checks that the process is
running. Authenticated endpoints require `Authorization: Bearer <Firebase ID
token>`.

Start the API successfully before registering in the app. Firebase can create
the account even if the API is unavailable; in that case, the MongoDB profile
will be missing. For a fresh development setup, delete that incomplete test
account from Firebase Authentication before trying registration again.

## Profile endpoints

- `PUT /api/profile` creates the signed-in user's profile once. The API derives
  the UID and email from the verified Firebase token; later requests cannot
  overwrite the name or role.
- `GET /api/profile` returns the signed-in user's profile.
- `GET /api/profiles/:uid` returns allowlisted public profile information and
  published book titles for a writer. Public responses omit account email and
  private publisher royalty and contract terms.

The initial supported roles match the Flutter registration screen. Treat these
as profile data only; do not use a client-selected role as authorization for
privileged backend actions.

## Connect Flutter

Run the API and Android emulator, then start Flutter with:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

`10.0.2.2` routes from the Android emulator to the development computer. For a
physical Android device, use the computer's LAN IP and ensure both devices can
reach each other. Use an HTTPS URL for deployed environments; never ship Atlas
credentials in the Flutter app.

New signups create their profiles in MongoDB. Firebase accounts created before
this integration need their profiles migrated or recreated before they can use
the profile lookup endpoint.

## Content storage and privacy

The API stores user content in MongoDB collections for books, cover designs,
publisher books, publisher workspaces, conversations, and messages. User profile
documents also contain profile data and public-facing creator or publisher
details. Passwords remain in Firebase Authentication; the backend never stores
them.

New books and cover designs are private drafts by default. Owners can list and
edit their own drafts through the authenticated `/api/books/mine` and
`/api/cover-designs/mine` endpoints. Publisher books are managed through
`/api/publisher-books/mine` and are likewise private until published. The
owner-only `PATCH /api/books/:id/publish`,
`PATCH /api/cover-designs/:id/publish`, and
`PATCH /api/publisher-books/:id/publish` endpoints make those items available
through the corresponding public list endpoints. Public profiles and published
books/designs can be searched and viewed without exposing account email
addresses. Publisher royalty terms, royalty models, sales-report terms, and
contract durations remain private to the account owner. Private publisher
workspace data and chat messages are only
available to the owning account or conversation participants.

Public image URLs only serve images attached to published content or public
profile images. Chat images require participant authorization. Image uploads
are limited to JPEG, PNG, or WebP and 4 MB per image.

The app loads public Discover data when the screen opens and refreshes it when
the user submits a search. It does not currently use live subscriptions or
polling, so updates made by other users appear after a refresh/search rather
than immediately.

## Using the app with the phone unplugged

`http://10.0.2.2:3000` and `localhost` only work while the phone is attached to
your computer. To use the app away from the cable the API must be reachable on
the internet over HTTPS, because Android release builds refuse plain `http://`.

1. Host the `backend` folder on any Node host (Render, Railway, Fly.io, ...).
   Build command `npm install`, start command `npm start`. Add these as
   environment variables on the host instead of `.env.local`:
   `MONGODB_URI`, `MONGODB_DB`, `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`,
   `FIREBASE_PRIVATE_KEY`, and `ALLOW_LOCALHOST_ORIGINS=false`.
2. In MongoDB Atlas > Network Access, a host with changing IP addresses needs
   `0.0.0.0/0`. That is acceptable only because the database user has a strong
   password and `readWrite` on the `novelly` database only.
3. Check `https://<your-host>/health` shows `{"status":"ok"}` in a browser.
4. Register the SHA-1 and SHA-256 of the key that signs your app (step 4 of
   Local setup), download the new `google-services.json`, and replace
   `android/app/google-services.json`. Without this, Google sign-in fails.
5. Build an installable app and put it on the phone:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://<your-host>
```

   Install `build/app/outputs/flutter-apk/app-release.apk` (copy it to the phone,
   or run `flutter install`). The URL is baked into the app at build time, so
   rebuild if the URL changes.

Free hosts put idle servers to sleep, so the first request after a pause can
take up to a minute. The app waits up to 45 seconds for it.

## Flutter web (Chrome)

Web has no `google-services.json`, so give Flutter the web app's config. It is
in Firebase Console > Project settings > Your apps > Web app, and these values
are public identifiers, not secrets. See `lib/firebase_options.dart` for the
exact `--dart-define` names. Browser calls to the API are allowed from any
`localhost` port by default; add your deployed site to `CORS_ORIGINS`.
