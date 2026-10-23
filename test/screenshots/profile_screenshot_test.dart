import 'package:flutter/widgets.dart' show Locale, Size, Widget;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dealsouk/core/widgets/shell_layout.dart';
import 'package:dealsouk/core/widgets/tutorial_overlay.dart';
import 'package:dealsouk/features/admin/domain/admin_submission.dart';
import 'package:dealsouk/features/auth/presentation/auth_providers.dart';
import 'package:dealsouk/features/auth/presentation/unauthorized_screen.dart';
import 'package:dealsouk/features/legal/presentation/privacy_policy_screen.dart';
import 'package:dealsouk/features/profile/data/profile_service.dart';
import 'package:dealsouk/features/profile/presentation/profile_providers.dart';
import 'package:dealsouk/features/profile/presentation/profile_screen.dart';
import 'package:dealsouk/features/requests/domain/price_request.dart';
import 'package:dealsouk/features/requests/presentation/requests_providers.dart';
import 'package:dealsouk/features/tokens/domain/streak_data.dart';
import 'package:dealsouk/features/tokens/domain/token_transaction.dart';
import 'package:dealsouk/features/tokens/presentation/tokens_providers.dart';
import 'harness.dart';

class _Auth extends FakeAuth {
  _Auth() : super(const AuthState(status: AuthStatus.authenticated));
  @override
  Future<void> refreshProfile() async {}
}

class _Profile extends UserProfileNotifier {
  @override
  UserProfile build() => UserProfile(
    name: 'Sara',
    location: 'Dubai',
    avatarUrl: '',
    homeArea: 'Dubai Marina',
  );
}

class _Tokens extends UserTokensNotifier {
  @override
  int build() => 42;
}

class _Streak extends StreakNotifier {
  @override
  StreakData build() => const StreakData(
    currentStreak: 5,
    longestStreak: 9,
    lastActivityLabel: 'today',
  );
}

class _Stats extends UserStatsNotifier {
  @override
  ProfileData? build() => const ProfileData(
    id: 'u1',
    displayName: 'Sara',
    preferredLocale: 'en',
    tokenBalance: 42,
    accuracyRating: 92,
    isAdmin: false,
    totalSubmissions: 25,
    approvedSubmissions: 23,
  );
}

AdminSubmission _sub(
  String id,
  String name,
  String store,
  double p,
  String s,
) => AdminSubmission(
  id: id,
  productName: name,
  brand: '',
  storeName: store,
  price: p,
  hasReceipt: false,
  hasPhoto: true,
  promoType: 'none',
  tokensReward: 5,
  timestampLabel: 'today',
  sourcerId: 'u1',
  sourcerName: 'Sara',
  sourcerAccuracyRating: 92,
  status: s,
  productImageUrl: '',
);

class _Subs extends MySubmissionsNotifier {
  @override
  List<AdminSubmission> build() => [
    _sub('1', 'Al Rawabi Low Fat Milk', 'Lulu', 9.5, 'pending'),
    _sub('2', 'Farm Fresh Eggs, 15 pcs', 'Union Coop', 14.75, 'approved'),
    _sub('3', 'Rozana Basmati Rice 5kg', 'Carrefour', 31, 'rejected'),
  ];
  @override
  Future<void> fetch() async {}
}

class _Tx extends UserTransactionsNotifier {
  @override
  List<TokenTransaction> build() => [
    TokenTransaction(
      id: '1',
      amount: 5,
      title: 'Price approved: Farm Fresh Eggs',
      timestampLabel: 'today',
    ),
    TokenTransaction(
      id: '2',
      amount: -20,
      title: 'Price request: Basmati Rice',
      timestampLabel: 'today',
    ),
  ];
  @override
  Future<void> fetch() async {}
}

class _Vouchers extends UserVouchersNotifier {
  @override
  Future<void> fetch() async {}
}

class _Mine extends MyRequestsNotifier {
  @override
  List<PriceRequest> build() => [
    PriceRequest(
      id: 'r1',
      productName: 'Almarai Fresh Milk 2L',
      storeName: 'Carrefour',
      requestRewardTokens: 20,
      requesterName: 'Sara',
      status: 'open',
      timestampLabel: '2h ago',
    ),
  ];
  @override
  Future<void> fetchMyRequests() async {}
}

List<Override> _data() => [
  authProvider.overrideWith(_Auth.new),
  userProfileProvider.overrideWith(_Profile.new),
  userTokensProvider.overrideWith(_Tokens.new),
  streakProvider.overrideWith(_Streak.new),
  userStatsProvider.overrideWith(_Stats.new),
  mySubmissionsProvider.overrideWith(_Subs.new),
  userTransactionsProvider.overrideWith(_Tx.new),
  userVouchersProvider.overrideWith(_Vouchers.new),
  myRequestsProvider.overrideWith(_Mine.new),
];

Widget _framed(Size s, Widget w) =>
    s.width >= 600 ? ShellFrame(locationOverride: '/profile', child: w) : w;

Widget _withRouter(Widget w) => InheritedGoRouter(
  goRouter: GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => w)],
  ),
  child: w,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final c in [
    ('phone', Sizes.phone),
    ('tablet', Sizes.tablet),
    ('desktop', Sizes.desktop),
  ]) {
    testWidgets('profile ${c.$1}', (tester) async {
      await shoot(
        tester,
        _framed(c.$2, const ProfileScreen()),
        name: 'profile_${c.$1}',
        size: c.$2,
        overrides: _data(),
      );
    });
  }

  testWidgets('profile Arabic comfort text', (tester) async {
    await shoot(
      tester,
      const ProfileScreen(),
      name: 'profile_ar_comfort',
      locale: const Locale('ar'),
      textScale: 1.6,
      overrides: _data(),
    );
  });

  testWidgets('privacy phone', (tester) async {
    await shoot(
      tester,
      _withRouter(const PrivacyPolicyScreen()),
      name: 'privacy_phone',
    );
  });

  testWidgets('privacy desktop', (tester) async {
    await shoot(
      tester,
      _withRouter(const PrivacyPolicyScreen()),
      name: 'privacy_desktop',
      size: Sizes.desktop,
    );
  });

  testWidgets('unauthorized', (tester) async {
    await shoot(
      tester,
      const UnauthorizedScreen(),
      name: 'unauthorized_phone',
      overrides: [fakeAuth()],
    );
  });

  testWidgets('tutorial phone', (tester) async {
    await shoot(tester, const TutorialOverlay(), name: 'tutorial_phone');
  });

  testWidgets('tutorial Arabic comfort text', (tester) async {
    await shoot(
      tester,
      const TutorialOverlay(),
      name: 'tutorial_ar_comfort',
      locale: const Locale('ar'),
      textScale: 1.6,
    );
  });

  testWidgets('tutorial desktop', (tester) async {
    await shoot(
      tester,
      const TutorialOverlay(),
      name: 'tutorial_desktop',
      size: Sizes.desktop,
    );
  });
}
