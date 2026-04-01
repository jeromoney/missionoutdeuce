import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:missionout/screens/logged_out_screen.dart';

void main() {
  testWidgets('renders dispatcher sign-in screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoggedOutScreen(
          onRequestEmailCode: ({required email}) async {},
          onVerifyEmailCode: ({required email, required code}) async {},
          onGoogleLogin: () async {},
        ),
      ),
    );

    expect(find.text('Sign in to mission control'), findsOneWidget);
    expect(find.text('Email me a sign-in code'), findsOneWidget);
  });
}
