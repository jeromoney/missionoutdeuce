import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

import '../app_palette.dart';

class LoggedOutScreen extends StatefulWidget {
  const LoggedOutScreen({
    super.key,
    required this.onMagicLinkLogin,
    required this.onGoogleLogin,
    this.googleLoginEnabled = true,
    this.roleLabel = 'Team Admin',
  });

  final Future<void> Function({required String email}) onMagicLinkLogin;
  final Future<void> Function() onGoogleLogin;
  final bool googleLoginEnabled;
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
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _LoginPanel(
                  emailController: emailController,
                  errorText: errorText,
                  successText: successText,
                  isSubmitting: isSubmitting,
                  googleLoginEnabled: widget.googleLoginEnabled,
                  onMagicLinkLogin: _submitMagicLink,
                  onGoogleLogin: _submitGoogle,
                  roleLabel: widget.roleLabel,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitMagicLink() async {
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
    try {
      await widget.onMagicLinkLogin(email: email);
      if (!mounted) {
        return;
      }
      setState(() {
        successText = 'Check your email for link';
        isSubmitting = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        errorText = error.toString().replaceFirst('Exception: ', '');
        isSubmitting = false;
      });
    }
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

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.emailController,
    required this.errorText,
    required this.successText,
    required this.isSubmitting,
    required this.googleLoginEnabled,
    required this.onMagicLinkLogin,
    required this.onGoogleLogin,
    required this.roleLabel,
  });

  final TextEditingController emailController;
  final String? errorText;
  final String? successText;
  final bool isSubmitting;
  final bool googleLoginEnabled;
  final Future<void> Function() onMagicLinkLogin;
  final Future<void> Function() onGoogleLogin;
  final String roleLabel;

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
          const MissionOutBrandLockup(
            subtitle: 'Secure sign-in for active MissionOut operations.',
            logoSize: 60,
          ),
          const SizedBox(height: 20),
          Text(
            roleLabel,
            style: const TextStyle(
              color: TeamAdminPalette.accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
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
              onPressed: isSubmitting || successText != null
                  ? null
                  : onMagicLinkLogin,
              child: Text(
                isSubmitting
                    ? 'Sending link...'
                    : successText != null
                    ? 'Check your email for link'
                    : 'Email me a sign-in link',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  isSubmitting || !googleLoginEnabled || successText != null
                  ? null
                  : onGoogleLogin,
              icon: const Icon(Icons.login_rounded),
              label: Text(
                googleLoginEnabled
                    ? 'Continue with Google'
                    : 'Google login not configured',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
