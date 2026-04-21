import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

import 'auth_controller.dart';

Widget buildGoogleSignInButton(AuthController controller) {
  return _WebGoogleSignInButton(controller: controller);
}

class _WebGoogleSignInButton extends StatefulWidget {
  const _WebGoogleSignInButton({required this.controller});

  final AuthController controller;

  @override
  State<_WebGoogleSignInButton> createState() => _WebGoogleSignInButtonState();
}

class _WebGoogleSignInButtonState extends State<_WebGoogleSignInButton> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = widget.controller.initializeGoogleSignIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 44,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Text(
            'Google sign-in unavailable: ${snapshot.error}',
            style: const TextStyle(color: Colors.redAccent),
          );
        }
        return web.renderButton();
      },
    );
  }
}
