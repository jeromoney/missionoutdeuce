import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_user.dart';

const _googleScopes = <String>['email', 'profile'];

class AuthController extends ChangeNotifier {
  AuthController({
    required this.loggedOutRoleLabel,
    required this.backendBaseUrl,
    required this.requestedClient,
    this.googleClientId,
  }) {
    unawaited(_restoreSession());
  }

  final String loggedOutRoleLabel;
  final String backendBaseUrl;
  final String requestedClient;
  final String? googleClientId;

  AuthUser? _currentUser;
  bool _isRestoring = true;

  Future<void>? _googleInit;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleEventSub;

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isRestoring => _isRestoring;
  String get roleLabel => _currentUser?.role ?? loggedOutRoleLabel;
  bool get canUseGoogleLogin =>
      googleClientId != null && googleClientId!.trim().isNotEmpty;

  String get _sessionStorageKey => 'missionout.auth.$requestedClient';

  Future<void> initializeGoogleSignIn() {
    return _googleInit ??= GoogleSignIn.instance
        .initialize(clientId: googleClientId)
        .then((_) {
          _googleEventSub ??= GoogleSignIn.instance.authenticationEvents.listen(
            _handleGoogleAuthEvent,
          );
        })
        .catchError((Object error) {
          _googleInit = null;
          throw error;
        });
  }

  Future<void> loginWithEmailCode({required String email}) async {
    final response = await http.post(
      Uri.parse('$backendBaseUrl/auth/email-code'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'requested_client': requestedClient}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_buildEmailCodeError(response));
    }
  }

  Future<void> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$backendBaseUrl/auth/email-code/verify'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_buildEmailCodeError(response));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid auth response.');
    }

    _currentUser = AuthUser.fromJson(
      decoded,
      requestedClient: requestedClient,
      fallbackRole: loggedOutRoleLabel,
    );
    await _persistSession();
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    if (!canUseGoogleLogin) {
      throw Exception(
        'Google login is not configured. Set GOOGLE_CLIENT_ID for this app.',
      );
    }

    await initializeGoogleSignIn();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw Exception(
        'On web, embed MissionOutGoogleLoginButton instead of calling loginWithGoogle().',
      );
    }

    await GoogleSignIn.instance.authenticate(scopeHint: _googleScopes);
  }

  Future<void> _handleGoogleAuthEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      try {
        await _completeGoogleLogin(event.user);
      } catch (_) {
        // Surfaced via the next sign-in attempt; the stream API has no
        // direct callback path back to the UI.
      }
    } else if (event is GoogleSignInAuthenticationEventSignOut) {
      _currentUser = null;
      unawaited(_clearSession());
      notifyListeners();
    }
  }

  Future<void> _completeGoogleLogin(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    final authorization = await account.authorizationClient
        .authorizationForScopes(_googleScopes);
    final accessToken = authorization?.accessToken;

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
    await _persistSession();
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
    unawaited(_clearSession());
    _currentUser = null;
    if (_googleInit != null) {
      unawaited(GoogleSignIn.instance.signOut().catchError((_) => null));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_googleEventSub?.cancel());
    _googleEventSub = null;
    super.dispose();
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

  String _buildEmailCodeError(http.Response response) {
    final prefix = 'Email code request failed (${response.statusCode})';
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

  Future<void> _restoreSession() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final storedSession = preferences.getString(_sessionStorageKey);
      if (storedSession != null && storedSession.isNotEmpty) {
        final decoded = jsonDecode(storedSession);
        if (decoded is Map<String, dynamic>) {
          _currentUser = AuthUser.fromJson(
            decoded,
            requestedClient: requestedClient,
            fallbackRole: loggedOutRoleLabel,
          );
        }
      }
    } catch (_) {
      await _clearSession();
      _currentUser = null;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> _persistSession() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionStorageKey, jsonEncode(user.toJson()));
  }

  Future<void> _clearSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionStorageKey);
  }
}
