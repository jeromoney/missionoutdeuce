@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:missionout_responder/main.dart' as app;

/// Reads errors captured by the console.error hook in web/index.html.
@JS('window.__smokeTestErrors')
external JSArray<JSString>? get _capturedConsoleErrors;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign-in page renders without errors', (tester) async {
    app.main();
    // Allow time for Firebase to initialize and auth state to resolve.
    await tester.pumpAndSettle(const Duration(seconds: 15));

    // Firebase initialized — loading spinner gone, sign-in form visible.
    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'App is still showing a loading spinner — Firebase may have failed to initialize.',
    );
    expect(
      find.byType(TextField),
      findsOneWidget,
      reason: 'Email field not found — sign-in page did not render.',
    );
    expect(
      find.byType(FilledButton),
      findsAtLeastNWidgets(1),
      reason: 'Submit button not found on sign-in page.',
    );

    // No browser console errors during page load.
    final errors = _capturedConsoleErrors?.toDart.map((e) => e.toDart).toList() ?? [];
    expect(errors, isEmpty, reason: 'Browser console errors: $errors');
  });
}
