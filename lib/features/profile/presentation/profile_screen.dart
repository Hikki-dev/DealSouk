import 'package:dealsouk/core/util/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/widgets/avatar_image.dart';
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

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    Future.microtask(() {
      ref.read(userVouchersProvider.notifier).fetch();
      ref.read(myRequestsProvider.notifier).fetchMyRequests();
      // Reconcile economy + submissions from the server when the profile opens
      // (also covers tokens, streak, accuracy, approved/total, token history).
      ref.read(authProvider.notifier).refreshProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tokens = ref.watch(userTokensProvider);
    final profile = ref.watch(userProfileProvider);
    final stats = ref.watch(userStatsProvider);
    final mySubmissions = ref.watch(mySubmissionsProvider);
    final transactions = ref.watch(userTransactionsProvider);
    final settings = ref.watch(adminSettingsProvider);
    final vouchers = ref.watch(userVouchersProvider);
    final locale = ref.watch(localeProvider);
    final streak = ref.watch(streakProvider);

    final myRequests = ref.watch(myRequestsProvider);
    final level = tokensToLevel(tokens);
    // Authoritative server values (GET /profile/me), not derived from the
    // admin moderation queue. Fall back to 0 / 100% until the first sync lands.
    final approvedCount = stats?.approvedSubmissions ?? 0;
    final accuracyPct = stats?.accuracyRating.round() ?? 100;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () => ref.read(authProvider.notifier).refreshProfile(),
        color: AppTheme.forestDeep,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            // ── Hero: big tappable avatar + name + level/streak + tokens ──
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.forestDeep,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 24,
                20,
                26,
              ),
              child: Column(
                children: [
                  _buildHeroAvatar(profile),
                  const SizedBox(height: 14),
                  Text(
                    profile.name,
                    style: GoogleFonts.fredoka(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.limeAccent.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l.profileLevelBadge(level, levelTitle(level)),
                          style: const TextStyle(
                            color: AppTheme.limeAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 15,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        l.profileDayStreak(streak.currentStreak),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Quick stats ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
              child: Row(
                children: [
                  _statCard(
                    Icons.bolt,
                    '$tokens',
                    l.profileStatTokens,
                    AppTheme.forestDeep,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    Icons.verified_outlined,
                    '$accuracyPct%',
                    l.profileStatAccuracy,
                    Colors.green.shade600,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    Icons.receipt_long_outlined,
                    '$approvedCount',
                    l.profileStatApproved,
                    Colors.blue.shade600,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    Icons.local_fire_department,
                    '${streak.currentStreak}',
                    l.profileStatStreak,
                    Colors.orange.shade700,
                  ),
                ],
              ),
            ),

            // ── Plain labeled sections (no tabs) ──
            _profileSection(
              icon: Icons.receipt_long_outlined,
              title: l.profileSectionSubmissions,
              child: _buildSubmissionsTab(mySubmissions, accuracyPct),
            ),
            _profileSection(
              icon: Icons.bolt,
              title: l.profileSectionTokens,
              child: _buildTokenHistoryTab(transactions, tokens),
            ),
            _profileSection(
              icon: Icons.search_rounded,
              title: l.profileSectionRequests,
              child: _buildRequestsTab(myRequests),
            ),
            _profileSection(
              icon: Icons.settings_outlined,
              title: l.profileSectionSettings,
              initiallyExpanded: true,
              child: _buildSettingsTab(
                context,
                profile,
                settings,
                locale,
                tokens,
                vouchers,
              ),
            ),

            SizedBox(height: 110 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// Large circular avatar with a camera badge. Tapping anywhere on it (or the
  /// badge) opens the photo options sheet — the primary way to change the pic.
  Widget _buildHeroAvatar(dynamic profile) {
    final l = AppLocalizations.of(context)!;
    final photo = avatarImageProvider(profile.avatarUrl as String);
    final hasPhoto = photo != null;
    return Semantics(
      button: true,
      label: l.profileEditPhotoTooltip,
      child: GestureDetector(
        onTap: _showPhotoOptions,
        child: Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2.5,
                ),
                image: hasPhoto
                    ? DecorationImage(image: photo, fit: BoxFit.cover)
                    : null,
              ),
              child: hasPhoto
                  ? null
                  : const Center(
                      child: Icon(Icons.person, color: Colors.white, size: 46),
                    ),
            ),
            PositionedDirectional(
              end: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.limeAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.forestDeep, width: 2),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  color: AppTheme.forestDeep,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EEE4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  /// Collapsible labeled section card used instead of tabs.
  Widget _profileSection({
    required IconData icon,
    required String title,
    required Widget child,
    bool initiallyExpanded = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EEE4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Icon(icon, color: AppTheme.forestDeep, size: 20),
            title: Text(
              title,
              style: GoogleFonts.fredoka(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            children: [child],
          ),
        ),
      ),
    );
  }

  /// Action sheet: take a new photo, choose from library, or remove.
  void _showPhotoOptions() {
    final l = AppLocalizations.of(context)!;
    final hasPhoto = ref.read(userProfileProvider).avatarUrl.isNotEmpty;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_rounded,
                  color: AppTheme.forestDeep,
                ),
                title: Text(l.profilePhotoTakePhoto),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _changeProfilePhoto(fromCamera: true);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.forestDeep,
                ),
                title: Text(l.profilePhotoChooseLibrary),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _changeProfilePhoto(fromCamera: false);
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade700,
                  ),
                  title: Text(
                    l.profileRemovePhoto,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _removeProfilePhoto();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeProfilePhoto({bool fromCamera = false}) async {
    final l = AppLocalizations.of(context)!;
    final isGuest = ref.read(authProvider).isGuest;
    final oldUrl = ref.read(userProfileProvider).avatarUrl;
    final messenger = ScaffoldMessenger.of(context);

    // Demo/guest: keep the photo on-device (local path). Real accounts upload
    // to Firebase Storage and store the download URL.
    final newUrl = isGuest
        ? await storageService.pickLocalAvatarPath(fromCamera: fromCamera)
        : (fromCamera
              ? await storageService.captureAndUploadAvatar()
              : await storageService.pickAndUploadAvatar());
    if (!mounted || newUrl == null) return;
    await ref.read(userProfileProvider.notifier).updateAvatar(newUrl);
    // Only remote (http) avatars need server-side cleanup.
    if (!isGuest && oldUrl.startsWith('http')) {
      await storageService.deleteFileByUrl(oldUrl);
    }
    messenger.showSnackBar(SnackBar(content: Text(l.profilePhotoUpdated)));
  }

  Future<void> _removeProfilePhoto() async {
    final l = AppLocalizations.of(context)!;
    final isGuest = ref.read(authProvider).isGuest;
    final oldUrl = ref.read(userProfileProvider).avatarUrl;
    if (oldUrl.isEmpty) return;
    await ref.read(userProfileProvider.notifier).removeAvatar(oldUrl);
    if (!isGuest && oldUrl.startsWith('http')) {
      await storageService.deleteFileByUrl(oldUrl);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.profilePhotoRemoved)));
  }

  // ── TAB 1: Submissions ──
  Widget _buildSubmissionsTab(List<dynamic> mySubmissions, int accuracyPct) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  '${sub.storeName} • ${formatAed(sub.price)}',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        .read(userProfileProvider.notifier)
                        .updatePreferredLocale('en');
                  }),
                  const SizedBox(width: 8),
                  _langButton('عر', locale.languageCode == 'ar', () {
                    ref
                        .read(userProfileProvider.notifier)
                        .updatePreferredLocale('ar');
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
                  // Real accounts (Google/Apple/Phone) just say "Log Out";
                  // only the demo/guest session says "Log Out of Demo".
                  ref.read(authProvider).isGuest
                      ? l.profileLogOutDemo
                      : l.profileLogOut,
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
