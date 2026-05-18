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
      home: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          if (auth.isRestoring) {
            return const _AuthLoadingScreen();
          }
          if (auth.isUnprovisioned) {
            return _UnprovisionedScreen(onLogout: auth.logout);
          }
          if (auth.needsTeamSelection) {
            return _TeamSelectionScreen(auth: auth);
          }
          if (auth.isLoggedIn) {
            return MissionControlScreen(auth: auth);
          }
          return LoggedOutScreen(
            onSendSignInLink: auth.sendSignInLinkToEmail,
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

class _UnprovisionedScreen extends StatelessWidget {
  const _UnprovisionedScreen({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MissionOutBackdrop(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 48),
                  const SizedBox(height: 24),
                  const Text(
                    'Account not provisioned',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your account is not associated with any MissionOut team. '
                    'Contact your administrator to be added.',
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton(
                    onPressed: onLogout,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamSelectionScreen extends StatelessWidget {
  const _TeamSelectionScreen({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final memberships = auth.currentUser?.teamMemberships ?? const [];

    return Scaffold(
      body: MissionOutBackdrop(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a team',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You belong to multiple teams. Choose one to continue.',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  ...memberships.map(
                    (team) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => auth.selectTeam(team),
                          child: Text(team.teamName),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: auth.logout,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
