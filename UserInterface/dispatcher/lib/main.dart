import 'package:flutter/material.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_theme/shared_theme.dart';

import 'app_config.dart';
import 'app_palette.dart';
import 'screens/logged_out_screen.dart';
import 'screens/mission_control_screen.dart';

void main() {
  runApp(const MissionOutApp());
}

class MissionOutApp extends StatefulWidget {
  const MissionOutApp({super.key});

  @override
  State<MissionOutApp> createState() => _MissionOutAppState();
}

class _MissionOutAppState extends State<MissionOutApp> {
  final apiBaseUrl = resolveApiBaseUrl();

  final auth = AuthController(
    loggedOutRoleLabel: 'Dispatcher',
    requestedClient: 'dispatcher',
    defaultUser: const AuthUser(
      name: 'Justin Mercer',
      initials: 'JM',
      role: 'Dispatcher',
      email: 'justin@missionout.test',
    ),
    backendBaseUrl: resolveApiBaseUrl(),
    googleClientId: googleClientId.isEmpty ? null : googleClientId,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MissionOut',
      theme: buildMissionOutTheme(accent: AppPalette.secondary),
      home: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          return auth.isLoggedIn
              ? MissionControlScreen(auth: auth)
              : LoggedOutScreen(
                  onMagicLinkLogin: auth.loginWithMagicLink,
                  onGoogleLogin: auth.loginWithGoogle,
                  roleLabel: auth.roleLabel,
                );
        },
      ),
    );
  }
}
