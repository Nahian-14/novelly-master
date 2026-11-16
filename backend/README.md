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
