import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/localization/locale_provider.dart';
import 'package:dealsouk/core/localization/text_scale_provider.dart';
import 'package:dealsouk/core/network/storage_service.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/util/format.dart';
import 'package:dealsouk/core/widgets/avatar_image.dart';
import 'package:dealsouk/core/widgets/souk_widgets.dart' show DirectionalIcon;
import 'package:dealsouk/core/widgets/tutorial_overlay.dart';
import 'package:dealsouk/features/admin/domain/admin_settings.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/features/auth/presentation/auth_providers.dart';
import 'package:dealsouk/features/profile/data/profile_service.dart';
import 'package:dealsouk/features/profile/presentation/profile_providers.dart';
import 'package:dealsouk/features/requests/presentation/requests_providers.dart';
import 'package:dealsouk/features/tokens/presentation/tokens_providers.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  int _tab = 0;

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

    final identity = _identityCard(
      profile,
      l.profileLevelBadge(level, levelTitle(level)),
    );
    final statRow = _statsGrid(
      l,
      tokens: tokens,
      accuracyPct: accuracyPct,
      approvedCount: approvedCount,
      streak: streak.currentStreak,
    );
    final voucher = _voucherCard(l, tokens, settings, vouchers);
    final tabLabels = [
      l.profileTabSubmissions,
      l.profileTabTokens,
      l.profileTabRequests,
      l.profileTabSettings,
    ];
    // At large text sizes four tabs no longer fit in one row, so they wrap.
    final tabs = MediaQuery.textScalerOf(context).scale(1.0) > 1.2
        ? Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < tabLabels.length; i++)
                DsChip(
                  label: tabLabels[i],
                  selected: _tab == i,
                  onTap: () => setState(() => _tab = i),
                ),
            ],
          )
        : DsSegmented(
            labels: tabLabels,
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          );
    final content = switch (_tab) {
      0 => _buildSubmissionsTab(mySubmissions, accuracyPct),
      1 => _buildTokenHistoryTab(transactions, tokens),
      2 => _buildRequestsTab(myRequests),
      _ => _buildSettingsTab(context, profile, locale),
    };

    final Widget body;
    if (context.isExpanded) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: 12),
                statRow,
                const SizedBox(height: 12),
                voucher,
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [tabs, const SizedBox(height: 16), content],
            ),
          ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          identity,
          const SizedBox(height: 12),
          statRow,
          const SizedBox(height: 12),
          voucher,
          const SizedBox(height: 16),
          tabs,
          const SizedBox(height: 16),
          content,
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(authProvider.notifier).refreshProfile(),
          color: AppTheme.forestDeep,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              PageContainer(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 16,
                    bottom: 24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          l.profile,
                          style: AppFonts.display(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      body,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identityCard(UserProfile profile, String levelLabel) {
    final l = AppLocalizations.of(context)!;
    final photo = avatarImageProvider(profile.avatarUrl);
    return DsCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Semantics(
            image: true,
            label: profile.name,
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.limeAccent,
                image: photo == null
                    ? null
                    : DecorationImage(image: photo, fit: BoxFit.cover),
              ),
              child: photo != null
                  ? null
                  : Text(
                      profile.name.trim().isEmpty
                          ? '?'
                          : profile.name.trim().characters.first.toUpperCase(),
                      style: AppFonts.display(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  profile.homeArea,
                  style: AppFonts.body(fontSize: 15, color: AppTheme.textLight),
                ),
                const SizedBox(height: 6),
                DsTag(levelLabel, tone: DsTone.teal),
              ],
            ),
          ),
          DsIconButton(
            icon: Icons.photo_camera_outlined,
            semanticLabel: l.profileEditPhotoTooltip,
            onPressed: _showPhotoOptions,
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(
    AppLocalizations l, {
    required int tokens,
    required int accuracyPct,
    required int approvedCount,
    required int streak,
  }) {
    final cells = [
      ('$tokens', l.profileStatTokens),
      ('$accuracyPct%', l.profileStatAccuracy),
      ('$approvedCount', l.profileStatApproved),
      ('$streak', l.profileStatStreak),
    ];
    Widget cell((String, String) c) => Expanded(
      child: DsCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                c.$1,
                style: AppFonts.display(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
            ),
            Text(
              c.$2,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.body(fontSize: 13, color: AppTheme.textLight),
            ),
          ],
        ),
      ),
    );
    // Two rows of two when text is large, so labels never get cut.
    final large = MediaQuery.textScalerOf(context).scale(1.0) > 1.25;
    if (large || context.isExpanded) {
      return Column(
        children: [
          Row(
            children: [
              cell(cells[0]),
              const SizedBox(width: 8),
              cell(cells[1]),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              cell(cells[2]),
              const SizedBox(width: 8),
              cell(cells[3]),
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          cell(cells[i]),
        ],
      ],
    );
  }

  Widget _voucherCard(
    AppLocalizations l,
    int tokens,
    AdminSettings settings,
    List<UserVoucher> vouchers,
  ) {
    UserVoucher? find(String status) {
      for (final v in vouchers) {
        if (v.status == status) return v;
      }
      return null;
    }

    final approved = find('approved');
    final pending = find('pending');
    final ready = tokens >= settings.voucherThreshold;
    final remaining = settings.voucherThreshold - tokens;
    final title = AppFonts.display(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: AppTheme.ink,
    );
    final small = AppFonts.body(fontSize: 15, height: 1.4, color: AppTheme.ink);

    final Widget inner;
    if (approved != null) {
      inner = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.confirmation_num_rounded,
                color: AppTheme.forestDeep,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(l.profileVoucherApproved, style: title)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'AED ${approved.denominationAed} ${approved.supermarket}',
            style: small.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          SelectableText(
            approved.voucherCode ?? l.profileCodePending,
            style: AppFonts.display(
              fontSize: 20,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: AppTheme.forestDeep,
            ),
          ),
        ],
      );
    } else if (pending != null) {
      inner = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.profileVoucherUnderReview, style: title),
          const SizedBox(height: 6),
          Text(
            l.profileVoucherPendingBody(
              pending.denominationAed,
              pending.supermarket,
            ),
            style: small,
          ),
        ],
      );
    } else if (ready) {
      inner = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.profileVoucherReady, style: title),
          const SizedBox(height: 6),
          Text(l.profileVoucherReadyBody, style: small),
          const SizedBox(height: 12),
          DsButton(
            label: l.profileClaimVoucherNow,
            style: DsButtonStyle.accent,
            onPressed: () => context.go('/leaderboard'),
          ),
        ],
      );
    } else {
      inner = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(l.profileVoucherGoalTitle, style: title)),
              Text(
                '$tokens / ${settings.voucherThreshold}',
                style: small.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DsProgressBar(
            value: settings.voucherThreshold == 0
                ? 0
                : tokens / settings.voucherThreshold,
          ),
          const SizedBox(height: 8),
          Text(
            l.profileEarnMoreTokens(remaining > 0 ? remaining : 0),
            style: small,
          ),
        ],
      );
    }
    return DsCard(
      color: AppTheme.warnLight,
      borderless: true,
      padding: const EdgeInsets.all(16),
      child: inner,
    );
  }

  /// Action sheet: take a new photo, choose from library, or remove.
  void _showPhotoOptions() {
    final l = AppLocalizations.of(context)!;
    final hasPhoto = ref.read(userProfileProvider).avatarUrl.isNotEmpty;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 520),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        Widget item(
          IconData icon,
          String label,
          VoidCallback onTap, {
          Color? color,
        }) => ListTile(
          minTileHeight: 56,
          leading: Icon(icon, color: color ?? AppTheme.forestDeep),
          title: Text(
            label,
            style: AppFonts.body(fontSize: 17, color: color ?? AppTheme.ink),
          ),
          onTap: () {
            Navigator.pop(sheetContext);
            onTap();
          },
        );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              item(
                Icons.photo_camera_rounded,
                l.profilePhotoTakePhoto,
                () => _changeProfilePhoto(fromCamera: true),
              ),
              item(
                Icons.photo_library_rounded,
                l.profilePhotoChooseLibrary,
                () => _changeProfilePhoto(fromCamera: false),
              ),
              if (hasPhoto)
                item(
                  Icons.delete_outline_rounded,
                  l.profileRemovePhoto,
                  _removeProfilePhoto,
                  color: AppTheme.badText,
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

  // ── Submissions ──
  Widget _emptyNote(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppFonts.body(
          fontSize: 16,
          height: 1.45,
          color: AppTheme.textLight,
        ),
      ),
    ),
  );

  DsTone _toneFor(String status) => switch (status) {
    'approved' || 'fulfilled' => DsTone.good,
    'rejected' => DsTone.bad,
    'refunded' => DsTone.teal,
    _ => DsTone.warn,
  };

  Widget _buildSubmissionsTab(List<dynamic> mySubmissions, int accuracyPct) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppTheme.goodLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  color: AppTheme.goodText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.profileAccuracyRating,
                      style: AppFonts.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                    Text(
                      l.profileAccuracyApproved(accuracyPct),
                      style: AppFonts.body(
                        fontSize: 14,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$accuracyPct%',
                style: AppFonts.display(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.forestDeep,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (mySubmissions.isEmpty)
          _emptyNote(l.profileNoSubmissions)
        else
          for (final sub in mySubmissions) ...[
            _historyRow(
              icon: Icons.receipt_long_outlined,
              title: sub.productName as String,
              subtitle: '${sub.storeName} • ${formatAed(sub.price)}',
              status: (sub.status as String),
              trailingNote: '+${sub.tokensReward} T',
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _historyRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    String? trailingNote,
    Widget? action,
  }) {
    final tone = _toneFor(status);
    return DsCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppTheme.sand2,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.forestDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(fontSize: 14, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DsTag(
                status.isEmpty
                    ? status
                    : status[0].toUpperCase() + status.substring(1),
                tone: tone,
              ),
              if (trailingNote != null) ...[
                const SizedBox(height: 4),
                Text(
                  trailingNote,
                  style: AppFonts.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.forestDeep,
                  ),
                ),
              ],
              ?action,
            ],
          ),
        ],
      ),
    );
  }

  // ── Token history ──
  Widget _buildTokenHistoryTab(List<dynamic> transactions, int tokens) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppTheme.forestDeep,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.profileCurrentBalance,
                      style: AppFonts.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                    Text(
                      l.profileTapLeaderboardRedeem,
                      style: AppFonts.body(
                        fontSize: 14,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$tokens T',
                style: AppFonts.display(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.forestDeep,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty) _emptyNote(l.profileNoTokenActivity),
        for (final tx in transactions) ...[
          DsCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  tx.amount > 0
                      ? Icons.add_circle_outline_rounded
                      : Icons.remove_circle_outline_rounded,
                  color: tx.amount > 0 ? AppTheme.good : AppTheme.badText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tx.title as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.body(fontSize: 15, color: AppTheme.ink),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  tx.amount > 0 ? '+${tx.amount}' : '${tx.amount}',
                  style: AppFonts.display(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: tx.amount > 0 ? AppTheme.good : AppTheme.badText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  // ── Requests ──
  Widget _buildRequestsTab(List<dynamic> myRequests) {
    final l = AppLocalizations.of(context)!;
    if (myRequests.isEmpty) return _emptyNote(l.profileNoPriceRequests);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final req in myRequests) ...[
          _historyRow(
            icon: Icons.search_rounded,
            title: req.productName as String,
            subtitle: '${req.storeName} • ${req.timestampLabel}',
            status: req.status as String,
            action: req.status == 'open'
                ? DsIconButton(
                    icon: Icons.cancel_outlined,
                    color: AppTheme.badText,
                    semanticLabel: l.profileCancelRequest,
                    onPressed: () => _confirmCancel(req),
                  )
                : null,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  void _confirmCancel(dynamic req) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.profileCancelRequestTitle),
        content: Text(
          l.profileCancelRequestBody(req.productName),
          style: AppFonts.body(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.profileNo),
          ),
          TextButton(
            onPressed: () {
              ref.read(myRequestsProvider.notifier).cancelRequest(req.id);
              Navigator.pop(context);
            },
            child: Text(
              l.profileYesCancel,
              style: const TextStyle(color: AppTheme.badText),
            ),
          ),
        ],
      ),
    );
  }

  // ── Settings ──
  Widget _row(
    String label, {
    String? value,
    Widget? trailing,
    VoidCallback? onTap,
    String? subtitle,
    Widget? below,
  }) {
    final Widget end =
        trailing ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null)
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            if (onTap != null)
              const DirectionalIcon(Icons.chevron_right_rounded, size: 24),
          ],
        );
    final row = InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppFonts.body(fontSize: 16, color: AppTheme.ink),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: AppFonts.body(
                          fontSize: 13,
                          color: AppTheme.textLight,
                        ),
                      ),
                  ],
                ),
              ),
              if (below == null) ...[
                const SizedBox(width: 8),
                Flexible(
                  flex: 3,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: end,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (below == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
          child: below,
        ),
      ],
    );
  }

  Widget _group(List<Widget> rows) => DsCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppTheme.line),
          rows[i],
        ],
      ],
    ),
  );

  Widget _buildSettingsTab(
    BuildContext context,
    UserProfile profile,
    Locale locale,
  ) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final textSize = ref.watch(textSizeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _group([
          _row(
            l.profilePhotoTitle,
            value: profile.avatarUrl.isEmpty
                ? l.profilePhotoSubtitleEmpty
                : l.profilePhotoSubtitleSet,
            onTap: _showPhotoOptions,
          ),
          _row(
            l.profileDisplayName,
            value: profile.name,
            onTap: () => _editName(profile.name),
          ),
          _row(
            l.profileHomeArea,
            trailing: DropdownButton<String>(
              value: _dubaiAreas.contains(profile.homeArea)
                  ? profile.homeArea
                  : _dubaiAreas.first,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.expand_more, color: AppTheme.forestDeep),
              items: [
                for (final area in _dubaiAreas)
                  DropdownMenuItem(
                    value: area,
                    child: Text(
                      area,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
              ],
              onChanged: (val) async {
                if (val != null) {
                  await ref
                      .read(userProfileProvider.notifier)
                      .updateHomeArea(val);
                }
              },
            ),
          ),
          _row(
            l.profileLanguage,
            below: DsSegmented(
              labels: const ['English', 'العربية'],
              selected: locale.languageCode == 'ar' ? 1 : 0,
              onChanged: (i) => ref
                  .read(userProfileProvider.notifier)
                  .updatePreferredLocale(i == 1 ? 'ar' : 'en'),
            ),
          ),
          _row(
            l.profileTextSize,
            subtitle: l.profileTextSizeSubtitle,
            below: DsSegmented(
              labels: [
                l.textSizeStandard,
                l.textSizeLarge,
                l.textSizeExtraLarge,
              ],
              selected: textSize.index,
              onChanged: (i) => ref
                  .read(textSizeProvider.notifier)
                  .set(TextSizeChoice.values[i]),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        _group([
          _row(
            l.profileViewTutorial,
            subtitle: l.profileViewTutorialSubtitle,
            onTap: () => TutorialOverlay.show(context),
          ),
          _row(
            l.profilePrivacyTerms,
            subtitle: l.profilePrivacyTermsSubtitle,
            onTap: () => context.push('/privacy'),
          ),
          if (auth.isAdmin)
            _row(
              l.profileAdminConsole,
              subtitle: l.profileAdminConsoleSubtitle,
              onTap: () => context.push('/admin'),
            ),
        ]),
        const SizedBox(height: 16),
        DsButton(
          label: auth.isGuest ? l.profileLogOutDemo : l.profileLogOut,
          style: DsButtonStyle.secondary,
          icon: Icons.logout_rounded,
          onPressed: () async {
            await ref.read(authProvider.notifier).signOut();
            if (context.mounted) context.go('/welcome');
          },
        ),
      ],
    );
  }

  void _editName(String current) {
    final l = AppLocalizations.of(context)!;
    _nameController.text = current;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.profileDisplayName),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: InputDecoration(labelText: l.profileNameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.profileCancel),
          ),
          FilledButton(
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
  }
}
