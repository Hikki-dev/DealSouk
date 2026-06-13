import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/features/auth/data/auth_service.dart';
import 'package:dealsouk/features/auth/domain/auth_role.dart';
import 'package:dealsouk/core/network/api_client.dart';
import 'package:dealsouk/features/profile/data/profile_service.dart';
import 'package:dealsouk/features/profile/presentation/profile_providers.dart';
import 'package:dealsouk/features/tokens/presentation/tokens_providers.dart';

enum AuthStatus { unknown, unauthenticated, guest, authenticated }

const bool _devMockAdmin = bool.fromEnvironment(
  'DEV_MOCK_ADMIN',
  defaultValue: false,
);

class AuthState {
  final AuthStatus status;
  final User? firebaseUser;
  final String? displayName;
  final Set<AuthRole> roles;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.firebaseUser,
    this.displayName,
    this.roles = const {AuthRole.user},
    this.error,
  });

  bool get isLoggedIn => status == AuthStatus.authenticated;
  bool get isGuest => status == AuthStatus.guest;
  bool get canSubmit => status == AuthStatus.authenticated;
  bool get isAdmin => roles.contains(AuthRole.admin);

  AuthState copyWith({
    AuthStatus? status,
    User? firebaseUser,
    String? displayName,
    Set<AuthRole>? roles,
    String? error,
  }) => AuthState(
    status: status ?? this.status,
    firebaseUser: firebaseUser ?? this.firebaseUser,
    displayName: displayName ?? this.displayName,
    roles: roles ?? this.roles,
    error: error,
  );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() {
      authService.authStateChanges.listen((user) {
        if (user != null && state.status != AuthStatus.authenticated) {
          _syncWithBackend(user);
        } else if (user == null && state.status == AuthStatus.authenticated) {
          state = const AuthState(status: AuthStatus.unauthenticated);
        }
      });
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
        roles: _effectiveRoles(AuthRole.fromClaims(data)),
      );
      _syncProfileProviders(data);
    } catch (_) {
      state = AuthState(
        status: AuthStatus.authenticated,
        firebaseUser: user,
        displayName: user.displayName ?? user.phoneNumber ?? 'Souk User',
        roles: _effectiveRoles(const {AuthRole.user}),
      );
    }
  }

  Set<AuthRole> _effectiveRoles(Set<AuthRole> backendRoles) {
    if (kDebugMode && _devMockAdmin) {
      return {...backendRoles, AuthRole.admin};
    }
    return backendRoles;
  }

  void _syncProfileProviders(Map<String, dynamic> data) {
    try {
      final profileData = ProfileData.fromJson(data);
      ref.read(userTokensProvider.notifier).sync(profileData.tokenBalance);
      ref.read(userProfileProvider.notifier).syncFromProfile(profileData);
      ref.read(userTransactionsProvider.notifier).fetch();
    } catch (_) {}
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.unknown);
    try {
      final result = await authService.signInWithGoogle();
      await _syncWithBackend(result.user!);
    } catch (e) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
      ).copyWith(error: e.toString());
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(status: AuthStatus.unknown);
    try {
      final result = await authService.signInWithApple();
      await _syncWithBackend(result.user!);
    } catch (e) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
      ).copyWith(error: e.toString());
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

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
