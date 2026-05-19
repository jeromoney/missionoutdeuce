import 'package:flutter/material.dart';

import 'auth_controller.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.auth,
    required this.loggedInBuilder,
    required this.loggedOutBuilder,
  });

  final AuthController auth;
  final Widget Function(AuthController) loggedInBuilder;
  final Widget Function(AuthController) loggedOutBuilder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        if (auth.isRestoring) return const _AuthLoadingScreen();
        if (auth.needsTeamSelection) return _TeamSelectionScreen(auth: auth);
        if (auth.isLoggedIn) return loggedInBuilder(auth);
        return loggedOutBuilder(auth);
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
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
      body: Center(
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
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
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
    );
  }
}
