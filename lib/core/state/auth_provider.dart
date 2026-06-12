import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

enum AuthStatus { unknown, unauthenticated, guest, authenticated }

class AuthState {
  final AuthStatus status;
  final User? firebaseUser;
  final String? displayName;
  final bool isAdmin;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.firebaseUser,
    this.displayName,
    this.isAdmin = false,
    this.error,
  });

  bool get isLoggedIn => status == AuthStatus.authenticated;
  bool get isGuest => status == AuthStatus.guest;
  bool get canSubmit => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    User? firebaseUser,
    String? displayName,
    bool? isAdmin,
    String? error,
  }) => AuthState(
    status: status ?? this.status,
    firebaseUser: firebaseUser ?? this.firebaseUser,
    displayName: displayName ?? this.displayName,
    isAdmin: isAdmin ?? this.isAdmin,
    error: error,
  );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Listen to Firebase auth state changes
    authService.authStateChanges.listen((user) {
      if (user != null && state.status != AuthStatus.authenticated) {
        _syncWithBackend(user);
      } else if (user == null && state.status == AuthStatus.authenticated) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });

    final current = authService.currentUser;
    if (current != null) {
      _syncWithBackend(current);
      return AuthState(
        status: AuthStatus.authenticated,
        firebaseUser: current,
        displayName: current.displayName ?? current.phoneNumber,
      );
    }
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _syncWithBackend(User user) async {
    try {
      final res = await apiClient.post('/auth/verify');
      final data = res.data as Map<String, dynamic>;
      state = AuthState(
        status: AuthStatus.authenticated,
        firebaseUser: user,
        displayName: data['displayName'] as String?,
        isAdmin: data['isAdmin'] as bool? ?? false,
      );
    } catch (_) {
      // Backend not reachable yet — still mark as authenticated via Firebase
      state = AuthState(
        status: AuthStatus.authenticated,
        firebaseUser: user,
        displayName: user.displayName ?? user.phoneNumber ?? 'Souk User',
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.unknown);
    try {
      final result = await authService.signInWithGoogle();
      await _syncWithBackend(result.user!);
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated)
          .copyWith(error: e.toString());
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(status: AuthStatus.unknown);
    try {
      final result = await authService.signInWithApple();
      await _syncWithBackend(result.user!);
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated)
          .copyWith(error: e.toString());
    }
  }

  Future<String?> sendOtp(String phoneNumber) async {
    String? verificationId;
    String? errorMsg;

    await authService.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: (id) => verificationId = id,
      onError: (e) => errorMsg = e,
      onAutoVerified: (_) => _syncWithBackend(authService.currentUser!),
    );

    if (errorMsg != null) {
      state = state.copyWith(error: errorMsg);
      return null;
    }
    return verificationId;
  }

  Future<bool> verifyOtp(String verificationId, String smsCode) async {
    try {
      final result = await authService.verifyOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _syncWithBackend(result.user!);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Invalid code. Please try again.');
      return false;
    }
  }

  void continueAsGuest() {
    state = const AuthState(status: AuthStatus.guest, displayName: 'Guest');
  }

  Future<void> signOut() async {
    await authService.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
