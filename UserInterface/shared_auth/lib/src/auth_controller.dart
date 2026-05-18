import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_user.dart';
import 'firebase_auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required this.backendBaseUrl,
    required this.requestedClient,
    this.loggedOutRoleLabel = 'User',
    this.googleLoginEnabled = true,
    this.emailLinkContinueUrl,
    FirebaseAuthService? firebaseAuthService,
  }) : _firebase = firebaseAuthService ?? FirebaseAuthService() {
    _authSub = _firebase.authStateChanges.listen(_onAuthStateChanged);
  }

  final String backendBaseUrl;
  final String requestedClient;
  final String loggedOutRoleLabel;
  final bool googleLoginEnabled;

  /// The URL Firebase redirects to after the user taps an Email Link.
  /// Must be an authorized domain in the Firebase console.
  final String? emailLinkContinueUrl;

  final FirebaseAuthService _firebase;
  StreamSubscription<User?>? _authSub;

  bool _isRestoring = true;
  bool _isUnprovisioned = false;
  AuthUser? _profile;
  AuthTeamMembership? _activeTeam;

  /// True while the initial Firebase auth state is being determined.
  bool get isRestoring => _isRestoring;

  /// True when Firebase authenticated but the user has no MissionOut
  /// Team Membership — show "contact your administrator" screen.
  bool get isUnprovisioned => _isUnprovisioned;

  /// True when the user has a MissionOut Profile but has not yet selected
  /// an Active Team (only possible with 2+ memberships).
  bool get needsTeamSelection =>
      _profile != null && _activeTeam == null && !_isUnprovisioned;

  /// True when fully authenticated: Firebase OK + MissionOut Profile + Active Team.
  bool get isLoggedIn => _profile != null && _activeTeam != null;

  AuthUser? get currentUser => _profile;
  AuthTeamMembership? get activeTeam => _activeTeam;
  bool get canUseGoogleLogin => googleLoginEnabled;
  String get roleLabel => _profile?.role ?? loggedOutRoleLabel;

  // ── Sign-in ──────────────────────────────────────────────────────────────

  Future<void> loginWithGoogle() => _firebase.signInWithGoogle();

  Future<void> sendSignInLinkToEmail(String email) async {
    final url = emailLinkContinueUrl;
    if (url == null || url.isEmpty) {
      throw Exception(
        'Set emailLinkContinueUrl on AuthController to use Email Link sign-in.',
      );
    }
    await _firebase.sendSignInLinkToEmail(email, continueUrl: url);
  }

  Future<void> handleEmailLink({
    required String email,
    required String emailLink,
  }) =>
      _firebase.handleEmailLink(email: email, emailLink: emailLink);

  /// Call on app startup and when the app receives a deep link. Automatically
  /// completes a pending email-link sign-in on web.
  Future<void> checkIncomingEmailLink() =>
      _firebase.checkAndHandleIncomingEmailLink();

  // ── Active Team ──────────────────────────────────────────────────────────

  Future<void> selectTeam(AuthTeamMembership team) async {
    _activeTeam = team;
    notifyListeners();
    await _persistActiveTeam(team.teamPublicId);
  }

  // ── Token ────────────────────────────────────────────────────────────────

  /// Returns a fresh Firebase ID token. Firebase handles refresh automatically.
  Future<String?> getIdToken() => _firebase.getIdToken();

  bool isSignInWithEmailLink(String link) =>
      _firebase.isSignInWithEmailLink(link);

  // ── Sign-out ─────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final uid = _firebase.currentUser?.uid;
    _profile = null;
    _activeTeam = null;
    _isUnprovisioned = false;
    if (uid != null) {
      await _clearActiveTeam(uid);
    }
    await _firebase.signOut();
    notifyListeners();
  }

  // ── Firebase auth state ──────────────────────────────────────────────────

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _profile = null;
      _activeTeam = null;
      _isUnprovisioned = false;
      _isRestoring = false;
      notifyListeners();
      return;
    }

    try {
      final idToken = await _firebase.getIdToken();
      final response = await http.get(
        Uri.parse('$backendBaseUrl/users/me'),
        headers: {
          if (idToken != null && idToken.isNotEmpty)
            'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          _profile = AuthUser.fromJson(
            decoded,
            requestedClient: requestedClient,
            fallbackRole: loggedOutRoleLabel,
          );
          _isUnprovisioned = _profile!.teamMemberships.isEmpty;
          _activeTeam = _isUnprovisioned
              ? null
              : await _restoreActiveTeam(user.uid, _profile!.teamMemberships);
        }
      } else {
        _profile = null;
        _isUnprovisioned = false;
        _activeTeam = null;
      }
    } catch (_) {
      _profile = null;
      _isUnprovisioned = false;
      _activeTeam = null;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  // ── Active Team persistence ───────────────────────────────────────────────

  Future<AuthTeamMembership?> _restoreActiveTeam(
    String uid,
    List<AuthTeamMembership> memberships,
  ) async {
    if (memberships.length == 1) {
      await _persistActiveTeam(memberships.first.teamPublicId, uid: uid);
      return memberships.first;
    }
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_teamKey(uid));
    if (savedId != null && savedId.isNotEmpty) {
      final match = memberships
          .where((m) => m.teamPublicId == savedId)
          .firstOrNull;
      if (match != null) return match;
    }
    return null;
  }

  String _teamKey(String uid) =>
      'missionout.active_team.$uid.$requestedClient';

  Future<void> _persistActiveTeam(String teamId, {String? uid}) async {
    final effectiveUid = uid ?? _firebase.currentUser?.uid;
    if (effectiveUid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_teamKey(effectiveUid), teamId);
  }

  Future<void> _clearActiveTeam(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_teamKey(uid));
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
