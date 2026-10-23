import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/features/auth/data/auth_service.dart';
import 'package:dealsouk/features/auth/domain/auth_role.dart';
import 'package:dealsouk/core/network/api_client.dart';
import 'package:dealsouk/features/profile/data/profile_service.dart';
import 'package:dealsouk/features/profile/presentation/profile_providers.dart';
import 'package:dealsouk/core/offline/sync_service.dart';
import 'package:dealsouk/features/tokens/presentation/tokens_providers.dart';

enum AuthStatus { unknown, unauthenticated, guest, authenticated }

const bool _devMockAdmin = bool.fromEnvironment(
  'DEV_MOCK_ADMIN',
  defaultValue: false,
);

// The admin web console routes on role (admin vs unauthorized), so it must wait
// for the backend before it can decide. The shopper app never gates navigation
// on roles, so it flips to authenticated as soon as Firebase resolves.
const bool _adminMode = bool.fromEnvironment('ADMIN_MODE', defaultValue: false);

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
  bool get isDemoViewer => !isAdmin && roles.contains(AuthRole.demo);

  /// May open the moderator console. Demo viewers only in the admin build, and
  /// the API still refuses every change they try.
  bool get canViewAdmin => isAdmin || (_adminMode && isDemoViewer);

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
    // Store and cancel the subscription on dispose to prevent memory leaks and
    // duplicate listeners when the notifier is rebuilt (H-12).
    final subscription = authService.authStateChanges.listen((user) {
      if (user != null && state.status != AuthStatus.authenticated) {
        _syncWithBackend(user);
      } else if (user == null && state.status == AuthStatus.authenticated) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
    ref.onDispose(subscription.cancel);

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
      _syncProfileProviders(data, firebaseUser: user);
      // Pull the full economy (streak, accuracy, approved/total counts, and the
      // user's own submissions) from /profile/me and reconcile every provider to
      // DB truth. Fire-and-forget so login isn't blocked on the round-trip.
      unawaited(refreshProfile());
    } catch (_) {
      if (_adminMode) {
        // Admin route gating depends on a confirmed role from the backend.
        // The first attempt may have failed because:
        //   (a) Render was cold-starting, or
        //   (b) the Firebase token hadn't yet propagated newly-set custom claims.
        // Force-refresh the token (pulls the latest claims from Firebase) and
        // retry the backend call once before giving up.
        try {
          await user.getIdToken(
            true,
          ); // force-refresh so backend sees fresh claims
          final retry = await apiClient.post('/auth/verify');
          final data = retry.data as Map<String, dynamic>;
          state = AuthState(
            status: AuthStatus.authenticated,
            firebaseUser: user,
            displayName: data['displayName'] as String?,
            roles: _effectiveRoles(AuthRole.fromClaims(data)),
          );
          _syncProfileProviders(data, firebaseUser: user);
          unawaited(refreshProfile());
          return;
        } catch (_) {
          // Both attempts failed. Drop back to unauthenticated so the router
          // sends the user to /welcome where they can retry — instead of landing
          // on /unauthorized with no way out (fixed separately in that screen).
          state = const AuthState(status: AuthStatus.unauthenticated);
          return;
        }
      }
      state = AuthState(
        status: AuthStatus.authenticated,
        firebaseUser: user,
        displayName: user.displayName ?? user.phoneNumber ?? 'Souk User',
        roles: _effectiveRoles(const {AuthRole.user}),
      );
      // Backend unreachable (e.g. Render cold start). Still surface the Google/
      // Apple account's name + photo so the greeting and avatar aren't blank.
      if (user.displayName != null || user.photoURL != null) {
        ref
            .read(userProfileProvider.notifier)
            .seedFromAccount(name: user.displayName, avatarUrl: user.photoURL);
      }
    }
  }

  // Finish an interactive sign-in once Firebase has authenticated [user].
  //
  // Shopper app: flip to `authenticated` immediately (so the router leaves the
  // welcome/loading screen without waiting on a possibly cold-starting backend)
  // and reconcile roles/profile in the background. This mirrors what `build()`
  // already does for a restored session and fixes the long login spinner / the
  // app being stuck on the loading screen until a tab switch.
  //
  // Admin web: keep awaiting the backend, because the route choice (AdminScreen
  // vs UnauthorizedScreen) depends on the role that only the backend knows.
  Future<void> _completeSignIn(User user) async {
    if (_adminMode) {
      await _syncWithBackend(user);
      return;
    }
    state = AuthState(
      status: AuthStatus.authenticated,
      firebaseUser: user,
      displayName: user.displayName ?? user.phoneNumber,
    );
    unawaited(_syncWithBackend(user));
  }

  Set<AuthRole> _effectiveRoles(Set<AuthRole> backendRoles) {
    if (kDebugMode && _devMockAdmin) {
      return {...backendRoles, AuthRole.admin};
    }
    return backendRoles;
  }

  void _syncProfileProviders(Map<String, dynamic> data, {User? firebaseUser}) {
    try {
      final profileData = ProfileData.fromJson(data);
      ref.read(userTokensProvider.notifier).sync(profileData.tokenBalance);
      ref.read(badgesProvider.notifier).syncFromProfile(profileData);
      ref
          .read(userProfileProvider.notifier)
          .syncFromProfile(
            profileData,
            // Default to the Google/Apple account's name + photo when the
            // backend has none, so the greeting and avatar populate instantly.
            fallbackName: firebaseUser?.displayName,
            fallbackAvatarUrl: firebaseUser?.photoURL,
          );
      ref.read(userTransactionsProvider.notifier).fetch();
    } catch (_) {}
  }

  /// Re-fetch GET /profile/me and reconcile every per-user provider to the
  /// server's truth: token balance, streak, accuracy/approved/total stats, the
  /// profile (name/area/avatar), token history, and the user's submissions.
  /// Called on login and after any action that changes the economy (submitting
  /// a price, fulfilling/cancelling a request) so optimistic UI converges to DB
  /// and survives an app restart or a switch to another device.
  Future<void> refreshProfile() async {
    if (state.status != AuthStatus.authenticated) return;
    try {
      final profile = await profileService.getMyProfile();
      ref.read(userTokensProvider.notifier).sync(profile.tokenBalance);
      ref.read(badgesProvider.notifier).syncFromProfile(profile);
      ref
          .read(streakProvider.notifier)
          .sync(profile.currentStreak, profile.longestStreak);
      ref.read(userStatsProvider.notifier).sync(profile);
      ref
          .read(userProfileProvider.notifier)
          .syncFromProfile(
            profile,
            fallbackName: state.firebaseUser?.displayName,
            fallbackAvatarUrl: state.firebaseUser?.photoURL,
          );
      await ref.read(userTransactionsProvider.notifier).fetch();
      await ref.read(mySubmissionsProvider.notifier).fetch();
      await ref.read(dailyChallengeProvider.notifier).fetchToday();
    } catch (_) {}
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.unknown);
    try {
      final result = await authService.signInWithGoogle();
      await _completeSignIn(result.user!);
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
      await _completeSignIn(result.user!);
    } catch (e) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
      ).copyWith(error: e.toString());
    }
  }

  Future<String?> sendOtp(String phoneNumber) async {
    state = state.copyWith(error: null);
    final completer = Completer<String?>();

    try {
      await authService.sendOtp(
        phoneNumber: phoneNumber,
        onCodeSent: (id) {
          if (!completer.isCompleted) {
            completer.complete(id);
          }
        },
        onError: (e) {
          state = state.copyWith(error: e);
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
        onAutoVerified: (_) => _syncWithBackend(authService.currentUser!),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }

    return completer.future;
  }

  Future<bool> verifyOtp(String verificationId, String smsCode) async {
    state = state.copyWith(error: null);
    try {
      final result = await authService.verifyOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _completeSignIn(result.user!);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Invalid code. Please try again.');
      return false;
    }
  }

  void continueAsGuest() {
    state = const AuthState(status: AuthStatus.guest, displayName: 'Demo');
    // Restore any on-device demo profile (name/avatar/area saved locally).
    ref.read(userProfileProvider.notifier).loadGuestProfile();
  }

  Future<void> signOut() async {
    // Drop this account's pending offline ops so they don't leak into the next
    // session on the same device (the queue is device-level).
    await ref.read(syncControllerProvider.notifier).clear();
    await authService.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
