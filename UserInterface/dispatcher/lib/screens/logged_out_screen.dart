import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_theme/shared_theme.dart';

import '../app_palette.dart';
import '../l10n/generated/app_localizations.dart';
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
          child: SingleChildScrollView(
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
      ),
    );
  }

  Future<void> _submitEmailCode() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();
    final l10n = AppLocalizations.of(context);

    setState(() {
      errorText = null;
      successText = null;
      isSubmitting = true;
    });

    final emailError = EmailValidator.validate(email);
    if (emailError != null) {
      setState(() {
        errorText = switch (emailError) {
          EmailValidationError.empty => l10n.emailRequired,
          EmailValidationError.invalid => l10n.emailInvalid,
        };
        isSubmitting = false;
      });
      return;
    }

    if (awaitingCode && code.isEmpty) {
      setState(() {
        errorText = l10n.codeRequired;
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
        successText = l10n.codeSentMessage;
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
      if (!mounted) {
        return;
      }
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
    final l10n = AppLocalizations.of(context);
    return SectionShell(
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MissionOutBrandLockup(
            subtitle: l10n.signInBrandSubtitle,
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
          SectionEyebrow(label: l10n.sectionEyebrowAccess),
          const SizedBox(height: 8),
          Text(
            l10n.signInTitle,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: AppPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.signInSubtitle,
            style: const TextStyle(color: AppPalette.textSoft, height: 1.5),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.emailFieldLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            readOnly: awaitingCode,
            decoration: InputDecoration(hintText: l10n.emailFieldHint),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.emailFieldHelp,
            style: const TextStyle(color: AppPalette.textSoft),
          ),
          if (awaitingCode) ...[
            const SizedBox(height: 18),
            Text(
              l10n.codeFieldLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppPalette.text,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.codeFieldHint),
            ),
          ],
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
                    ? (awaitingCode ? l10n.verifyingButton : l10n.sendingButton)
                    : awaitingCode
                    ? l10n.verifyCodeButton
                    : l10n.emailMeCodeButton,
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
                      ? l10n.continueWithGoogle
                      : l10n.googleNotConfigured,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
