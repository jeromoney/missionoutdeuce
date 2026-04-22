import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_theme/shared_theme.dart';

import '../app_palette.dart';
import '../widgets/common_widgets.dart';

class LoggedOutScreen extends StatefulWidget {
  const LoggedOutScreen({
    super.key,
    required this.onRequestEmailCode,
    required this.onVerifyEmailCode,
    required this.onGoogleLogin,
    this.googleLoginEnabled = true,
    this.googleSignInButton,
    this.roleLabel = 'Dispatcher',
  });

  final Future<void> Function({required String email}) onRequestEmailCode;
  final Future<void> Function({required String email, required String code})
  onVerifyEmailCode;
  final Future<void> Function() onGoogleLogin;
  final bool googleLoginEnabled;
  final Widget? googleSignInButton;
  final String roleLabel;

  @override
  State<LoggedOutScreen> createState() => _LoggedOutScreenState();
}

class _LoggedOutScreenState extends State<LoggedOutScreen> {
  final emailController = TextEditingController();
  final codeController = TextEditingController();

  String? errorText;
  String? successText;
  bool isSubmitting = false;
  bool awaitingCode = false;

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MissionOutBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _LoginPanel(
                  emailController: emailController,
                  codeController: codeController,
                  errorText: errorText,
                  successText: successText,
                  isSubmitting: isSubmitting,
                  awaitingCode: awaitingCode,
                  googleLoginEnabled: widget.googleLoginEnabled,
                  googleSignInButton: widget.googleSignInButton,
                  onSubmitEmailCode: _submitEmailCode,
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

  Future<void> _submitEmailCode() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();

    setState(() {
      errorText = null;
      successText = null;
      isSubmitting = true;
    });

    final emailError = EmailValidator.validate(email);
    if (emailError != null) {
      setState(() {
        errorText = emailError;
        isSubmitting = false;
      });
      return;
    }

    if (awaitingCode && code.isEmpty) {
      setState(() {
        errorText = 'Enter the code from your email.';
        isSubmitting = false;
      });
      return;
    }

    try {
      if (awaitingCode) {
        await widget.onVerifyEmailCode(email: email, code: code);
        return;
      }

      await widget.onRequestEmailCode(email: email);
      if (!mounted) {
        return;
      }
      setState(() {
        successText = 'Check your email for code';
        awaitingCode = true;
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
    required this.codeController,
    required this.errorText,
    required this.successText,
    required this.isSubmitting,
    required this.awaitingCode,
    required this.googleLoginEnabled,
    required this.googleSignInButton,
    required this.onSubmitEmailCode,
    required this.onGoogleLogin,
    required this.roleLabel,
  });

  final TextEditingController emailController;
  final TextEditingController codeController;
  final String? errorText;
  final String? successText;
  final bool isSubmitting;
  final bool awaitingCode;
  final bool googleLoginEnabled;
  final Widget? googleSignInButton;
  final Future<void> Function() onSubmitEmailCode;
  final Future<void> Function() onGoogleLogin;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return SectionShell(
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MissionOutBrandLockup(
            subtitle: 'Secure sign-in for active MissionOut operations.',
            logoSize: 62,
          ),
          const SizedBox(height: 20),
          Text(
            roleLabel,
            style: const TextStyle(
              color: AppPalette.info,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          SectionEyebrow(label: 'Access'),
          const SizedBox(height: 8),
          const Text(
            'Sign in to mission control',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: AppPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use an emailed code or Google to continue into the dispatcher workspace.',
            style: TextStyle(color: AppPalette.textSoft, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Email',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            readOnly: awaitingCode,
            decoration: const InputDecoration(hintText: 'name@example.com'),
          ),
          const SizedBox(height: 10),
          const Text(
            'We will send a sign-in link for this dispatcher account.',
            style: TextStyle(color: AppPalette.textSoft),
          ),
          if (successText != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppPalette.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppPalette.success.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                successText!,
                style: const TextStyle(
                  color: AppPalette.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSubmitting ? null : onSubmitEmailCode,
              child: Text(
                isSubmitting
                    ? (awaitingCode ? 'Verifying code...' : 'Sending code...')
                    : awaitingCode
                    ? 'Verify code'
                    : 'Email me a sign-in code',
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (googleSignInButton != null && googleLoginEnabled)
            SizedBox(width: double.infinity, child: googleSignInButton!)
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isSubmitting || !googleLoginEnabled || awaitingCode
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
