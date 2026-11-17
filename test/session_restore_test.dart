import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novelly/auth/auth_service.dart';
import 'package:novelly/auth/session_restore.dart';
import 'package:novelly/main_page/writer_profile.dart';
import 'package:novelly/publisher/publisher_profile.dart';
import 'package:novelly/services/profile_api.dart';

void main() {
  const emptyProfile = WriterProfile(name: 'Your profile');

  setUp(() {
    WriterProfileScreen.currentUser = emptyProfile;
    PublisherProfileScreen.currentUser = null;
  });

  test('restores the saved profile into memory after a restart', () async {
    final result = await restoreSignedInUser(
      restore: () async => const UserAuthProfile(
        uid: 'uid-1',
        name: 'Nahian',
        email: 'nahian@example.com',
        role: 'Writer',
        profileData: {'uid': 'uid-1', 'about': 'I write novels.'},
      ),
      signOut: () async => fail('A restored user must stay signed in.'),
    );

    expect(result, SessionRestoreResult.restored);
    expect(WriterProfileScreen.currentUser.name, 'Nahian');
    expect(WriterProfileScreen.currentUser.accountId, 'uid-1');
    expect(PublisherProfileScreen.currentUser, isNull);
  });

  test('a publisher account also restores its publisher profile', () async {
    final result = await restoreSignedInUser(
      restore: () async => const UserAuthProfile(
        uid: 'uid-2',
        name: 'Press House',
        email: 'press@example.com',
        role: 'Publisher',
        profileData: {'uid': 'uid-2'},
      ),
      signOut: () async {},
    );

    expect(result, SessionRestoreResult.restored);
    expect(PublisherProfileScreen.currentUser, isNotNull);
  });

  test('nobody signed in goes to the login screen', () async {
    final result = await restoreSignedInUser(
      restore: () async => null,
      signOut: () async => fail('Nothing to sign out.'),
    );

    expect(result, SessionRestoreResult.noSession);
    expect(WriterProfileScreen.currentUser.name, 'Your profile');
  });

  for (final status in [401, 403, 404]) {
    test('backend answer $status signs the user out', () async {
      var signedOut = false;
      final result = await restoreSignedInUser(
        restore: () async =>
            throw ProfileApiException('rejected', statusCode: status),
        signOut: () async => signedOut = true,
      );

      expect(result, SessionRestoreResult.signInRequired);
      expect(signedOut, isTrue);
    });
  }

  test('a server or network failure keeps the user signed in', () async {
    for (final failure in <Object>[
      const ProfileApiException('down', statusCode: 503),
      const ProfileApiException('invalid response'),
      Exception('SocketException'),
    ]) {
      final result = await restoreSignedInUser(
        restore: () async => throw failure,
        signOut: () async => fail('A temporary failure must not sign out.'),
      );
      expect(result, SessionRestoreResult.unreachable);
    }
  });

  test('Firebase offline keeps the login, other Firebase errors sign out', () async {
    final offline = await restoreSignedInUser(
      restore: () async =>
          throw FirebaseAuthException(code: 'network-request-failed'),
      signOut: () async => fail('Offline must not sign out.'),
    );
    expect(offline, SessionRestoreResult.unreachable);

    var signedOut = false;
    final disabled = await restoreSignedInUser(
      restore: () async => throw FirebaseAuthException(code: 'user-disabled'),
      signOut: () async => signedOut = true,
    );
    expect(disabled, SessionRestoreResult.signInRequired);
    expect(signedOut, isTrue);
  });
}
