import 'package:flutter/material.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_theme/shared_theme.dart';

import 'app_palette.dart';
import 'screens/logged_out_screen.dart';
import 'screens/responder_home_screen.dart';

void main() {
  runApp(const MissionOutResponderApp());
}

class MissionOutResponderApp extends StatefulWidget {
  const MissionOutResponderApp({super.key});

  @override
  State<MissionOutResponderApp> createState() => _MissionOutResponderAppState();
}

class _MissionOutResponderAppState extends State<MissionOutResponderApp> {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://missionout-backend.onrender.com',
  );
  static const googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  final auth = AuthController(
    loggedOutRoleLabel: 'Responder',
    defaultUser: const AuthUser(
      name: 'Justin Mercer',
      initials: 'JM',
      role: 'Responder',
      email: 'justin@missionout.test',
    ),
    backendBaseUrl: apiBaseUrl,
    googleClientId: googleClientId.isEmpty ? null : googleClientId,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MissionOut Responder',
      theme: buildMissionOutTheme(accent: ResponderPalette.accent),
      home: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          return auth.isLoggedIn
              ? ResponderHomeScreen(auth: auth)
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
