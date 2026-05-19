import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_theme/shared_theme.dart';

import 'app_config.dart';
import 'app_palette.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/logged_out_screen.dart';
import 'screens/mission_control_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MissionOutApp());
}

class MissionOutApp extends StatefulWidget {
  const MissionOutApp({super.key});

  @override
  State<MissionOutApp> createState() => _MissionOutAppState();
}

class _MissionOutAppState extends State<MissionOutApp> {
  final auth = AuthController(
    backendBaseUrl: resolveApiBaseUrl(),
    requestedClient: 'dispatcher',
    loggedOutRoleLabel: 'Dispatcher',
    emailLinkContinueUrl:
        emailLinkContinueUrl.isEmpty ? null : emailLinkContinueUrl,
  );

  @override
  void initState() {
    super.initState();
    unawaited(auth.checkIncomingEmailLink());
  }

  @override
  void dispose() {
    auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildMissionOutTheme(accent: AppPalette.secondary),
      home: AuthGate(
        auth: auth,
        loggedInBuilder: (auth) => MissionControlScreen(auth: auth),
        loggedOutBuilder: (auth) => LoggedOutScreen(
          rejectedEmail: auth.rejectedEmail,
          onSendSignInLink: auth.sendSignInLinkToEmail,
          onGoogleLogin: auth.loginWithGoogle,
          googleLoginEnabled: auth.canUseGoogleLogin,
          roleLabel: auth.roleLabel,
        ),
      ),
    );
  }
}

