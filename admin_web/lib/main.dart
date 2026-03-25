import 'package:flutter/material.dart';
import 'package:shared_auth/shared_auth.dart';

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
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static const googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  final auth = AuthController(
    loggedOutRoleLabel: 'Dispatcher',
    defaultUser: const AuthUser(
      name: 'Justin Mercer',
      initials: 'JM',
      role: 'Dispatcher',
      email: 'justin@missionout.test',
    ),
    backendBaseUrl: apiBaseUrl,
    googleClientId: googleClientId.isEmpty ? null : googleClientId,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.seed,
      brightness: Brightness.light,
      primary: AppPalette.primary,
      secondary: AppPalette.secondary,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MissionOut',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: AppPalette.scaffold,
      ),
      home: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          return auth.isLoggedIn
              ? MissionControlScreen(
                  auth: auth,
                )
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
