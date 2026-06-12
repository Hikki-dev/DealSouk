import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/features/profile/data/profile_service.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';

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
    int? submissionsToday,
    String? homeArea,
  }) {
    return UserProfile(
      name: name ?? this.name,
      location: location ?? this.location,
      avatarUrl: avatarUrl,
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

  void syncFromProfile(ProfileData data) {
    state = UserProfile(
      name: data.displayName,
      location: data.homeArea ?? 'Dubai',
      avatarUrl: '',
      submissionsToday: 0,
      homeArea: data.homeArea ?? 'Dubai',
    );
  }

  void incrementSubmissions() {
    final settings = ref.read(adminSettingsProvider);
    if (state.submissionsToday < settings.dailySubmissionCap) {
      state = state.copyWith(submissionsToday: state.submissionsToday + 1);
    }
  }

  void updateName(String name) => state = state.copyWith(name: name);
  void updateHomeArea(String area) => state = state.copyWith(homeArea: area);
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
