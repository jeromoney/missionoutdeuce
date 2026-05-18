import 'package:flutter/material.dart';

import 'auth_controller.dart';

class MissionOutGoogleLoginButton extends StatelessWidget {
  const MissionOutGoogleLoginButton({super.key, required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: controller.loginWithGoogle,
      icon: const Icon(Icons.login_rounded),
      label: const Text('Continue with Google'),
    );
  }
}
