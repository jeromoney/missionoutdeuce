import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:missionout_responder/firebase_options.dart';
import 'package:missionout_responder/main.dart' as app;
import 'package:missionout_responder/screens/responder_home_screen.dart';

// Host IP of the development machine as seen from the Android emulator.
const _emulatorHost = '10.0.2.2';
const _authEmulatorPort = 9099;
const _projectId = 'mission-out-deuce';

/// Polls the emulator health endpoint until it responds, up to 30 seconds.
/// Throws if the emulator never comes up — gives a clear message instead of
/// a cryptic SocketException deep inside a test.
Future<void> _waitForEmulator() async {
  final uri = Uri.parse(
    'http://$_emulatorHost:$_authEmulatorPort/emulator/v1/projects/$_projectId/oobCodes',
  );
  const maxAttempts = 30;
  for (var i = 0; i < maxAttempts; i++) {
    try {
      final res = await http
          .get(uri, headers: {'Authorization': 'Bearer owner'})
          .timeout(const Duration(seconds: 1));
      if (res.statusCode == 200) return;
    } catch (_) {}
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  throw StateError(
    'Firebase Auth Emulator did not become ready at '
    'http://$_emulatorHost:$_authEmulatorPort after ${maxAttempts}s. '
    'Start it with: firebase emulators:start --only auth --project $_projectId',
  );
}

/// Clears all Firebase Auth emulator accounts between tests.
Future<void> _clearEmulatorAccounts() async {
  await http.delete(
    Uri.parse(
      'http://$_emulatorHost:$_authEmulatorPort/emulator/v1/projects/$_projectId/accounts',
    ),
    headers: {'Authorization': 'Bearer owner'},
  );
}

/// Fetches the most-recently generated OOB sign-in link from the emulator.
Future<String> _getLatestSignInLink() async {
  final response = await http.get(
    Uri.parse(
      'http://$_emulatorHost:$_authEmulatorPort/emulator/v1/projects/$_projectId/oobCodes',
    ),
    headers: {'Authorization': 'Bearer owner'},
  );
  final codes =
      (jsonDecode(response.body)['oobCodes'] as List).cast<Map<String, dynamic>>();
  return codes.last['oobLink'] as String;
}

/// Stub that returns a provisioned MissionOut user for any /users/me request.
http.Client _provisionedStub() {
  return _StubClient((request) async {
    if (request.url.path.endsWith('/users/me')) {
      return http.Response(
        jsonEncode({
          'public_id': 'test-provisioned-1',
          'name': 'Justin Matis',
          'initials': 'JM',
          'role': 'responder',
          'email': 'justin.matis@gmail.com',
          'global_permissions': [],
          'team_memberships': [
            {
              'team_public_id': 'team-smoke-1',
              'team_name': 'Smoke Test Team',
              'roles': ['responder'],
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response('Not found', 404);
  });
}

/// Stub that returns 403 for any /users/me request (user not provisioned).
http.Client _rejectedStub() {
  return _StubClient((request) async {
    if (request.url.path.endsWith('/users/me')) {
      return http.Response('Forbidden', 403);
    }
    return http.Response('Not found', 404);
  });
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _waitForEmulator();
    await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, _authEmulatorPort);
  });

  setUp(() async {
    await FirebaseAuth.instance.signOut();
    await _clearEmulatorAccounts();
  });

  group('auth smoke tests', () {
    testWidgets(
      'provisioned user completes email-link sign-in and reaches home screen',
      (tester) async {
        await tester.pumpWidget(app.buildApp(httpClient: _provisionedStub()));
        await tester.pumpAndSettle();

        // Enter email and request sign-in link.
        await tester.enterText(find.byType(TextField), 'justin.matis@gmail.com');
        await tester.tap(find.byType(FilledButton).first);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        // Confirm the link was sent before fetching OOB codes.
        expect(
          find.textContaining('Check your email'),
          findsOneWidget,
          reason: 'sendSignInLinkToEmail did not complete — check emulator connection and cleartext HTTP in debug manifest',
        );

        // Complete sign-in using the link from the emulator.
        final link = await _getLatestSignInLink();
        await FirebaseAuth.instance.signInWithEmailLink(
          email: 'justin.matis@gmail.com',
          emailLink: link,
        );

        // Wait for auth state + backend stub + UI rebuild.
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        expect(find.byType(ResponderHomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      'unprovisioned user sees rejection banner with their email',
      (tester) async {
        await tester.pumpWidget(app.buildApp(httpClient: _rejectedStub()));
        await tester.pumpAndSettle();

        // Enter email and request sign-in link.
        await tester.enterText(
            find.byType(TextField), 'notinthesystem@gmail.com');
        await tester.tap(find.byType(FilledButton).first);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        // Complete sign-in using the link from the emulator.
        final link = await _getLatestSignInLink();
        await FirebaseAuth.instance.signInWithEmailLink(
          email: 'notinthesystem@gmail.com',
          emailLink: link,
        );

        // Wait for auth state + backend stub + UI rebuild.
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Still on the sign-in screen — no home screen.
        expect(find.byType(ResponderHomeScreen), findsNothing);

        // Rejection banner contains the user's email.
        expect(
          find.textContaining('notinthesystem@gmail.com'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Contact your local administrator'),
          findsOneWidget,
        );
      },
    );
  });
}

class _StubClient extends http.BaseClient {
  _StubClient(this._handler);

  final Future<http.Response> Function(http.BaseRequest) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}
