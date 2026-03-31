import 'package:flutter/material.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_theme/shared_theme.dart';

import 'app_config.dart';
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
  static const googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  final auth = AuthController(
    loggedOutRoleLabel: 'Responder',
    requestedClient: 'responder',
    defaultUser: const AuthUser(
      name: 'Justin Mercer',
      initials: 'JM',
      role: 'Responder',
      email: 'justin@missionout.test',
    ),
    backendBaseUrl: resolveApiBaseUrl(),
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
          if (auth.isRestoring) {
            return const _AuthLoadingScreen();
          }
          return auth.isLoggedIn
              ? ResponderHomeScreen(auth: auth)
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
