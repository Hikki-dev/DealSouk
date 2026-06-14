import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _googleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    // Web signs in via Firebase's popup flow (see signInWithGoogle), so the
    // google_sign_in package is only initialized on native platforms, where
    // the client ID comes from google-services.json / GoogleService-Info.plist.
    if (kIsWeb) {
      _googleSignInInitialized = true;
      return;
    }
    await GoogleSignIn.instance.initialize();
    _googleSignInInitialized = true;
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  ConfirmationResult? _webConfirmationResult;

  // --- Phone OTP ---

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(PhoneAuthCredential)? onAutoVerified,
  }) async {
    if (kIsWeb) {
      try {
        final result = await _auth.signInWithPhoneNumber(phoneNumber);
        _webConfirmationResult = result;
        onCodeSent('web');
      } catch (e) {
        onError(e.toString());
      }
      return;
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
        onAutoVerified?.call(credential);
      },
      verificationFailed: (e) => onError(e.message ?? 'Verification failed'),
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    if (kIsWeb) {
      if (_webConfirmationResult == null) {
        throw StateError('No confirmation result found for Web OTP verification.');
      }
      return _webConfirmationResult!.confirm(smsCode);
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  // --- Google Sign-In ---

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      // Firebase popup flow. No OAuth client ID needed in code — it works as
      // long as the deploy origin (e.g. deal-souk.vercel.app) is listed under
      // Firebase Console → Authentication → Settings → Authorized domains.
      return _auth.signInWithPopup(GoogleAuthProvider());
    }
    await _ensureGoogleSignInInitialized();
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  // --- Apple Sign-In ---

  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider(
      'apple.com',
    ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

    return _auth.signInWithCredential(oauthCredential);
  }

  // --- Sign Out ---

  Future<void> signOut() async {
    if (kIsWeb) {
      await _auth.signOut();
      return;
    }
    await _ensureGoogleSignInInitialized();
    await Future.wait([_auth.signOut(), GoogleSignIn.instance.signOut()]);
  }

  // --- Get ID Token (for backend calls) ---

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  }

  // --- Helpers ---

  String _generateNonce([int length = 32]) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

final authService = AuthService();
