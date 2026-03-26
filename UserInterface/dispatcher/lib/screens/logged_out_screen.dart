import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

import '../app_palette.dart';
import '../widgets/common_widgets.dart';

class LoggedOutScreen extends StatefulWidget {
  const LoggedOutScreen({
    super.key,
    required this.onMagicLinkLogin,
    required this.onGoogleLogin,
    this.roleLabel = 'Dispatcher',
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
              constraints: const BoxConstraints(maxWidth: 1180),
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
                      width: 420,
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
    return SectionShell(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MissionOutBrandLockup(
            subtitle:
                'Dispatch workspace built for fast launch, calm decision-making, and auditable live operations.',
            logoSize: 70,
          ),
          const SizedBox(height: 28),
          const Text(
            'See the mission board, launch incidents fast, and track acknowledgements without losing context.',
            style: TextStyle(
              fontSize: 36,
              height: 1.05,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.4,
              color: AppPalette.text,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'MissionOut keeps dispatch centered on the signal that matters: who has the alert, who is moving, and where response is stalling.',
            style: TextStyle(
              color: AppPalette.textSoft,
              fontSize: 15,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              StatusPill(label: 'Dispatcher workflow', color: AppPalette.info),
              StatusPill(
                label: 'Responder visibility',
                color: AppPalette.success,
              ),
              StatusPill(
                label: 'Audit-friendly activity',
                color: AppPalette.muted,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              MetricBadge(label: 'Role', value: roleLabel),
              const MetricBadge(label: 'Mode', value: 'Web-first'),
              const MetricBadge(label: 'Priority', value: 'Reliability'),
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
    return SectionShell(
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionEyebrow(label: 'Access'),
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
            'Use a sign-in link or Google to continue into the dispatcher workspace.',
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
            decoration: InputDecoration(
              hintText: 'justin@missionout.test',
              errorText: errorText,
            ),
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
