import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:missionout_team_admin/l10n/generated/app_localizations.dart';

Widget _harness({required Locale locale, required Widget child}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(builder: (_) => child),
  );
}

void main() {
  testWidgets('English locale resolves keys', (tester) async {
    late AppLocalizations resolved;
    await tester.pumpWidget(
      _harness(
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            resolved = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolved.appName, 'MissionOut Team Admin');
    expect(resolved.emailMeCodeButton, 'Email me a sign-in code');
    expect(resolved.signInTitle, 'Sign in to Team Admin');
    expect(resolved.deviceHealth('healthy'), 'Healthy');
    expect(resolved.deviceHealth('needsReview'), 'Needs review');
  });

  testWidgets('Spanish locale uses stub keys with English fallback', (
    tester,
  ) async {
    late AppLocalizations resolved;
    await tester.pumpWidget(
      _harness(
        locale: const Locale('es'),
        child: Builder(
          builder: (context) {
            resolved = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolved.emailMeCodeButton, 'Envíame un código por correo');
    expect(resolved.signInTitle, 'Sign in to Team Admin');
  });
}
