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
import 'screens/team_admin_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MissionOutTeamAdminApp());
}

class MissionOutTeamAdminApp extends StatefulWidget {
  const MissionOutTeamAdminApp({super.key});

  @override
  State<MissionOutTeamAdminApp> createState() => _MissionOutTeamAdminAppState();
}

class _MissionOutTeamAdminAppState extends State<MissionOutTeamAdminApp> {
  final auth = AuthController(
    backendBaseUrl: resolveApiBaseUrl(),
    requestedClient: 'team_admin',
    loggedOutRoleLabel: 'Team Admin',
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
      theme: buildMissionOutTheme(accent: TeamAdminPalette.accent),
      home: AuthGate(
        auth: auth,
        loggedInBuilder: (auth) => TeamAdminHomeScreen(auth: auth),
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

