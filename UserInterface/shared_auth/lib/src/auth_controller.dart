import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_user.dart';

const _googleScopes = <String>['email', 'profile'];

/// How close to expiry an access token must be before we proactively refresh.
const _accessTokenRefreshSkew = Duration(seconds: 60);

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
  Future<String?>? _inFlightRefresh;

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

    _currentUser = AuthUser.fromSessionJson(
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

    return AuthUser.fromSessionJson(
      decoded,
      requestedClient: requestedClient,
      fallbackRole: loggedOutRoleLabel,
    );
  }

  /// Returns a fresh access token, transparently refreshing it via
  /// `/auth/refresh` if it is within [_accessTokenRefreshSkew] of expiry. If
  /// no session is loaded or the refresh fails, returns null and forces a
  /// sign-out so the UI can route to the login screen.
  Future<String?> ensureFreshAccessToken() async {
    final user = _currentUser;
    if (user == null) {
      return null;
    }

    final expiresAt = user.accessTokenExpiresAt;
    final mustRefresh = expiresAt == null
        ? user.accessToken == null
        : DateTime.now()
            .toUtc()
            .add(_accessTokenRefreshSkew)
            .isAfter(expiresAt);

    if (!mustRefresh) {
      return user.accessToken;
    }

    return _inFlightRefresh ??= _performRefresh().whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  Future<String?> _performRefresh() async {
    final refreshToken = _currentUser?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _forceSignOut();
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/auth/refresh'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 401) {
        await _forceSignOut();
        return null;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_buildBackendError(response));
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid refresh response.');
      }

      _currentUser = AuthUser.fromSessionJson(
        decoded,
        requestedClient: requestedClient,
        fallbackRole: loggedOutRoleLabel,
      );
      await _persistSession();
      notifyListeners();
      return _currentUser?.accessToken;
    } on Exception {
      await _forceSignOut();
      rethrow;
    }
  }

  Future<void> _forceSignOut() async {
    _currentUser = null;
    await _clearSession();
    notifyListeners();
  }

  /// Service clients invoke this on a 401 response. Triggers one refresh; if
  /// it succeeds, callers can retry the original request with the new token.
  Future<String?> handleUnauthorized() async {
    final user = _currentUser;
    if (user?.refreshToken == null) {
      await _forceSignOut();
      return null;
    }
    return _performRefresh();
  }

  Future<void> logout() async {
    final refreshToken = _currentUser?.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('$backendBaseUrl/auth/logout'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        );
      } catch (_) {
        // Best-effort revocation; the local session is cleared regardless.
      }
    }

    _currentUser = null;
    await _clearSession();
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
    final prefix = 'Auth request failed (${response.statusCode})';
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
          _currentUser = AuthUser.fromSessionJson(
            decoded,
            requestedClient: requestedClient,
            fallbackRole: loggedOutRoleLabel,
          );
          // If the persisted access token is already expired, attempt a
          // background refresh so the UI doesn't have to wait until the
          // first authenticated call to discover the staleness.
          final expiresAt = _currentUser?.accessTokenExpiresAt;
          if (expiresAt != null &&
              DateTime.now().toUtc().isAfter(expiresAt) &&
              (_currentUser?.refreshToken?.isNotEmpty ?? false)) {
            unawaited(ensureFreshAccessToken());
          }
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
