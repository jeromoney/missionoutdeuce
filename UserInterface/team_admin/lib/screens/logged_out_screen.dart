import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_theme/shared_theme.dart';

import '../app_palette.dart';
import '../l10n/generated/app_localizations.dart';

class LoggedOutScreen extends StatefulWidget {
  const LoggedOutScreen({
    super.key,
    required this.onSendSignInLink,
    required this.onGoogleLogin,
    this.googleLoginEnabled = true,
    this.roleLabel = 'Team Admin',
    this.rejectedEmail,
  });

  final Future<void> Function(String email) onSendSignInLink;
  final Future<void> Function() onGoogleLogin;
  final bool googleLoginEnabled;
  final String roleLabel;
  final String? rejectedEmail;

  @override
  State<LoggedOutScreen> createState() => _LoggedOutScreenState();
}

class _LoggedOutScreenState extends State<LoggedOutScreen> {
  final emailController = TextEditingController();

  String? errorText;
  String? successText;
  bool isSubmitting = false;
  bool linkSent = false;

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
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _LoginPanel(
                  emailController: emailController,
                  errorText: errorText,
                  successText: successText,
                  isSubmitting: isSubmitting,
                  linkSent: linkSent,
                  googleLoginEnabled: widget.googleLoginEnabled,
                  onSendSignInLink: _sendSignInLink,
                  onGoogleLogin: _submitGoogle,
                  roleLabel: widget.roleLabel,
                  rejectedEmail: widget.rejectedEmail,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendSignInLink() async {
    final email = emailController.text.trim();
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

    try {
      await widget.onSendSignInLink(email);
      if (!mounted) return;
      setState(() {
        successText = l10n.linkSentMessage;
        linkSent = true;
        isSubmitting = false;
      });
    } catch (error) {
      if (!mounted) return;
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
      if (!mounted) return;
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
    required this.linkSent,
    required this.googleLoginEnabled,
    required this.onSendSignInLink,
    required this.onGoogleLogin,
    required this.roleLabel,
    this.rejectedEmail,
  });

  final TextEditingController emailController;
  final String? errorText;
  final String? successText;
  final bool isSubmitting;
  final bool linkSent;
  final bool googleLoginEnabled;
  final Future<void> Function() onSendSignInLink;
  final Future<void> Function() onGoogleLogin;
  final String roleLabel;
  final String? rejectedEmail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          MissionOutBrandLockup(
            subtitle: l10n.signInBrandSubtitle,
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
          Text(
            l10n.signInTitle,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              color: TeamAdminPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.signInSubtitle,
            style: const TextStyle(
              color: TeamAdminPalette.textSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          if (rejectedEmail != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TeamAdminPalette.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: TeamAdminPalette.accent.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                l10n.contactAdministrator(rejectedEmail!),
                style: const TextStyle(
                  color: TeamAdminPalette.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            l10n.emailFieldLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: TeamAdminPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            readOnly: linkSent,
            decoration: InputDecoration(hintText: l10n.emailFieldHint),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.emailFieldHelpInitial,
            style: const TextStyle(color: TeamAdminPalette.textSoft),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TeamAdminPalette.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: TeamAdminPalette.danger.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                errorText!,
                style: const TextStyle(
                  color: TeamAdminPalette.danger,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
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
              onPressed: isSubmitting ? null : onSendSignInLink,
              child: Text(
                isSubmitting
                    ? l10n.sendingButton
                    : linkSent
                        ? l10n.resendLinkButton
                        : l10n.emailMeCodeButton,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSubmitting || !googleLoginEnabled ? null : onGoogleLogin,
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
