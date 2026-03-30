import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'auth_user.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required this.loggedOutRoleLabel,
    required this.defaultUser,
    required this.backendBaseUrl,
    required this.requestedClient,
    this.googleClientId,
  });

  final String loggedOutRoleLabel;
  final AuthUser defaultUser;
  final String backendBaseUrl;
  final String requestedClient;
  final String? googleClientId;

  AuthUser? _currentUser;
  GoogleSignIn? _googleSignIn;

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String get roleLabel => _currentUser?.role ?? loggedOutRoleLabel;
  bool get canUseGoogleLogin =>
      googleClientId != null && googleClientId!.trim().isNotEmpty;

  GoogleSignIn _getGoogleSignIn() {
    return _googleSignIn ??= GoogleSignIn(
      scopes: const ['email', 'profile'],
      clientId: googleClientId,
    );
  }

  Future<void> loginWithMagicLink({required String email}) async {
    final response = await http.post(
      Uri.parse('$backendBaseUrl/auth/email-link'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'requested_client': requestedClient}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_buildEmailLinkError(response));
    }
  }

  Future<void> loginWithGoogle() async {
    if (!canUseGoogleLogin) {
      throw Exception(
        'Google login is not configured. Set GOOGLE_CLIENT_ID for this app.',
      );
    }

    final googleSignIn = _getGoogleSignIn();
    final account = await googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in cancelled.');
    }

    await _completeGoogleLogin(account);
  }

  Future<void> _completeGoogleLogin(GoogleSignInAccount account) async {
    final authentication = await account.authentication;
    final idToken = authentication.idToken;
    final accessToken = authentication.accessToken;
    if ((idToken == null || idToken.isEmpty) &&
        (accessToken == null || accessToken.isEmpty)) {
      throw Exception(
        'Google sign-in did not return a usable token. Check the web client ID configuration.',
      );
    }

    final body = <String, String>{'requested_client': requestedClient};
    if (idToken != null && idToken.isNotEmpty) {
      body['id_token'] = idToken;
    }
    if (accessToken != null && accessToken.isNotEmpty) {
      body['access_token'] = accessToken;
    }

    _currentUser = await _sendGoogleAuthRequest(body);
    notifyListeners();
  }

  Future<AuthUser> _sendGoogleAuthRequest(Map<String, String> body) async {
    final response = await http.post(
      Uri.parse('$backendBaseUrl/auth/google'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_buildBackendError(response));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid auth response.');
    }

    return AuthUser.fromJson(
      decoded,
      requestedClient: requestedClient,
      fallbackRole: loggedOutRoleLabel,
    );
  }

  void logout() {
    _currentUser = null;
    final googleSignIn = _googleSignIn;
    if (googleSignIn != null) {
      unawaited(googleSignIn.signOut().catchError((_) {}));
    }
    notifyListeners();
  }

  String _buildBackendError(http.Response response) {
    final prefix = 'Google auth failed (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return '$prefix: $detail';
        }
      }
    } catch (_) {
      // Ignore malformed error payloads and fall back to the status code.
    }
    return prefix;
  }

  String _buildEmailLinkError(http.Response response) {
    final prefix = 'Email link request failed (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return '$prefix: $detail';
        }
      }
    } catch (_) {
      // Ignore malformed error payloads and fall back to the status code.
    }
    return prefix;
  }
}
