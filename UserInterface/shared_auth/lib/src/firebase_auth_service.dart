import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pendingEmailKey = 'missionout.auth.pending_email_link';

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  Future<void>? _googleSignInInitFuture;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      _googleSignInInitFuture ??= GoogleSignIn.instance.initialize();
      await _googleSignInInitFuture;
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credential);
    }
  }

  Future<void> sendSignInLinkToEmail(
    String email, {
    required String continueUrl,
  }) async {
    final settings = ActionCodeSettings(url: continueUrl, handleCodeInApp: true);
    await _auth.sendSignInLinkToEmail(email: email, actionCodeSettings: settings);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingEmailKey, email);
  }

  Future<void> handleEmailLink({
    required String email,
    required String emailLink,
  }) async {
    if (!_auth.isSignInWithEmailLink(emailLink)) {
      throw Exception('Not a valid email sign-in link.');
    }
    await _auth.signInWithEmailLink(email: email, emailLink: emailLink);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingEmailKey);
  }

  /// On web: checks if the current URL is a pending email sign-in link and
  /// completes sign-in automatically using the email stored by
  /// [sendSignInLinkToEmail]. No-op on non-web platforms.
  Future<void> checkAndHandleIncomingEmailLink() async {
    if (!kIsWeb) return;
    final link = Uri.base.toString();
    if (!_auth.isSignInWithEmailLink(link)) return;
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_pendingEmailKey);
    if (email == null || email.isEmpty) return;
    await handleEmailLink(email: email, emailLink: link);
  }

  bool isSignInWithEmailLink(String link) => _auth.isSignInWithEmailLink(link);

  Future<String?> getIdToken({bool forceRefresh = false}) =>
      _auth.currentUser?.getIdToken(forceRefresh) ?? Future.value(null);

  Future<void> signOut() => _auth.signOut();
}
