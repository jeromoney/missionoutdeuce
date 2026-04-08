import 'package:flutter/material.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_theme/shared_theme.dart';

import 'app_config.dart';
import 'app_palette.dart';
import 'screens/logged_out_screen.dart';
import 'screens/team_admin_home_screen.dart';

void main() {
  runApp(const MissionOutTeamAdminApp());
}

class MissionOutTeamAdminApp extends StatefulWidget {
  const MissionOutTeamAdminApp({super.key});

  @override
  State<MissionOutTeamAdminApp> createState() => _MissionOutTeamAdminAppState();
}

class _MissionOutTeamAdminAppState extends State<MissionOutTeamAdminApp> {
  final auth = AuthController(
    loggedOutRoleLabel: 'Team Admin',
    requestedClient: 'team_admin',
    backendBaseUrl: resolveApiBaseUrl(),
    googleClientId: googleClientId.isEmpty ? null : googleClientId,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MissionOut Team Admin',
      theme: buildMissionOutTheme(accent: TeamAdminPalette.accent),
      home: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          if (auth.isRestoring) {
            return const _AuthLoadingScreen();
          }
          return auth.isLoggedIn
              ? TeamAdminHomeScreen(auth: auth)
              : LoggedOutScreen(
                  onRequestEmailCode: auth.loginWithEmailCode,
                  onVerifyEmailCode: auth.verifyEmailCode,
                  onGoogleLogin: auth.loginWithGoogle,
                  googleLoginEnabled: auth.canUseGoogleLogin,
                  roleLabel: auth.roleLabel,
                );
        },
      ),
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: MissionOutBackdrop(
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
