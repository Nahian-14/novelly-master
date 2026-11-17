import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../main_page/writer_profile.dart';
import '../publisher/publisher_profile.dart';
import '../services/profile_api.dart';
import 'auth_service.dart';

enum SessionRestoreResult {
  /// Nobody was signed in: show the login screen.
  noSession,

  /// The saved login was restored and the profile is loaded.
  restored,

  /// The saved login is no longer valid (account removed or rejected).
  signInRequired,

  /// The backend could not be reached. The login is kept so the user can retry.
  unreachable,
}

/// Brings back the signed-in user's profile after the app is reopened.
///
/// Firebase remembers who is logged in, but `WriterProfileScreen.currentUser`
/// is only memory. Without this, a restarted app shows an empty profile.
///
/// [restore] and [signOut] default to the real [AuthService]; tests replace them.
Future<SessionRestoreResult> restoreSignedInUser({
  Future<UserAuthProfile?> Function()? restore,
  Future<void> Function()? signOut,
}) async {
  final restoreProfile = restore ?? AuthService().restoreSession;
  final signOutUser = signOut ?? AuthService().signOut;

  try {
    final profile = await restoreProfile();
    if (profile == null) return SessionRestoreResult.noSession;

    final profileData = {
      ...profile.profileData,
      'uid': profile.uid,
      'name': profile.name,
      'role': profile.role,
    };
    WriterProfileScreen.currentUser = WriterProfile.fromJson(profileData);
    PublisherProfileScreen.currentUser = profile.isPublisher
        ? PublisherProfile.fromJson(profileData)
        : null;
    return SessionRestoreResult.restored;
  } on ProfileApiException catch (error) {
    final status = error.statusCode;
    if (status == 401 || status == 403 || status == 404) {
      await signOutUser();
      return SessionRestoreResult.signInRequired;
    }
    debugPrint('Could not restore the session: $error');
    return SessionRestoreResult.unreachable;
  } on FirebaseAuthException catch (error) {
    if (error.code == 'network-request-failed') {
      return SessionRestoreResult.unreachable;
    }
    await signOutUser();
    return SessionRestoreResult.signInRequired;
  } catch (error) {
    debugPrint('Could not restore the session: $error');
    return SessionRestoreResult.unreachable;
  }
}
