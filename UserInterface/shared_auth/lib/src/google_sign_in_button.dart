import 'package:flutter/widgets.dart';

import 'auth_controller.dart';
import 'google_sign_in_button_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_button_web.dart';

class MissionOutGoogleLoginButton extends StatelessWidget {
  const MissionOutGoogleLoginButton({super.key, required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return buildGoogleSignInButton(controller);
  }
}
