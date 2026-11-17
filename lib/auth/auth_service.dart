import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/profile_api.dart';

class UserAuthProfile {
  final String uid;
  final String name;
  final String email;
  final String role;
  final Map<String, dynamic> profileData;

  const UserAuthProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.profileData = const {},
  });

  bool get isWriter => role == 'Writer' || role == 'Writer and Publisher';
  bool get isPublisher => role == 'Publisher' || role == 'Writer and Publisher';
  bool get isCoverArtist => role == 'Cover Artist';
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  ProfileApi? _profileApiInstance;
  ProfileApi get _profileApi => _profileApiInstance ??= ProfileApi();

  User? get currentUser => _auth.currentUser;

  /// Register with Firebase Authentication and save the profile through the API.
  Future<UserAuthProfile> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    if (Firebase.apps.isEmpty) {
      // Offline stand-in used only by widget tests. A release build must never
      // pretend an account was created, so it fails loudly instead.
      if (kReleaseMode) _ensureFirebaseInitialized();
      return UserAuthProfile(
        uid: 'test-uid',
        name: name.trim(),
        email: email.trim().toLowerCase(),
        role: role,
        profileData: {'uid': 'test-uid', 'name': name.trim(), 'role': role},
      );
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('User registration failed.');
      }

      // Update Display Name in Firebase Auth
      try {
        await user
            .updateDisplayName(name.trim())
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Update display name warning: $e');
      }

      try {
        final profileData = await _profileApi.createProfile(
          idToken: await _idTokenFor(user),
          name: name.trim(),
          role: role,
        );
        return _profileFromData(profileData, user);
      } catch (_) {
        // Do not leave a Firebase account without a database profile: the user
        // could never log in or register again with this email. Undo it so
        // they can simply retry.
        try {
          await user.delete();
        } catch (deleteError) {
          debugPrint('Could not roll back the new account: $deleteError');
        }
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Sign in an existing user with Email and Password.
  Future<UserAuthProfile> signIn({
    required String email,
    required String password,
  }) async {
    if (Firebase.apps.isEmpty) {
      if (kReleaseMode) _ensureFirebaseInitialized();
      return UserAuthProfile(
        uid: 'test-uid',
        name: 'Test User',
        email: email.trim().toLowerCase(),
        role: 'Writer',
        profileData: {'uid': 'test-uid', 'name': 'Test User', 'role': 'Writer'},
      );
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('User login failed.');
      }

      final profileData = await _profileApi.getProfile(
        idToken: await _idTokenFor(user),
      );
      return _profileFromData(profileData, user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Sign in or register with Google, then create the MongoDB profile if needed.
  Future<UserAuthProfile?> signInWithGoogle({String role = 'Writer'}) async {
    _ensureFirebaseInitialized();
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Google sign-in failed.');
      }

      final displayName = user.displayName?.trim();
      final profileData = await _profileApi.createProfile(
        idToken: await _idTokenFor(user),
        name: displayName == null || displayName.isEmpty
            ? user.email?.split('@').first ?? 'User'
            : displayName,
        role: role,
      );
      return _profileFromData(profileData, user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    _ensureFirebaseInitialized();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out current user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  void _ensureFirebaseInitialized() {
    if (Firebase.apps.isEmpty) {
      throw Exception(
        'Firebase is not initialized yet. Please make sure you have added '
        'google-services.json to android/app/ and configured Firebase Console.',
      );
    }
  }

  Future<String> _idTokenFor(User user) async {
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw Exception('Could not get a Firebase authentication token.');
    }
    return token;
  }

  UserAuthProfile _profileFromData(Map<String, dynamic> data, User user) {
    String requiredString(String key) {
      final value = data[key];
      if (value is! String || value.trim().isEmpty) {
        throw Exception('The backend returned an incomplete user profile.');
      }
      return value;
    }

    final uid = requiredString('uid');
    if (uid != user.uid) {
      throw Exception(
        'The backend returned a profile for a different account.',
      );
    }
    return UserAuthProfile(
      uid: uid,
      name: requiredString('name'),
      email: requiredString('email'),
      role: requiredString('role'),
      profileData: data,
    );
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'user-disabled':
        return Exception(
          'No account found with this email. Please register first!',
        );
      case 'wrong-password':
      case 'invalid-credential':
        return Exception(
          'Incorrect password or email. If you do not have an account, please register first.',
        );
      case 'email-already-in-use':
        return Exception(
          'An account with this email already exists. Please login instead.',
        );
      case 'invalid-email':
        return Exception('The email address entered is invalid.');
      case 'weak-password':
        return Exception(
          'Password is too weak. Please use at least 6 characters.',
        );
      case 'network-request-failed':
        return Exception(
          'Network error. Please check your internet connection.',
        );
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      default:
        return Exception(
          e.message ?? 'Authentication error occurred (${e.code}).',
        );
    }
  }
}
