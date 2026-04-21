import 'package:flutter/foundation.dart';
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
          if (auth.isRestoring) {
            return const _AuthLoadingScreen();
          }
          return auth.isLoggedIn
              ? MissionControlScreen(auth: auth)
              : LoggedOutScreen(
                  onRequestEmailCode: auth.loginWithEmailCode,
                  onVerifyEmailCode: auth.verifyEmailCode,
                  onGoogleLogin: auth.loginWithGoogle,
                  googleLoginEnabled: auth.canUseGoogleLogin,
                  googleSignInButton: kIsWeb && auth.canUseGoogleLogin
                      ? MissionOutGoogleLoginButton(controller: auth)
                      : null,
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
