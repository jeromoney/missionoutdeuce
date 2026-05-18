import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:missionout/l10n/generated/app_localizations.dart';
import 'package:missionout/screens/logged_out_screen.dart';

void main() {
  testWidgets('renders dispatcher sign-in screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoggedOutScreen(
          onSendSignInLink: (email) async {},
          onGoogleLogin: () async {},
        ),
      ),
    );

    expect(find.text('Sign in to mission control'), findsOneWidget);
    expect(find.text('Email me a sign-in link'), findsOneWidget);
  });

  testWidgets('shows link-sent confirmation after sending sign-in link',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoggedOutScreen(
          onSendSignInLink: (email) async {},
          onGoogleLogin: () async {},
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.tap(find.text('Email me a sign-in link'));
    await tester.pumpAndSettle();

    expect(find.text('Resend link'), findsOneWidget);
  });

  testWidgets('shows error message when send-link request fails',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoggedOutScreen(
          onSendSignInLink: (_) async {
            throw Exception('Server error');
          },
          onGoogleLogin: () async {},
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.tap(find.text('Email me a sign-in link'));
    await tester.pumpAndSettle();

    expect(find.text('Server error'), findsOneWidget);
    expect(find.text('Resend link'), findsNothing);
  });
}
