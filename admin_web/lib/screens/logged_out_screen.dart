import 'package:flutter/material.dart';

import '../app_palette.dart';

class LoggedOutScreen extends StatefulWidget {
  const LoggedOutScreen({
    super.key,
    required this.onMagicLinkLogin,
    required this.onGoogleLogin,
    this.roleLabel = 'Dispatcher',
  });

  final void Function({
    required String email,
  }) onMagicLinkLogin;
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppPalette.gradientTop, AppPalette.gradientBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppPalette.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'MissionOut Admin',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Dispatcher and administrative controls for incidents, response visibility, and alert operations.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppPalette.textSoft,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCE8F4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.roleLabel,
                      style: const TextStyle(
                        color: AppPalette.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _fieldLabel('Email'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      hintText: 'justin@missionout.test',
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Enter your email and we will send you a sign-in link.',
                      style: TextStyle(color: AppPalette.textSoft),
                    ),
                  ),
                  if (successText != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4F3EB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF94C7A8)),
                      ),
                      child: Text(
                        successText!,
                        style: const TextStyle(
                          color: Color(0xFF246B45),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting ? null : _submitMagicLink,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPalette.info,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        isSubmitting ? 'Sending link...' : 'Email me a sign-in link',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isSubmitting ? null : _submitGoogle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppPalette.text,
                        side: const BorderSide(color: AppPalette.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                      ),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      filled: true,
      fillColor: const Color(0xFFF7FAFD),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppPalette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppPalette.info,
          width: 1.4,
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppPalette.text,
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
      successText = 'Sign-in link sent to $email. For this mock flow, you are now signed in.';
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
      setState(() {
        isSubmitting = false;
      });
    }
  }
}
