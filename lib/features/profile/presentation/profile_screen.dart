import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dealsouk/features/admin/domain/admin_settings.dart';
import 'package:dealsouk/features/requests/presentation/requests_providers.dart';
import 'package:dealsouk/features/profile/data/profile_service.dart';
import 'package:dealsouk/features/profile/presentation/profile_providers.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/features/tokens/presentation/tokens_providers.dart';
import 'package:dealsouk/core/localization/locale_provider.dart';
import 'package:dealsouk/features/auth/presentation/auth_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/network/storage_service.dart';
import 'package:dealsouk/core/widgets/tutorial_overlay.dart';
import 'package:dealsouk/core/widgets/souk_widgets.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;

  static const List<String> _dubaiAreas = [
    'Dubai Marina',
    'Downtown Dubai',
    'JLT',
    'Deira',
    'Business Bay',
    'Al Barsha',
    'Jumeirah',
    'Mirdif',
    'Al Quoz',
    'Silicon Oasis',
    'International City',
    'Dubai Silicon Oasis',
    'Al Nahda',
    'Oud Metha',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    Future.microtask(() {
      ref.read(userVouchersProvider.notifier).fetch();
      ref.read(myRequestsProvider.notifier).fetchMyRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tokens = ref.watch(userTokensProvider);
    final profile = ref.watch(userProfileProvider);
    final submissions = ref.watch(adminSubmissionsProvider);
    final transactions = ref.watch(userTransactionsProvider);
    final settings = ref.watch(adminSettingsProvider);
    final vouchers = ref.watch(userVouchersProvider);
    final locale = ref.watch(localeProvider);
    final streak = ref.watch(streakProvider);

    final mySubmissions = submissions
        .where((s) => s.sourcerName == profile.name)
        .toList();
    final myRequests = ref.watch(myRequestsProvider);
    final level = tokensToLevel(tokens);
    final approvedCount = mySubmissions
        .where((s) => s.status == 'approved')
        .length;
    final accuracyPct = mySubmissions.isEmpty
        ? 0
        : ((approvedCount / mySubmissions.length) * 100).round();

    return Scaffold(
      backgroundColor: AppTheme.forestDeep,
      body: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 14,
              16,
              0,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        image: profile.avatarUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(profile.avatarUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profile.avatarUrl.isEmpty
                          ? const Center(
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 28,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: GoogleFonts.fredoka(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.limeAccent.withValues(
                                    alpha: 0.25,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l.profileLevelBadge(level, levelTitle(level)),
                                  style: const TextStyle(
                                    color: AppTheme.limeAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.local_fire_department,
                                color: Colors.orange,
                                size: 13,
                              ),
                              Text(
                                l.profileDayStreak(streak.currentStreak),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$tokens',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.bolt,
                      color: AppTheme.limeAccent,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.limeAccent,
                  labelColor: AppTheme.limeAccent,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: [
                    Tab(text: l.profileTabSubmissions),
                    Tab(text: l.profileTabTokens),
                    Tab(text: l.profileTabRequests),
                    Tab(text: l.profileTabSettings),
                  ],
                ),
              ],
            ),
          ),

          // Body tabs
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1 — Submissions
                  _buildSubmissionsTab(mySubmissions, accuracyPct),

                  // TAB 2 — Token History
                  _buildTokenHistoryTab(transactions, tokens),

                  // TAB 3 — Requests
                  _buildRequestsTab(myRequests),

                  // TAB 4 — Settings
                  _buildSettingsTab(
                    context,
                    profile,
                    settings,
                    locale,
                    tokens,
                    vouchers,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeProfilePhoto() async {
    final l = AppLocalizations.of(context)!;
    final oldUrl = ref.read(userProfileProvider).avatarUrl;
    final messenger = ScaffoldMessenger.of(context);
    final newUrl = await storageService.pickAndUploadAvatar();
    if (!mounted || newUrl == null) return;
    await ref.read(userProfileProvider.notifier).updateAvatar(newUrl);
    if (oldUrl.isNotEmpty) {
      await storageService.deleteFileByUrl(oldUrl);
    }
    messenger.showSnackBar(SnackBar(content: Text(l.profilePhotoUpdated)));
  }

  Future<void> _removeProfilePhoto() async {
    final l = AppLocalizations.of(context)!;
    final oldUrl = ref.read(userProfileProvider).avatarUrl;
    if (oldUrl.isEmpty) return;
    await ref.read(userProfileProvider.notifier).removeAvatar(oldUrl);
    await storageService.deleteFileByUrl(oldUrl);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.profilePhotoRemoved)));
  }

  // ── TAB 1: Submissions ──
  Widget _buildSubmissionsTab(List<dynamic> mySubmissions, int accuracyPct) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 160),
      children: [
        // Accuracy chip
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EEE4)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppTheme.limeAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  color: AppTheme.forestDeep,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.profileAccuracyRating,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      l.profileAccuracyApproved(accuracyPct),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$accuracyPct%',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.forestDeep,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (mySubmissions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                l.profileNoSubmissions,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ),
          )
        else
          ...mySubmissions.map((sub) => _submissionCard(sub)),
      ],
    );
  }

  Widget _submissionCard(dynamic sub) {
    final statusColor = sub.status == 'approved'
        ? Colors.green
        : sub.status == 'rejected'
        ? Colors.red
        : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEE4)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: statusColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${sub.storeName} • AED ${sub.price.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  sub.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '+${sub.tokensReward}T',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.forestDeep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── TAB 2: Token History ──
  Widget _buildTokenHistoryTab(List<dynamic> transactions, int tokens) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 160),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EEE4)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppTheme.forestDeep,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.profileCurrentBalance,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    l.profileTapLeaderboardRedeem,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '$tokens',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.forestDeep,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'T',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.forestDeep,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Text(
                l.profileNoTokenActivity,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ...transactions.map((tx) {
          final isPos = tx.amount > 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EEE4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (isPos ? Colors.green : Colors.red).withValues(
                      alpha: 0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPos ? Icons.add_rounded : Icons.remove_rounded,
                    color: isPos ? Colors.green : Colors.red,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tx.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isPos ? '+${tx.amount}' : '${tx.amount}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isPos ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRequestsTab(List<dynamic> myRequests) {
    final l = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(myRequestsProvider.notifier).fetchMyRequests();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 160),
        children: [
          if (myRequests.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  l.profileNoPriceRequests,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ),
            )
          else
            ...myRequests.map((req) {
              final statusColor = req.status == 'fulfilled'
                  ? Colors.green
                  : req.status == 'refunded'
                  ? Colors.blue
                  : Colors.orange;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8EEE4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        color: statusColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${req.storeName} • ${req.timestampLabel}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (req.status == 'open') ...[
                          IconButton(
                            tooltip: l.profileCancelRequest,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.cancel_outlined,
                              color: AppTheme.redAccent,
                              size: 20,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: Text(l.profileCancelRequestTitle),
                                  content: Text(
                                    l.profileCancelRequestBody(req.productName),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(l.profileNo),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        ref
                                            .read(myRequestsProvider.notifier)
                                            .cancelRequest(req.id);
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        l.profileYesCancel,
                                        style: const TextStyle(
                                          color: AppTheme.redAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            req.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── TAB 4: Settings ──
  Widget _buildSettingsTab(
    BuildContext context,
    dynamic profile,
    AdminSettings settings,
    Locale locale,
    int tokens,
    List<UserVoucher> vouchers,
  ) {
    final l = AppLocalizations.of(context)!;
    final remaining = settings.voucherThreshold - tokens;
    final auth = ref.watch(authProvider);
    UserVoucher? findVoucher(String status) {
      for (final voucher in vouchers) {
        if (voucher.status == status) return voucher;
      }
      return null;
    }

    final approvedVoucher = findVoucher('approved');
    final pendingVoucher = findVoucher('pending');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 160),
      children: [
        // Voucher section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens >= settings.voucherThreshold
                ? const Color(0xFFE8F5E9)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: tokens >= settings.voucherThreshold
                  ? AppTheme.forestDeep
                  : const Color(0xFFE8EEE4),
            ),
          ),
          child: approvedVoucher != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.confirmation_num_rounded,
                          color: AppTheme.forestDeep,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.profileVoucherApproved,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppTheme.forestDeep,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AED ${approvedVoucher.denominationAed} ${approvedVoucher.supermarket}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      approvedVoucher.voucherCode ?? l.profileCodePending,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppTheme.forestDeep,
                      ),
                    ),
                  ],
                )
              : pendingVoucher != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.profileVoucherUnderReview,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppTheme.forestDeep,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.profileVoucherPendingBody(
                        pendingVoucher.denominationAed,
                        pendingVoucher.supermarket,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textDark,
                        height: 1.4,
                      ),
                    ),
                  ],
                )
              : tokens >= settings.voucherThreshold
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.confirmation_num_rounded,
                          color: AppTheme.forestDeep,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.profileVoucherReady,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppTheme.forestDeep,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.profileVoucherReadyBody,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textDark,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.go('/leaderboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.forestDeep,
                        minimumSize: const Size.fromHeight(42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l.profileClaimVoucherNow),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.profileVoucherGoalTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '$tokens / ${settings.voucherThreshold} T',
                          style: const TextStyle(
                            color: AppTheme.forestDeep,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: (tokens / settings.voucherThreshold).clamp(
                          0.0,
                          1.0,
                        ),
                        backgroundColor: Colors.grey.shade100,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.forestDeep,
                        ),
                        minHeight: 7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.profileEarnMoreTokens(remaining > 0 ? remaining : 0),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),

        // Profile photo
        _settingsTile(
          icon: Icons.account_circle_outlined,
          title: l.profilePhotoTitle,
          subtitle: profile.avatarUrl.isEmpty
              ? l.profilePhotoSubtitleEmpty
              : l.profilePhotoSubtitleSet,
          trailing: Wrap(
            spacing: 4,
            children: [
              IconButton(
                tooltip: l.profileChangePhoto,
                icon: const Icon(
                  Icons.photo_camera_outlined,
                  size: 19,
                  color: AppTheme.forestDeep,
                ),
                onPressed: _changeProfilePhoto,
              ),
              if (profile.avatarUrl.isNotEmpty)
                IconButton(
                  tooltip: l.profileRemovePhoto,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                    color: Colors.red.shade700,
                  ),
                  onPressed: _removeProfilePhoto,
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Display name
        _settingsTile(
          icon: Icons.person_outline_rounded,
          title: l.profileDisplayName,
          subtitle: profile.name,
          trailing: IconButton(
            tooltip: l.profileEditDisplayName,
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppTheme.forestDeep,
            ),
            onPressed: () {
              _nameController.text = profile.name;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l.profileDisplayName),
                  content: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: l.profileNameLabel),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l.profileCancel),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(userProfileProvider.notifier)
                            .updateName(_nameController.text.trim());
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                      child: Text(l.profileSave),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Home area
        _settingsTile(
          icon: Icons.home_outlined,
          title: l.profileHomeArea,
          subtitle: profile.homeArea,
          trailing: DropdownButton<String>(
            value: _dubaiAreas.contains(profile.homeArea)
                ? profile.homeArea
                : _dubaiAreas.first,
            underline: const SizedBox(),
            icon: const Icon(
              Icons.expand_more,
              size: 18,
              color: AppTheme.forestDeep,
            ),
            items: _dubaiAreas
                .map(
                  (area) => DropdownMenuItem(
                    value: area,
                    child: Text(area, style: const TextStyle(fontSize: 12)),
                  ),
                )
                .toList(),
            onChanged: (val) async {
              if (val != null) {
                await ref
                    .read(userProfileProvider.notifier)
                    .updateHomeArea(val);
              }
            },
          ),
        ),
        const SizedBox(height: 10),

        // Language toggle
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EEE4)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.language_rounded,
                color: AppTheme.forestDeep,
                size: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.profileLanguage,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              Row(
                children: [
                  _langButton('EN', locale.languageCode == 'en', () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(const Locale('en'));
                  }),
                  const SizedBox(width: 8),
                  _langButton('عر', locale.languageCode == 'ar', () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(const Locale('ar'));
                  }),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Tutorial
        GestureDetector(
          onTap: () => TutorialOverlay.show(context),
          child: _settingsTile(
            icon: Icons.help_outline_rounded,
            title: l.profileViewTutorial,
            subtitle: l.profileViewTutorialSubtitle,
          ),
        ),
        const SizedBox(height: 10),

        GestureDetector(
          onTap: () => context.push('/privacy'),
          child: _settingsTile(
            icon: Icons.privacy_tip_outlined,
            title: l.profilePrivacyTerms,
            subtitle: l.profilePrivacyTermsSubtitle,
          ),
        ),
        const SizedBox(height: 10),

        if (auth.isAdmin) ...[
          // Admin console shortcut
          GestureDetector(
            onTap: () => context.push('/admin'),
            child: _settingsTile(
              icon: Icons.admin_panel_settings_outlined,
              title: l.profileAdminConsole,
              subtitle: l.profileAdminConsoleSubtitle,
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Log out
        GestureDetector(
          onTap: () async {
            await ref.read(authProvider.notifier).signOut();
            if (context.mounted) {
              context.go('/welcome');
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l.profileLogOut,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _langButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.forestDeep : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEE4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.forestDeep, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing
          else
            const DirectionalIcon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
              size: 20,
            ),
        ],
      ),
    );
  }
}
