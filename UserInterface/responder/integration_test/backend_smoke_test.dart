import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:missionout_responder/firebase_options.dart';
import 'package:missionout_responder/main.dart' as app;
import 'package:missionout_responder/screens/logged_out_screen.dart';
import 'package:missionout_responder/screens/responder_home_screen.dart';

// Passed via --dart-define=TEST_FIREBASE_TOKEN=<token from mint_test_token.py>
const _testFirebaseToken = String.fromEnvironment('TEST_FIREBASE_TOKEN');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (_testFirebaseToken.isEmpty) {
      fail(
        'TEST_FIREBASE_TOKEN is not set.\n'
        'Generate one with:\n'
        '  TOKEN=\$(FIREBASE_CREDENTIALS_PATH=/Users/justinmatis/Documents/Secrets/firebase-service-account.json \\\n'
        '    python backend/scripts/mint_test_token.py)\n'
        'Then re-run flutter test with:\n'
        '  --dart-define=API_BASE_URL=http://10.0.2.2:8000 (Android) or http://localhost:8000 (iOS)\n'
        '  --dart-define=TEST_FIREBASE_TOKEN=\$TOKEN',
      );
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  setUp(() async {
    await FirebaseAuth.instance.signOut();
  });

  group('backend smoke tests', () {
    testWidgets(
      'Google sign-in for provisioned user reaches home screen',
      (tester) async {
        // No httpClient stub — hits the real backend at API_BASE_URL.
        await tester.pumpWidget(app.buildApp());
        await tester.pumpAndSettle();

        // App starts on the sign-in screen.
        expect(find.byType(LoggedOutScreen), findsOneWidget);

        // Simulate completing Google sign-in. A custom token bypasses the
        // native account picker while producing a real Firebase ID token that
        // the backend accepts.
        await FirebaseAuth.instance.signInWithCustomToken(_testFirebaseToken);

        // Allow time for: auth state change → /users/me round-trip → UI rebuild.
        await tester.pump(const Duration(seconds: 8));
        await tester.pumpAndSettle();

        expect(find.byType(ResponderHomeScreen), findsOneWidget);
      },
    );
  });
}
