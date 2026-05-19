import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_auth/shared_auth.dart';

void main() {
  group('AuthController.sendSignInLinkToEmail', () {
    test('throws when emailLinkContinueUrl is null', () {
      final auth = AuthController(
        backendBaseUrl: 'https://example.test',
        requestedClient: 'responder',
        emailLinkContinueUrl: null,
        firebaseAuthService: _FakeFirebaseAuthService(),
      );
      addTearDown(auth.dispose);

      expect(
        () => auth.sendSignInLinkToEmail('user@example.test'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('emailLinkContinueUrl'),
          ),
        ),
      );
    });

    // Real fail state: EMAIL_LINK_CONTINUE_URL env var not set at build time
    // defaults to '' in app_config.dart, which AuthController treats as unset.
    test('throws when emailLinkContinueUrl is empty string', () {
      final auth = AuthController(
        backendBaseUrl: 'https://example.test',
        requestedClient: 'responder',
        emailLinkContinueUrl: '',
        firebaseAuthService: _FakeFirebaseAuthService(),
      );
      addTearDown(auth.dispose);

      expect(
        () => auth.sendSignInLinkToEmail('user@example.test'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('emailLinkContinueUrl'),
          ),
        ),
      );
    });
  });
}

class _FakeFirebaseAuthService implements FirebaseAuthService {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> sendSignInLinkToEmail(
    String email, {
    required String continueUrl,
  }) async {}

  @override
  Future<void> handleEmailLink({
    required String email,
    required String emailLink,
  }) async {}

  @override
  Future<void> checkAndHandleIncomingEmailLink() async {}

  @override
  bool isSignInWithEmailLink(String link) => false;

  @override
  Future<bool> handleMobileDeepLink(String link) async => false;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async => null;

  @override
  Future<void> signOut() async {}
}
