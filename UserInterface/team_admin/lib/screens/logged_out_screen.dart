import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

import '../app_palette.dart';

class LoggedOutScreen extends StatefulWidget {
  const LoggedOutScreen({
    super.key,
    required this.onMagicLinkLogin,
    required this.onGoogleLogin,
    this.roleLabel = 'Team Admin',
  });

  final void Function({required String email}) onMagicLinkLogin;
  final Future<void> Function() onGoogleLogin;
  final String roleLabel;

  @override
  State<LoggedOutScreen> createState() => _LoggedOutScreenState();
}

class _LoggedOutScreenState extends State<LoggedOutScreen> {
  final emailController = TextEditingController(text: 'justin@missionout.test');
  String? errorText;
  String? successText;
  bool isSubmitting = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MissionOutBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 500,
                      child: _HeroPanel(roleLabel: widget.roleLabel),
                    ),
                    SizedBox(
                      width: 400,
                      child: _LoginPanel(
                        emailController: emailController,
                        errorText: errorText,
                        successText: successText,
                        isSubmitting: isSubmitting,
                        onMagicLinkLogin: _submitMagicLink,
                        onGoogleLogin: _submitGoogle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitMagicLink() {
    final email = emailController.text.trim();
    setState(() {
      errorText = null;
      successText = null;
      isSubmitting = true;
    });
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        errorText = 'Enter a valid email address.';
        isSubmitting = false;
      });
      return;
    }
    widget.onMagicLinkLogin(email: email);
    setState(() {
      successText =
          'Sign-in link sent to $email. For this mock flow, you are now signed in.';
      isSubmitting = false;
    });
  }

  Future<void> _submitGoogle() async {
    setState(() {
      errorText = null;
      successText = null;
      isSubmitting = true;
    });
    try {
      await widget.onGoogleLogin();
    } catch (error) {
      setState(() {
        errorText = error.toString().replaceFirst('Exception: ', '');
        isSubmitting = false;
      });
      return;
    }
    if (mounted) {
      setState(() => isSubmitting = false);
    }
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.roleLabel});

  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: TeamAdminPalette.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: TeamAdminPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MissionOutBrandLockup(
            subtitle:
                'Single-team user administration for memberships, team-scoped roles, device readiness, and response visibility.',
            logoSize: 68,
          ),
          const SizedBox(height: 28),
          const Text(
            'Manage one team well, without spilling into global administration.',
            style: TextStyle(
              fontSize: 34,
              height: 1.06,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              color: TeamAdminPalette.text,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'The Team Admin app is intentionally narrower than dispatcher or super admin. It handles invites, activation, role changes, device health, and team-level visibility for one existing team.',
            style: TextStyle(color: TeamAdminPalette.textSoft, height: 1.55),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SignalChip(label: roleLabel, color: TeamAdminPalette.accent),
              _SignalChip(
                label: 'Single-team scope',
                color: TeamAdminPalette.success,
              ),
              _SignalChip(
                label: 'Deactivate, not delete',
                color: TeamAdminPalette.secondaryAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.emailController,
    required this.errorText,
    required this.successText,
    required this.isSubmitting,
    required this.onMagicLinkLogin,
    required this.onGoogleLogin,
  });

  final TextEditingController emailController;
  final String? errorText;
  final String? successText;
  final bool isSubmitting;
  final VoidCallback onMagicLinkLogin;
  final Future<void> Function() onGoogleLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: TeamAdminPalette.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: TeamAdminPalette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sign in to Team Admin',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              color: TeamAdminPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use a sign-in link or Google to continue into your team-management workspace.',
            style: TextStyle(color: TeamAdminPalette.textSoft, height: 1.5),
          ),
          const SizedBox(height: 22),
          const Text(
            'Email',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: TeamAdminPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'justin@missionout.test',
              errorText: errorText,
            ),
          ),
          if (successText != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TeamAdminPalette.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: TeamAdminPalette.success.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                successText!,
                style: const TextStyle(
                  color: TeamAdminPalette.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSubmitting ? null : onMagicLinkLogin,
              child: Text(
                isSubmitting ? 'Sending link...' : 'Email me a sign-in link',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSubmitting ? null : onGoogleLogin,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Continue with Google'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
