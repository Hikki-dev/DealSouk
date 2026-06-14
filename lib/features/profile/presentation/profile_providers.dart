import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dealsouk/features/profile/data/profile_service.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/features/auth/presentation/auth_providers.dart';

class UserProfile {
  final String name;
  final String location;
  final String avatarUrl;
  final int submissionsToday;
  final String homeArea;

  UserProfile({
    required this.name,
    required this.location,
    required this.avatarUrl,
    this.submissionsToday = 0,
    this.homeArea = 'Dubai',
  });

  UserProfile copyWith({
    String? name,
    String? location,
    String? avatarUrl,
    int? submissionsToday,
    String? homeArea,
  }) {
    return UserProfile(
      name: name ?? this.name,
      location: location ?? this.location,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      submissionsToday: submissionsToday ?? this.submissionsToday,
      homeArea: homeArea ?? this.homeArea,
    );
  }
}

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() => UserProfile(
    name: 'Shopper',
    location: 'Dubai',
    avatarUrl: '',
    submissionsToday: 0,
    homeArea: 'Dubai',
  );

  static const _guestPrefsKey = 'guest_profile_v1';

  /// Syncs from the backend profile. [fallbackName]/[fallbackAvatarUrl] come
  /// from the Firebase account (e.g. the Google display name + photo) and are
  /// used when the backend has no value of its own — so a Google user sees
  /// their name and photo immediately without having to set anything.
  void syncFromProfile(
    ProfileData data, {
    String? fallbackName,
    String? fallbackAvatarUrl,
  }) {
    final name = data.displayName.isNotEmpty
        ? data.displayName
        : (fallbackName ?? 'Shopper');
    final avatar = (data.avatarUrl != null && data.avatarUrl!.isNotEmpty)
        ? data.avatarUrl!
        : (fallbackAvatarUrl ?? '');
    state = UserProfile(
      name: name,
      location: data.homeArea ?? 'Dubai',
      avatarUrl: avatar,
      submissionsToday: 0,
      homeArea: data.homeArea ?? 'Dubai',
    );
  }

  /// Seeds the name/avatar straight from the Firebase account (Google/Apple)
  /// when the backend profile isn't available — so the greeting + avatar show
  /// the real identity instead of the "Shopper" placeholder.
  void seedFromAccount({String? name, String? avatarUrl}) {
    state = state.copyWith(
      name: (name != null && name.isNotEmpty) ? name : state.name,
      avatarUrl: (avatarUrl != null && avatarUrl.isNotEmpty)
          ? avatarUrl
          : state.avatarUrl,
    );
  }

  bool get _isGuest => ref.read(authProvider).isGuest;

  /// Restores a guest/demo profile from on-device storage (or seeds defaults).
  /// Demo users never touch the backend — everything stays on the device.
  Future<void> loadGuestProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guestPrefsKey);
    if (raw == null) {
      state = UserProfile(
        name: 'Demo',
        location: 'Dubai',
        avatarUrl: '',
        submissionsToday: 0,
        homeArea: 'Dubai',
      );
      return;
    }
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      state = UserProfile(
        name: (m['name'] as String?) ?? 'Demo',
        location: (m['homeArea'] as String?) ?? 'Dubai',
        avatarUrl: (m['avatarUrl'] as String?) ?? '',
        submissionsToday: 0,
        homeArea: (m['homeArea'] as String?) ?? 'Dubai',
      );
    } catch (_) {
      state = UserProfile(
        name: 'Demo',
        location: 'Dubai',
        avatarUrl: '',
        homeArea: 'Dubai',
      );
    }
  }

  Future<void> _persistGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _guestPrefsKey,
      jsonEncode({
        'name': state.name,
        'avatarUrl': state.avatarUrl,
        'homeArea': state.homeArea,
      }),
    );
  }

  void incrementSubmissions() {
    final settings = ref.read(adminSettingsProvider);
    if (state.submissionsToday < settings.dailySubmissionCap) {
      state = state.copyWith(submissionsToday: state.submissionsToday + 1);
    }
  }

  Future<void> updateName(String name) async {
    final trimmed = name.trim();
    if (trimmed.length < 2) return;
    state = state.copyWith(name: trimmed);
    if (_isGuest) {
      await _persistGuest();
    } else {
      await profileService.updateProfile(displayName: trimmed);
    }
  }

  Future<void> updateAvatar(String avatarUrl) async {
    state = state.copyWith(avatarUrl: avatarUrl);
    if (_isGuest) {
      // Demo avatar is a local file path saved on-device — never uploaded.
      await _persistGuest();
    } else {
      await profileService.updateProfile(avatarUrl: avatarUrl);
    }
  }

  Future<void> removeAvatar(String oldAvatarUrl) async {
    state = state.copyWith(avatarUrl: '');
    if (_isGuest) {
      await _persistGuest();
    } else {
      await profileService.updateProfile(avatarUrl: '');
    }
  }

  Future<void> updateHomeArea(String area) async {
    state = state.copyWith(location: area, homeArea: area);
    if (_isGuest) {
      await _persistGuest();
    } else {
      await profileService.updateProfile(homeArea: area);
    }
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(
  UserProfileNotifier.new,
);

class NavbarVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void show() => state = true;
  void hide() => state = false;
}

final navbarVisibleProvider = NotifierProvider<NavbarVisibleNotifier, bool>(
  NavbarVisibleNotifier.new,
);

class UserVouchersNotifier extends Notifier<List<UserVoucher>> {
  @override
  List<UserVoucher> build() => [];

  Future<void> fetch() async {
    try {
      state = await profileService.getVouchers();
    } catch (_) {}
  }
}

final userVouchersProvider =
    NotifierProvider<UserVouchersNotifier, List<UserVoucher>>(
      UserVouchersNotifier.new,
    );
