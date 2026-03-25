import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'auth_user.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required this.loggedOutRoleLabel,
    required this.defaultUser,
    required this.backendBaseUrl,
    this.googleClientId,
  });

  final String loggedOutRoleLabel;
  final AuthUser defaultUser;
  final String backendBaseUrl;
  final String? googleClientId;

  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String get roleLabel => _currentUser?.role ?? loggedOutRoleLabel;

  void loginWithMagicLink({
    required String email,
    AuthUser? user,
  }) {
    final baseUser = user ?? defaultUser;
    _currentUser = baseUser.copyWith(email: email);
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      clientId: googleClientId,
    );

    final account = await googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in cancelled.');
    }

    final authentication = await account.authentication;
    final idToken = authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google sign-in did not return an ID token.');
    }

    final response = await http.post(
      Uri.parse('$backendBaseUrl/auth/google'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_token': idToken,
        'requested_role': loggedOutRoleLabel,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Google auth failed (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid auth response.');
    }

    _currentUser = AuthUser.fromJson(decoded);
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
