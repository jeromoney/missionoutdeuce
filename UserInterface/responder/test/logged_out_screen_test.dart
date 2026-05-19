import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:missionout_responder/l10n/generated/app_localizations.dart';
import 'package:missionout_responder/screens/logged_out_screen.dart';

Widget _harness({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  group('LoggedOutScreen email link sign-in', () {
    testWidgets(
      'shows error when emailLinkContinueUrl is not configured',
      (tester) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _harness(
            child: LoggedOutScreen(
              onSendSignInLink: (_) async => throw Exception(
                'Set emailLinkContinueUrl on AuthController to use Email Link sign-in.',
              ),
              onGoogleLogin: () async {},
            ),
          ),
        );

        await tester.enterText(
          find.byType(TextField),
          'user@example.test',
        );
        await tester.tap(find.text('Email me a sign-in link'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Set emailLinkContinueUrl on AuthController to use Email Link sign-in.',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
