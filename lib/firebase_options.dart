import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase options for platforms that have no native config file.
///
/// Android reads `android/app/google-services.json`, so this returns null
/// there. Flutter web has no such file and must be given the web app's config
/// (Firebase Console > Project settings > Your apps > Web app):
///
/// flutter run -d chrome `
///   --dart-define=API_BASE_URL=http://localhost:3000 `
///   --dart-define=FIREBASE_WEB_API_KEY=... `
///   --dart-define=FIREBASE_WEB_APP_ID=... `
///   --dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID=... `
///   --dart-define=FIREBASE_WEB_PROJECT_ID=novelly-a8e35 `
///   --dart-define=FIREBASE_WEB_AUTH_DOMAIN=novelly-a8e35.firebaseapp.com
/// (backticks are PowerShell line continuations; put it on one line if unsure)
///
/// These web values are public identifiers, not secrets.
FirebaseOptions? get firebaseOptionsForCurrentPlatform {
  if (!kIsWeb) return null;

  const apiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  const senderId = String.fromEnvironment('FIREBASE_WEB_MESSAGING_SENDER_ID');
  const projectId = String.fromEnvironment('FIREBASE_WEB_PROJECT_ID');
  const authDomain = String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN');
  const storageBucket = String.fromEnvironment('FIREBASE_WEB_STORAGE_BUCKET');

  if (apiKey.isEmpty ||
      appId.isEmpty ||
      senderId.isEmpty ||
      projectId.isEmpty) {
    return null;
  }
  return const FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: senderId,
    projectId: projectId,
    authDomain: authDomain == '' ? null : authDomain,
    storageBucket: storageBucket == '' ? null : storageBucket,
  );
}
