import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

import '../app_palette.dart';

class LoggedOutScreen extends StatefulWidget {
  const LoggedOutScreen({
    super.key,
    required this.onMagicLinkLogin,
    required this.onGoogleLogin,
    this.googleLoginEnabled = true,
    this.roleLabel = 'Responder',
  });

  final void Function({required String email}) onMagicLinkLogin;
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
  final VoidCallback onMagicLinkLogin;
  final Future<void> Function() onGoogleLogin;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: ResponderPalette.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: ResponderPalette.border),
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
              color: ResponderPalette.accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in to responder view',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              color: ResponderPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use a sign-in link or Google to continue to your mission queue.',
            style: TextStyle(color: ResponderPalette.textSoft, height: 1.5),
          ),
          const SizedBox(height: 22),
          const Text(
            'Email',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: ResponderPalette.text,
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
          const SizedBox(height: 10),
          const Text(
            'We will send a sign-in link for this responder account.',
            style: TextStyle(color: ResponderPalette.textSoft),
          ),
          if (successText != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ResponderPalette.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: ResponderPalette.success.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                successText!,
                style: const TextStyle(
                  color: ResponderPalette.success,
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
              onPressed: isSubmitting || !googleLoginEnabled
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
