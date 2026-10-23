import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dealsouk/features/admin/presentation/widgets/admin_panel_widgets.dart';
import 'package:dealsouk/features/admin/presentation/panels/analytics_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/features/auth/presentation/auth_providers.dart';
import 'package:dealsouk/features/admin/data/admin_service.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/l10n/app_localizations.dart';
import 'package:dealsouk/features/admin/domain/admin_submission.dart';
import 'package:dealsouk/features/admin/domain/voucher_request.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:dealsouk/core/util/map_tiles.dart';
import 'package:latlong2/latlong.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/profile/data/profile_service.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({
    super.key,
    this.initialTab = 'moderation',
    this.readOnly = false,
  });

  /// Demo viewers: show the banner and refuse writes.
  final bool readOnly;

  /// Tab shown first: moderation, map, analytics, vouchers, stock, settings,
  /// products_crud or users_crud.
  final String initialTab;

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  String? _selectedSubId;
  late String _activeTab = widget.initialTab;
  int _filter = 0; // 0 pending, 1 flagged
  String _mapSearchQuery = '';
  String _mapSelectedChain = 'All';
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminSubmissionsProvider.notifier).fetchQueue();
      ref.read(adminSettingsProvider.notifier).fetchSettings();
      ref.read(adminVouchersProvider.notifier).fetchVouchers();
      ref.read(adminAnalyticsProvider.notifier).fetchAnalytics();
      ref.read(adminVoucherInventoryProvider.notifier).fetchInventoryStatus();
      ref.read(adminMapDataProvider.notifier).fetchMapData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingSubs = ref.watch(adminSubmissionsProvider);
    final vouchers = ref.watch(adminVouchersProvider);
    final int pendingCount = pendingSubs.length;
    final int voucherCount = vouchers.length;

    // Reactively adjust other dashboard stats
    final int approvedCount = 48 + (3 - pendingCount);
    final int tokensIssuedCount = 18450 + ((3 - pendingCount) * 15);

    // Initialize or correct the selected submission
    if (pendingSubs.isNotEmpty) {
      if (_selectedSubId == null ||
          !pendingSubs.any((s) => s.id == _selectedSubId)) {
        _selectedSubId = pendingSubs.first.id;
      }
    } else {
      _selectedSubId = null;
    }

    final currentSub = _selectedSubId != null
        ? pendingSubs.firstWhere(
            (s) => s.id == _selectedSubId,
            orElse: () => pendingSubs.first,
          )
        : null;

    final pending = pendingSubs.length;
    final isDemo = widget.readOnly;
    adminService.readOnly = isDemo;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1024;
        final nav = _navItems(
          AppLocalizations.of(context)!,
          pending,
          voucherCount,
        );
        final content = _buildContent(
          context,
          wide: wide,
          pendingSubs: pendingSubs,
          currentSub: currentSub,
          pendingCount: pendingCount,
          approvedCount: approvedCount,
          tokensIssuedCount: tokensIssuedCount,
          vouchers: vouchers,
        );
        final body = Column(
          children: [
            if (isDemo) const _DemoBanner(),
            Expanded(child: content),
          ],
        );
        if (wide) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 264, child: _buildSidebar(context, nav)),
                Expanded(
                  child: Column(
                    children: [
                      _buildHeader(context, wide: true),
                      Expanded(child: body),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          backgroundColor: AppTheme.background,
          drawer: Drawer(
            backgroundColor: AppTheme.forestDeep,
            child: _buildSidebar(context, nav, inDrawer: true),
          ),
          body: Column(
            children: [
              _buildHeader(context, wide: false),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }

  // --- NAVIGATION MODEL ---
  List<_AdminNavItem> _navItems(
    AppLocalizations l,
    int pending,
    int vouchers,
  ) => [
    _AdminNavItem(
      'moderation',
      Icons.gavel_rounded,
      l.navModeration,
      badge: pending,
    ),
    _AdminNavItem('map', Icons.map_rounded, l.navMap),
    _AdminNavItem('analytics', Icons.bar_chart_rounded, l.navAnalytics),
    _AdminNavItem(
      'vouchers',
      Icons.confirmation_num_rounded,
      l.navVouchers,
      badge: vouchers,
    ),
    _AdminNavItem('stock', Icons.inventory_2_rounded, l.navStock),
    _AdminNavItem('settings', Icons.settings_rounded, l.navSettings),
    _AdminNavItem('products_crud', Icons.shopping_bag_rounded, l.navProducts),
    _AdminNavItem('users_crud', Icons.people_rounded, l.navUsers),
  ];

  void _selectTab(String tab) {
    setState(() => _activeTab = tab);
    if (tab == 'products_crud') {
      ref.read(adminProductsProvider.notifier).fetch();
    } else if (tab == 'users_crud') {
      ref.read(adminUsersProvider.notifier).fetch();
    }
  }

  void _refresh() {
    switch (_activeTab) {
      case 'vouchers':
        ref.read(adminVouchersProvider.notifier).fetchVouchers();
      case 'analytics':
        ref.read(adminAnalyticsProvider.notifier).fetchAnalytics();
      case 'moderation':
        ref.read(adminSubmissionsProvider.notifier).fetchQueue();
      case 'map':
        ref.read(adminMapDataProvider.notifier).fetchMapData();
      case 'stock':
        ref.read(adminVoucherInventoryProvider.notifier).fetchInventoryStatus();
      case 'products_crud':
        ref.read(adminProductsProvider.notifier).fetch();
      case 'users_crud':
        ref.read(adminUsersProvider.notifier).fetch();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.modSyncing)),
    );
  }

  // --- SIDEBAR (desktop) / DRAWER (phone, tablet) ---
  Widget _buildSidebar(
    BuildContext context,
    List<_AdminNavItem> nav, {
    bool inDrawer = false,
  }) {
    final hasRouter = GoRouter.maybeOf(context) != null;
    return Container(
      color: AppTheme.forestDeep,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const DsBrandMark(size: 44, onDark: true),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.modTitle,
                      style: AppFonts.display(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    for (final item in nav)
                      _sidebarItem(
                        item,
                        onTap: () {
                          if (inDrawer) Navigator.of(context).pop();
                          _selectTab(item.tab);
                        },
                      ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 8),
              if (hasRouter)
                _footerAction(
                  Icons.arrow_back_rounded,
                  AppLocalizations.of(context)!.modBackToApp,
                  () => context.go('/profile'),
                ),
              _footerAction(
                Icons.logout_rounded,
                AppLocalizations.of(context)!.modLogOut,
                () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted && GoRouter.maybeOf(context) != null) {
                    context.go('/welcome');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sidebarItem(_AdminNavItem item, {required VoidCallback onTap}) {
    final active = _activeTab == item.tab;
    final fg = active ? AppTheme.forestDeep : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Semantics(
        button: true,
        selected: active,
        label: item.label,
        excludeSemantics: true,
        child: Material(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(item.icon, color: fg, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: AppFonts.body(
                          color: fg,
                          fontSize: 16,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (item.badge > 0) DsCountBadge(item.badge),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footerAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppFonts.body(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool wide}) {
    final title = _navItems(
      AppLocalizations.of(context)!,
      0,
      0,
    ).firstWhere((n) => n.tab == _activeTab).label;
    if (!wide) {
      return Container(
        color: AppTheme.background,
        padding: EdgeInsets.fromLTRB(
          4,
          MediaQuery.paddingOf(context).top + 4,
          4,
          4,
        ),
        child: Row(
          children: [
            Builder(
              builder: (ctx) => IconButton(
                iconSize: 26,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                tooltip: AppLocalizations.of(context)!.modMenu,
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.display(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ),
            if (_activeTab == 'moderation')
              IconButton(
                iconSize: 26,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                tooltip: AppLocalizations.of(context)!.modExportCsv,
                icon: const Icon(Icons.download_rounded),
                onPressed: () => _exportCsv(ref.read(adminSubmissionsProvider)),
              ),
            IconButton(
              iconSize: 26,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              tooltip: AppLocalizations.of(context)!.modRefresh,
              icon: const Icon(Icons.sync_rounded),
              onPressed: _refresh,
            ),
          ],
        ),
      );
    }
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: AppFonts.display(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
            ),
          ),
          DsTag(
            AppLocalizations.of(context)!.modRoleTag,
            icon: Icons.verified_user_rounded,
          ),
          const SizedBox(width: 12),
          DsButton(
            label: AppLocalizations.of(context)!.modRefresh,
            style: DsButtonStyle.secondary,
            icon: Icons.sync_rounded,
            expanded: false,
            compact: true,
            onPressed: _refresh,
          ),
          if (_activeTab == 'moderation') ...[
            const SizedBox(width: 8),
            DsButton(
              label: AppLocalizations.of(context)!.modExportCsv,
              icon: Icons.download_rounded,
              expanded: false,
              compact: true,
              onPressed: () => _exportCsv(ref.read(adminSubmissionsProvider)),
            ),
          ],
        ],
      ),
    );
  }

  // --- CONTENT ---
  Widget _buildContent(
    BuildContext context, {
    required bool wide,
    required List<AdminSubmission> pendingSubs,
    required AdminSubmission? currentSub,
    required int pendingCount,
    required int approvedCount,
    required int tokensIssuedCount,
    required List<VoucherRequest> vouchers,
  }) {
    switch (_activeTab) {
      case 'moderation':
        return wide
            ? _buildModerationWide(
                context,
                pendingSubs,
                currentSub,
                pendingCount,
                approvedCount,
                tokensIssuedCount,
              )
            : _buildModerationNarrow(
                context,
                pendingSubs,
                pendingCount,
                approvedCount,
                tokensIssuedCount,
              );
      case 'map':
        return _buildMapDensityPanel();
      case 'analytics':
        return const AnalyticsPanel();
      case 'vouchers':
        return _buildVoucherQueuePanel(vouchers);
      case 'stock':
        return _buildVoucherStockPanel();
      case 'products_crud':
        return _buildProductsCrudPanel();
      case 'users_crud':
        return _buildUsersCrudPanel();
      default:
        return _buildMockPanelContent();
    }
  }

  Widget _statsRow(int pending, int approved, int tokens) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.7);
    return AdaptiveGrid(
      minTileWidth: 150,
      spacing: 12,
      maxColumns: 3,
      mainAxisExtent: 112 * scale,
      children: [
        adminStatCard(
          AppLocalizations.of(context)!.modPendingReviews,
          '$pending',
          Icons.hourglass_empty_rounded,
          AppTheme.warnText,
        ),
        adminStatCard(
          AppLocalizations.of(context)!.modApprovedToday,
          '$approved',
          Icons.check_circle_outline_rounded,
          AppTheme.good,
        ),
        adminStatCard(
          AppLocalizations.of(context)!.modTokensIssued,
          '$tokens',
          Icons.bolt_rounded,
          AppTheme.limeAccent,
        ),
      ],
    );
  }

  List<AdminSubmission> _visibleSubs(List<AdminSubmission> all) => all
      .where((s) => (s.promoType == 'Flagged Report') == (_filter == 1))
      .toList();

  Widget _buildFilterTabs(AppLocalizations l, List<AdminSubmission> all) {
    final flagged = all.where((s) => s.promoType == 'Flagged Report').length;
    return DsSegmented(
      labels: [l.modTabPending(all.length - flagged), l.modTabFlagged(flagged)],
      selected: _filter,
      onChanged: (i) => setState(() => _filter = i),
    );
  }

  Future<void> _exportCsv(List<AdminSubmission> subs) async {
    final l = AppLocalizations.of(context)!;
    String cell(String v) => '"${v.replaceAll('"', '""')}"';
    final rows = [
      'id,product,brand,store,price_aed,type,reward_tokens,submitter',
      for (final s in subs)
        [
          cell(s.id),
          cell(s.productName),
          cell(s.brand),
          cell(s.storeName),
          s.price.toStringAsFixed(2),
          cell(s.promoType),
          s.tokensReward,
          cell(s.sourcerName),
        ].join(','),
    ];
    await Clipboard.setData(ClipboardData(text: rows.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.modCsvCopied(subs.length))));
  }

  Widget _buildModerationWide(
    BuildContext context,
    List<AdminSubmission> pendingSubs,
    AdminSubmission? currentSub,
    int pendingCount,
    int approvedCount,
    int tokensIssuedCount,
  ) {
    final l = AppLocalizations.of(context)!;
    final visible = _visibleSubs(pendingSubs);
    final cur = visible.any((s) => s.id == _selectedSubId)
        ? visible.firstWhere((s) => s.id == _selectedSubId)
        : (visible.isEmpty ? null : visible.first);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(28, 8, 14, 40),
            children: [
              _statsRow(pendingCount, approvedCount, tokensIssuedCount),
              const SizedBox(height: 20),
              _buildFilterTabs(l, pendingSubs),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                _buildEmptyQueueCard()
              else
                for (final sub in visible)
                  _buildSubmissionCard(context, sub, sub.id == cur?.id, true),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 28, 28),
            child: DsCard(
              padding: const EdgeInsets.all(20),
              child: cur == null
                  ? _buildSidebarIdleState()
                  : _buildSidebarAuditState(context, cur),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModerationNarrow(
    BuildContext context,
    List<AdminSubmission> pendingSubs,
    int pendingCount,
    int approvedCount,
    int tokensIssuedCount,
  ) {
    final l = AppLocalizations.of(context)!;
    final visible = _visibleSubs(pendingSubs);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      children: [
        _statsRow(pendingCount, approvedCount, tokensIssuedCount),
        const SizedBox(height: 20),
        _buildFilterTabs(l, pendingSubs),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          _buildEmptyQueueCard()
        else
          for (final sub in visible)
            _buildSubmissionCard(context, sub, false, false),
      ],
    );
  }

  Widget _buildEmptyQueueCard() {
    final l = AppLocalizations.of(context)!;
    return DsCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: DsEmptyState(
        icon: Icons.done_all_rounded,
        title: l.modQueueClearedTitle,
        message: l.modQueueClearedBody,
      ),
    );
  }

  Widget _actionRow({required bool stacked, required List<Widget> children}) {
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            children[i],
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  bool get _largeText => MediaQuery.textScalerOf(context).scale(1) > 1.3;

  Widget _buildSubmissionCard(
    BuildContext context,
    AdminSubmission sub,
    bool isSelected,
    bool isDesktop,
  ) {
    final l = AppLocalizations.of(context)!;
    final flagged = sub.promoType == 'Flagged Report';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DsCard(
        selected: isSelected,
        color: flagged ? AppTheme.badLight : null,
        onTap: isDesktop ? () => setState(() => _selectedSubId = sub.id) : null,
        semanticLabel: '${sub.productName}, ${sub.storeName}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DsProductThumb(imageUrl: sub.productImageUrl, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.productName,
                        style: AppFonts.display(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sub.brand} · ${sub.storeName}',
                        style: AppFonts.body(
                          color: AppTheme.textLight,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                DsPrice(
                  sub.price,
                  size: 20,
                  color: flagged ? AppTheme.badText : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _attachmentChip(
                  icon: Icons.camera_alt_outlined,
                  label: l.modPricePhoto,
                  isAttached: sub.hasPhoto,
                  onTap: sub.hasPhoto
                      ? () => _showPricePhotoDialog(context, sub)
                      : null,
                ),
                _attachmentChip(
                  icon: Icons.receipt_long_outlined,
                  label: l.modReceipt,
                  isAttached: sub.hasReceipt,
                  onTap: sub.hasReceipt
                      ? () => _showReceiptDialog(context, sub)
                      : null,
                ),
                if (flagged)
                  DsTag(l.modCommunityFlagged, tone: DsTone.bad)
                else
                  DsTag(l.modRewardPlus(sub.tokensReward), tone: DsTone.warn),
              ],
            ),
            if (!isDesktop) ...[
              const SizedBox(height: 14),
              _actionRow(
                stacked: _largeText,
                children: [
                  DsButton(
                    label: flagged ? l.modDelete : l.modReject,
                    style: DsButtonStyle.danger,
                    compact: true,
                    onPressed: () => _reject(sub.id),
                  ),
                  if (!flagged)
                    DsButton(
                      label: l.modEdit,
                      style: DsButtonStyle.secondary,
                      compact: true,
                      onPressed: () => _showEditDialog(context, sub),
                    ),
                  DsButton(
                    label: flagged ? l.modReinstate : l.modApprove,
                    compact: true,
                    onPressed: () => _approve(sub.id, sub),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- RIGHT DETAILS PANEL ---
  Widget _buildSidebarIdleState() {
    final l = AppLocalizations.of(context)!;
    return DsEmptyState(
      icon: Icons.touch_app_outlined,
      title: l.modNothingSelected,
      message: l.modSelectToAudit,
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: AppFonts.body(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textLight,
      ),
    ),
  );

  Widget _buildSidebarAuditState(BuildContext context, AdminSubmission sub) {
    final l = AppLocalizations.of(context)!;
    final flagged = sub.promoType == 'Flagged Report';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    flagged ? l.modFlaggedReview : l.modAuditTitle,
                    style: AppFonts.display(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DsTag(
                flagged ? l.modStatusFlagged : l.modStatusPending,
                tone: flagged ? DsTone.bad : DsTone.warn,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l.modIdSubmitted(sub.id, sub.timestampLabel),
            style: AppFonts.body(fontSize: 14, color: AppTheme.textLight),
          ),
          const SizedBox(height: 16),
          if (flagged)
            DsBanner(
              l.modFlaggedAlertBody(
                sub.price.toStringAsFixed(2),
                sub.productName,
                sub.storeName,
              ),
              tone: DsBannerTone.warn,
            )
          else ...[
            _sectionLabel(l.modEvidence),
            Row(
              children: [
                Expanded(
                  child: _EvidenceThumbnail(
                    label: l.modPriceLabel,
                    url: sub.priceLabelUrl,
                    onTap: sub.hasPhoto
                        ? () => _showPricePhotoDialog(context, sub)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EvidenceThumbnail(
                    label: l.modReceipt,
                    url: sub.receiptUrl,
                    onTap: sub.hasReceipt
                        ? () => _showReceiptDialog(context, sub)
                        : null,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          _sectionLabel(flagged ? l.modInvestigation : l.modChecklist),
          if (flagged) ...[
            _auditCheckItem(l.modInvCatalog, true),
            _auditCheckItem(l.modInvDistributor, true),
            _auditCheckItem(l.modInvTrusted, false),
            _auditCheckItem(l.modInvReason, true),
          ] else ...[
            _auditCheckItem(l.modChkStore(sub.storeName), true),
            _auditCheckItem(l.modChkSize, true),
            _auditCheckItem(l.modChkPromo, sub.promoType != 'None'),
            _auditCheckItem(l.modChkFresh, sub.hasReceipt),
          ],
          const SizedBox(height: 12),
          DsCard(
            color: flagged ? AppTheme.warnLight : AppTheme.goodLight,
            borderless: true,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  flagged
                      ? Icons.warning_amber_rounded
                      : Icons.health_and_safety_outlined,
                  color: flagged ? AppTheme.warnText : AppTheme.goodText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flagged ? l.modTrustTitle : l.modAccuracyTitle,
                        style: AppFonts.display(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      Text(
                        flagged ? l.modTrustSub : l.modAccuracySub,
                        style: AppFonts.body(
                          fontSize: 13,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${sub.sourcerAccuracyRating.toStringAsFixed(0)}%',
                  style: AppFonts.display(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _actionRow(
            stacked: _largeText,
            children: [
              DsButton(
                label: flagged ? l.modReinstate : l.modApprove,
                onPressed: () => _approve(sub.id, sub),
              ),
              if (!flagged)
                DsButton(
                  label: l.modEdit,
                  style: DsButtonStyle.secondary,
                  onPressed: () => _showEditDialog(context, sub),
                ),
              DsButton(
                label: flagged ? l.modConfirmDeletion : l.modReject,
                style: DsButtonStyle.danger,
                onPressed: () => _reject(sub.id),
              ),
            ],
          ),
          _buildUserModerationActions(sub),
        ],
      ),
    );
  }

  Widget _buildUserModerationActions(AdminSubmission sub) {
    if (sub.sourcerId.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel(l.modSourcerControls),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DsButton(
                label: l.modWarn,
                style: DsButtonStyle.secondary,
                expanded: false,
                compact: true,
                onPressed: () => _moderateUser(sub, action: 'warn'),
              ),
              DsButton(
                label: l.modSuspend,
                style: DsButtonStyle.secondary,
                expanded: false,
                compact: true,
                onPressed: () => _moderateUser(sub, action: 'suspend'),
              ),
              DsButton(
                label: l.modBan,
                style: DsButtonStyle.danger,
                expanded: false,
                compact: true,
                onPressed: () => _moderateUser(sub, action: 'ban'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _auditCheckItem(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: done ? AppTheme.good : AppTheme.textLight,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppFonts.body(fontSize: 15, color: AppTheme.ink),
            ),
          ),
        ],
      ),
    );
  }

  // --- ACTIONS INTERFACE ---
  void _approve(String id, AdminSubmission sub) {
    ref.read(adminSubmissionsProvider.notifier).approveSubmission(id, ref);
    _selectNextAfterRemoval(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sub.promoType == 'Flagged Report'
              ? 'Price reinstated. Flags cleared.'
              : 'Submission approved! ${sub.tokensReward} tokens awarded to sourcer.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _reject(String id) {
    final pendingSubs = ref.read(adminSubmissionsProvider);
    final sub = pendingSubs.firstWhere(
      (s) => s.id == id,
      orElse: () => pendingSubs.first,
    );
    ref.read(adminSubmissionsProvider.notifier).rejectSubmission(id);
    _selectNextAfterRemoval(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sub.promoType == 'Flagged Report'
              ? 'Report confirmed. Price entry permanently deleted.'
              : 'Submission rejected.',
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _moderateUser(
    AdminSubmission sub, {
    required String action,
  }) async {
    final reasonCtrl = TextEditingController(
      text: action == 'warn'
          ? 'Please submit only clear, accurate shelf prices.'
          : action == 'suspend'
          ? 'Repeated incorrect or unverifiable submissions.'
          : 'Repeated policy violations after prior moderation.',
    );
    int suspendDays = 7;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            action == 'warn'
                ? 'Warn Sourcer'
                : action == 'suspend'
                ? 'Suspend Sourcer'
                : 'Ban Sourcer',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sub.sourcerName),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
              if (action == 'suspend') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: suspendDays,
                  decoration: const InputDecoration(labelText: 'Duration'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 day')),
                    DropdownMenuItem(value: 7, child: Text('7 days')),
                    DropdownMenuItem(value: 14, child: Text('14 days')),
                    DropdownMenuItem(value: 30, child: Text('30 days')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => suspendDays = value ?? 7),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                action == 'warn'
                    ? 'Send Warning'
                    : action == 'suspend'
                    ? 'Suspend'
                    : 'Ban',
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final reason = reasonCtrl.text.trim();
      final notifier = ref.read(adminSubmissionsProvider.notifier);
      if (action == 'warn') {
        await notifier.warnUser(sub.sourcerId, reason: reason);
      } else if (action == 'suspend') {
        await notifier.suspendUser(
          sub.sourcerId,
          reason: reason,
          days: suspendDays,
        );
      } else {
        await notifier.banUser(sub.sourcerId, reason: reason);
        _selectNextAfterRemoval(sub.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sourcer $action action saved.')));
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not $action sourcer: $err')),
      );
    }
  }

  void _selectNextAfterRemoval(String removedId) {
    final pendingSubs = ref.read(adminSubmissionsProvider);
    final remaining = pendingSubs.where((s) => s.id != removedId).toList();
    setState(() {
      if (remaining.isNotEmpty) {
        _selectedSubId = remaining.first.id;
      } else {
        _selectedSubId = null;
      }
    });
  }

  Widget _attachmentChip({
    required IconData icon,
    required String label,
    required bool isAttached,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isAttached ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAttached ? const Color(0xFFC8E6C9) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAttached ? Icons.check_circle_outline_rounded : icon,
              color: isAttached ? AppTheme.forestDeep : Colors.grey.shade600,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppFonts.body(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: isAttached ? AppTheme.forestDeep : Colors.grey.shade600,
              ),
            ),
            if (isAttached && onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.open_in_new_rounded,
                size: 8,
                color: AppTheme.forestDeep,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- EDIT DIALOG ---
  void _showEditDialog(BuildContext context, AdminSubmission sub) {
    final priceCtrl = TextEditingController(text: sub.price.toStringAsFixed(2));
    String selectedStore = sub.storeName;
    final storeNames = [
      'Carrefour JLT',
      'Lulu Al Barsha',
      'Spinneys JLT',
      'Union Coop Al Wasl',
      'Nesto Al Qusais',
    ];
    if (!storeNames.contains(selectedStore)) {
      storeNames.insert(0, selectedStore);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Edit Submission',
                style: AppFonts.display(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sub.productName,
                    style: AppFonts.body(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Corrected Price (AED)',
                      prefixIcon: Icon(Icons.payments_outlined),
                      suffixText: 'AED',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStore,
                    decoration: const InputDecoration(
                      labelText: 'Store',
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                    items: storeNames
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setDialogState(
                      () => selectedStore = val ?? selectedStore,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newPrice = double.tryParse(priceCtrl.text);
                    ref
                        .read(adminSubmissionsProvider.notifier)
                        .editSubmission(
                          sub.id,
                          storeName: selectedStore,
                          price: newPrice,
                        );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Submission updated.'),
                        backgroundColor: AppTheme.forestDeep,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.forestDeep,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog / mock panels support
  Widget _buildVoucherQueuePanel(List<VoucherRequest> vouchers) {
    final l = AppLocalizations.of(context)!;
    if (vouchers.isEmpty) {
      return DsEmptyState(
        icon: Icons.confirmation_num_outlined,
        title: l.vqEmptyTitle,
        message: l.vqEmptyBody,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: vouchers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final voucher = vouchers[index];
        final actions = [
          DsButton(
            label: l.modReject,
            style: DsButtonStyle.danger,
            compact: true,
            expanded: false,
            onPressed: () => _reviewVoucher(voucher, approve: false),
          ),
          DsButton(
            label: l.modApprove,
            compact: true,
            expanded: false,
            onPressed: () => _reviewVoucher(voucher, approve: true),
          ),
        ];
        return DsCard(
          child: LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 560 || _largeText;
              final info = Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.limeAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.confirmation_num_rounded,
                      color: AppTheme.forestDeep,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.vqLine(
                            voucher.userName,
                            voucher.denominationAed,
                            voucher.supermarket,
                          ),
                          style: AppFonts.display(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l.vqMeta(
                            voucher.userHomeArea ?? 'Dubai',
                            voucher.userTokenBalance,
                            voucher.tokenCost,
                          ),
                          style: AppFonts.body(
                            color: AppTheme.textLight,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              if (!narrow) {
                return Row(
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: 12),
                    actions[0],
                    const SizedBox(width: 8),
                    actions[1],
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  info,
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _reviewVoucher(
    VoucherRequest voucher, {
    required bool approve,
  }) async {
    final noteCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(approve ? 'Approve Voucher' : 'Reject Voucher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${voucher.userName} - AED ${voucher.denominationAed} ${voucher.supermarket}',
              style: AppFonts.body(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (approve) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A voucher code will be automatically selected and assigned from the active ${voucher.supermarket} (AED ${voucher.denominationAed}) inventory stock.',
                        style: AppFonts.body(
                          fontSize: 11,
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Admin note',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? AppTheme.forestDeep : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      if (approve) {
        await ref
            .read(adminVouchersProvider.notifier)
            .approveVoucher(voucher.id, adminNote: noteCtrl.text.trim());
      } else {
        await ref
            .read(adminVouchersProvider.notifier)
            .rejectVoucher(voucher.id, adminNote: noteCtrl.text.trim());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve ? 'Voucher approved successfully!' : 'Voucher rejected.',
            ),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not review voucher: $err'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildMapDensityPanel() {
    final l = AppLocalizations.of(context)!;
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final mapData = ref.watch(adminMapDataProvider);

    final chainsSet = mapData
        .map((e) => e['chain'] as String? ?? '')
        .where((c) => c.isNotEmpty)
        .toSet();
    final chains = ['All', ...chainsSet];
    if (!chains.contains(_mapSelectedChain)) {
      _mapSelectedChain = 'All';
    }

    final filteredStores = mapData.where((store) {
      final String chain = store['chain'] as String? ?? '';
      final String branchName = store['branchName'] as String? ?? '';
      final String area = store['area'] as String? ?? '';
      final matchesQuery =
          _mapSearchQuery.isEmpty ||
          chain.toLowerCase().contains(_mapSearchQuery.toLowerCase()) ||
          branchName.toLowerCase().contains(_mapSearchQuery.toLowerCase()) ||
          area.toLowerCase().contains(_mapSearchQuery.toLowerCase());
      final matchesChain =
          _mapSelectedChain == 'All' ||
          chain.toLowerCase() == _mapSelectedChain.toLowerCase();
      return matchesQuery && matchesChain;
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsBanner(l.mapInfo),
              Row(
                children: [const SizedBox.shrink(), const SizedBox(width: 8)],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: l.mapSearchHint,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _mapSearchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _mapSelectedChain,
                        isDense: true,
                        items: chains.map((String c) {
                          return DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              c,
                              style: AppFonts.body(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _mapSelectedChain = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Store List Panel (Desktop Sidebar)
              Container(
                width: wide ? 320 : null,
                height: wide ? null : 200,
                decoration: const BoxDecoration(
                  border: BorderDirectional(
                    end: BorderSide(color: AppTheme.line),
                    bottom: BorderSide(color: AppTheme.line),
                  ),
                ),
                child: Material(
                  color: Colors.white,
                  child: filteredStores.isEmpty
                      ? Center(
                          child: Text(
                            l.mapNoStores,
                            style: AppFonts.body(
                              fontSize: 16,
                              color: AppTheme.textLight,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredStores.length,
                          separatorBuilder: (context, index) =>
                              Divider(color: Colors.grey.shade100, height: 1),
                          itemBuilder: (context, index) {
                            final store = filteredStores[index];
                            final String chain =
                                store['chain'] as String? ?? 'Store';
                            final String branchName =
                                store['branchName'] as String? ?? '';
                            final String area = store['area'] as String? ?? '';
                            final int count =
                                store['activeSubmissionsCount'] as int? ?? 0;
                            final double lat = (store['lat'] is num)
                                ? (store['lat'] as num).toDouble()
                                : 25.2048;
                            final double lng = (store['lng'] is num)
                                ? (store['lng'] as num).toDouble()
                                : 55.2708;

                            return ListTile(
                              minVerticalPadding: 10,
                              title: Text(
                                '$chain $branchName',
                                style: AppFonts.body(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppTheme.ink,
                                ),
                              ),
                              subtitle: Text(
                                l.mapStoreMeta(area, count),
                                style: AppFonts.body(
                                  fontSize: 14,
                                  color: AppTheme.textLight,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 22,
                              ),
                              onTap: () {
                                _mapController.move(LatLng(lat, lng), 14.0);
                              },
                            );
                          },
                        ),
                ),
              ),
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(
                      25.2048,
                      55.2708,
                    ), // Dubai coordinates
                    initialZoom: 11.0,
                  ),
                  children: [
                    buildBaseTileLayer(context),
                    CircleLayer(
                      circles: filteredStores.map<CircleMarker>((store) {
                        final double lat = (store['lat'] is num)
                            ? (store['lat'] as num).toDouble()
                            : 25.2048;
                        final double lng = (store['lng'] is num)
                            ? (store['lng'] as num).toDouble()
                            : 55.2708;
                        final int count =
                            store['activeSubmissionsCount'] as int? ?? 0;
                        final Color circleColor = count < 3
                            ? AppTheme.good.withValues(alpha: 0.4)
                            : count < 6
                            ? AppTheme.limeAccent.withValues(alpha: 0.45)
                            : AppTheme.redAccent.withValues(alpha: 0.4);
                        return CircleMarker(
                          point: LatLng(lat, lng),
                          radius: (count * 6.0 + 12.0).clamp(12.0, 48.0),
                          useRadiusInMeter: false,
                          color: circleColor,
                          borderColor: circleColor.withValues(alpha: 0.7),
                          borderStrokeWidth: 2,
                        );
                      }).toList(),
                    ),
                    MarkerLayer(
                      markers: filteredStores.map<Marker>((store) {
                        final double lat = (store['lat'] is num)
                            ? (store['lat'] as num).toDouble()
                            : 25.2048;
                        final double lng = (store['lng'] is num)
                            ? (store['lng'] as num).toDouble()
                            : 55.2708;
                        final String chain =
                            store['chain'] as String? ?? 'Store';
                        final String branchName =
                            store['branchName'] as String? ?? '';
                        final int count =
                            store['activeSubmissionsCount'] as int? ?? 0;
                        return Marker(
                          point: LatLng(lat, lng),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Text(
                                    '$chain $branchName',
                                    style: AppFonts.display(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l.mapArea(
                                          '${store['area'] ?? 'Dubai'}',
                                        ),
                                        style: AppFonts.body(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l.mapApprovedCount(count),
                                        style: AppFonts.body(
                                          color: AppTheme.forestDeep,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(l.mapClose),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppTheme.forestDeep,
                              size: 32,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    buildMapAttribution(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoucherStockPanel() {
    final l = AppLocalizations.of(context)!;
    final inventory = ref.watch(adminVoucherInventoryProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: DsButton(
              label: l.vsImport,
              icon: Icons.add_rounded,
              expanded: false,
              onPressed: () => _showImportVouchersDialog(context),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: inventory.isEmpty
                ? DsEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: l.vsTitle,
                    message: l.vsEmpty,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 40),
                    itemCount: inventory.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = inventory[index] as Map<String, dynamic>;
                      final supermarket =
                          item['supermarket'] as String? ?? 'Unknown';
                      final denom = item['denominationAed'] as int? ?? 50;
                      final count = item['count'] as int? ?? 0;
                      final isUsed = item['isUsed'] as bool? ?? false;

                      return DsCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isUsed
                                    ? AppTheme.sand2
                                    : AppTheme.limeAccent.withValues(
                                        alpha: 0.2,
                                      ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.confirmation_num_rounded,
                                color: isUsed
                                    ? AppTheme.textLight
                                    : AppTheme.forestDeep,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.vsItem(supermarket, denom),
                                    style: AppFonts.display(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isUsed ? l.vsUsed : l.vsAvailable,
                                    style: AppFonts.body(
                                      fontSize: 14,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            DsTag(
                              l.vsCodes(count),
                              tone: isUsed ? DsTone.neutral : DsTone.good,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showImportVouchersDialog(BuildContext context) {
    final supermarketCtrl = TextEditingController();
    final denomCtrl = TextEditingController(text: '50');
    final codesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Import Voucher Codes',
            style: AppFonts.display(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: supermarketCtrl,
                  decoration: const InputDecoration(
                    labelText:
                        'Supermarket Name (e.g. Carrefour, LuLu, Spinneys)',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: denomCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Denomination (AED)',
                    prefixIcon: Icon(Icons.money_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codesCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Voucher Codes (one per line, min 4 chars)',
                    hintText: 'CODE123\nCODE456\nCODE789',
                    prefixIcon: Icon(Icons.confirmation_num_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final supermarket = supermarketCtrl.text.trim();
                final denom = int.tryParse(denomCtrl.text.trim()) ?? 50;
                final rawCodes = codesCtrl.text.trim().split('\n');
                final codes = rawCodes
                    .map((c) => c.trim())
                    .where((c) => c.length >= 4)
                    .toList();

                if (supermarket.isEmpty || codes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please fill out supermarket and enter valid codes.',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                try {
                  await ref
                      .read(adminVoucherInventoryProvider.notifier)
                      .importVouchers(
                        supermarket: supermarket,
                        denominationAed: denom,
                        codes: codes,
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vouchers imported successfully.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (err) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to import vouchers: $err'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forestDeep,
                foregroundColor: Colors.white,
              ),
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMockPanelContent() {
    if (_activeTab == 'settings') {
      return _buildSettingsPanel();
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: Colors.grey.shade400,
            size: 48,
          ),
          const SizedBox(height: 14),
          Text(
            'Restricted View',
            style: AppFonts.display(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This tab is mock-only in the DealSouk prototype.',
            style: AppFonts.body(fontSize: 12.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    final l = AppLocalizations.of(context)!;
    final settings = ref.watch(adminSettingsProvider);
    final notifier = ref.read(adminSettingsProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DsSectionHeader(l.setTitle),
              const SizedBox(height: 8),
              _settingsSlider(
                label: l.setEarn,
                value: settings.tokenEarnRate.toDouble(),
                min: 10,
                max: 100,
                divisions: 18,
                displayValue: l.setTokens(settings.tokenEarnRate),
                onChanged: (v) => notifier.setTokenEarnRate(v.round()),
              ),
              _settingsSlider(
                label: l.setThreshold,
                value: settings.voucherThreshold.toDouble(),
                min: 200,
                max: 1000,
                divisions: 16,
                displayValue: l.setTokens(settings.voucherThreshold),
                onChanged: (v) => notifier.setVoucherThreshold(v.round()),
              ),
              _settingsSlider(
                label: l.setCap,
                value: settings.dailySubmissionCap.toDouble(),
                min: 5,
                max: 50,
                divisions: 9,
                displayValue: l.setPerDay(settings.dailySubmissionCap),
                onChanged: (v) => notifier.setDailySubmissionCap(v.round()),
              ),
              _settingsSlider(
                label: l.setRequestCost,
                value: settings.requestCostTokens.toDouble(),
                min: 1,
                max: 50,
                divisions: 49,
                displayValue: l.setTokens(settings.requestCostTokens),
                onChanged: (v) => notifier.setRequestCostTokens(v.round()),
              ),
              const SizedBox(height: 4),
              DsBanner(l.setNote),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DsCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppFonts.body(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DsTag(displayValue, tone: DsTone.teal),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.forestDeep,
                thumbColor: AppTheme.forestDeep,
                inactiveTrackColor: AppTheme.sand2,
                overlayColor: AppTheme.forestDeep.withValues(alpha: 0.1),
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              ),
              child: Slider(
                semanticFormatterCallback: (_) => '$label $displayValue',
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HIGH FIDELITY REAL PREVIEWS & MOCK DIALOGS ---
  void _showReceiptDialog(BuildContext context, AdminSubmission sub) {
    final hasRealImage =
        sub.receiptUrl != null && sub.receiptUrl!.startsWith('http');
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      'Receipt Evidence — ${sub.productName}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Image container
              Container(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 32,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: hasRealImage
                    ? SingleChildScrollView(
                        child: _proofImage(
                          sub.receiptUrl!,
                          fit: BoxFit.contain,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No receipt photo was attached.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
              ),
              // Spacer so close button doesn't overlap on short screens
              const SizedBox(height: 12),
              // "Preview only" label
              if (hasRealImage)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, color: Colors.white70, size: 13),
                      SizedBox(width: 5),
                      Text(
                        'Preview only — download disabled',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Proof image viewer — preview-only, no download.
  //
  // Right-click / secondary-click is swallowed at both the gesture and pointer
  // layers so the browser never sees it as "Save image as…". Build the admin
  // web app with --web-renderer canvaskit (default for desktop) to also ensure
  // images are painted onto a <canvas> rather than raw <img> elements.
  // ---------------------------------------------------------------------------
  Widget _proofImage(
    String url, {
    BoxFit fit = BoxFit.contain,
    double? height,
    BorderRadius borderRadius = BorderRadius.zero,
  }) {
    final placeholder = SizedBox(
      height: height ?? 260,
      child: const Center(child: CircularProgressIndicator()),
    );
    final errorWidget = SizedBox(
      height: height ?? 120,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.grey, size: 36),
            SizedBox(height: 6),
            Text(
              'Could not load image',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );

    return Listener(
      // Swallow secondary (right-mouse) pointer-down events before they reach
      // the browser's native context-menu handler.
      behavior: HitTestBehavior.opaque,
      onPointerDown: (PointerDownEvent event) {
        if (event.buttons == kSecondaryMouseButton) {
          // consumed — do nothing
        }
      },
      child: GestureDetector(
        // Belt-and-suspenders: also block at the gesture level.
        onSecondaryTap: () {},
        onSecondaryTapDown: (_) {},
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Image.network(
            url,
            fit: fit,
            height: height,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : placeholder,
            errorBuilder: (context, error, stack) => errorWidget,
          ),
        ),
      ),
    );
  }

  void _showPricePhotoDialog(BuildContext context, AdminSubmission sub) {
    final hasRealImage =
        sub.priceLabelUrl != null && sub.priceLabelUrl!.startsWith('http');
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      'Price Label — ${sub.productName}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Image container
              Container(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 32,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: hasRealImage
                    ? SingleChildScrollView(
                        child: _proofImage(
                          sub.priceLabelUrl!,
                          fit: BoxFit.contain,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No price label photo was attached.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              if (hasRealImage)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, color: Colors.white70, size: 13),
                      SizedBox(width: 5),
                      Text(
                        'Preview only — download disabled',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // --- PRODUCTS CRUD PANEL ---
  Widget _buildProductsCrudPanel() {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(adminProductsProvider);
    final notifier = ref.read(adminProductsProvider.notifier);
    final categories = [
      'All',
      'Beverages',
      'Bakery',
      'Dairy & Eggs',
      'Pantry',
      'Fresh Produce',
      'Meat & Seafood',
      'Household',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 240, maxWidth: 520),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l.prSearch,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: notifier.setSearchQuery,
                ),
              ),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  constraints: const BoxConstraints(minHeight: 52),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.line, width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButton<String>(
                    value: state.selectedCategory ?? 'All',
                    items: [
                      for (final c in categories)
                        DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: AppFonts.body(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                    onChanged: notifier.setCategory,
                  ),
                ),
              ),
              DsButton(
                label: l.prAdd,
                icon: Icons.add_rounded,
                expanded: false,
                compact: true,
                onPressed: () => _showProductFormDialog(context, null),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.products.isEmpty
                ? DsEmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: l.prEmpty,
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          itemCount: state.products.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final p = state.products[index];
                            return DsCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  DsProductThumb(
                                    imageUrl: p.imageUrl,
                                    size: 56,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: AppFonts.display(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l.prMeta(
                                            p.brand.isNotEmpty ? p.brand : '—',
                                            p.packSize.isNotEmpty
                                                ? p.packSize
                                                : '—',
                                            p.category,
                                          ),
                                          style: AppFonts.body(
                                            fontSize: 14,
                                            color: AppTheme.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: l.modEdit,
                                    constraints: const BoxConstraints(
                                      minWidth: 48,
                                      minHeight: 48,
                                    ),
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      color: AppTheme.forestDeep,
                                    ),
                                    onPressed: () =>
                                        _showProductFormDialog(context, p),
                                  ),
                                  IconButton(
                                    tooltip: l.modDelete,
                                    constraints: const BoxConstraints(
                                      minWidth: 48,
                                      minHeight: 48,
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppTheme.redAccent,
                                    ),
                                    onPressed: () =>
                                        _confirmDeleteProduct(context, p),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      _pager(
                        l.prTotal(state.total),
                        state.currentPage,
                        (state.currentPage + 1) * 20 < state.total,
                        notifier.setPage,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _pager(String total, int page, bool hasNext, ValueChanged<int> go) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              total,
              style: AppFonts.body(fontSize: 15, color: AppTheme.textLight),
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.chevron_left),
            onPressed: page > 0 ? () => go(page - 1) : null,
          ),
          Text(
            l.prPage(page + 1),
            style: AppFonts.body(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.chevron_right),
            onPressed: hasNext ? () => go(page + 1) : null,
          ),
        ],
      ),
    );
  }

  void _showProductFormDialog(BuildContext context, Product? product) {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final brandCtrl = TextEditingController(text: product?.brand ?? '');
    final sizeCtrl = TextEditingController(text: product?.packSize ?? '');
    final barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    final imageCtrl = TextEditingController(text: product?.imageUrl ?? '');
    String category = product?.category ?? 'Beverages';
    final categories = [
      'Beverages',
      'Bakery',
      'Dairy & Eggs',
      'Pantry',
      'Fresh Produce',
      'Meat & Seafood',
      'Household',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isEdit ? 'Edit Product' : 'Add New Product',
                style: AppFonts.display(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: brandCtrl,
                        decoration: const InputDecoration(labelText: 'Brand'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: sizeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Pack Size (e.g. 500g, 6x1.5L)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                        ),
                        items: categories.map((c) {
                          return DropdownMenuItem<String>(
                            value: c,
                            child: Text(c),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              category = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: barcodeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Barcode / UPC',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: imageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.forestDeep,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name is required')),
                      );
                      return;
                    }
                    final payload = {
                      'name': nameCtrl.text.trim(),
                      'brand': brandCtrl.text.trim(),
                      'packSize': sizeCtrl.text.trim(),
                      'category': category,
                      'barcode': barcodeCtrl.text.trim(),
                      'imageUrl': imageCtrl.text.trim(),
                    };
                    try {
                      if (isEdit) {
                        await ref
                            .read(adminProductsProvider.notifier)
                            .updateProduct(product.id, payload);
                      } else {
                        await ref
                            .read(adminProductsProvider.notifier)
                            .createProduct(payload);
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit
                                  ? 'Product updated successfully'
                                  : 'Product created successfully',
                            ),
                          ),
                        );
                      }
                    } catch (err) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error saving product: $err')),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteProduct(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Text(
                'Are you sure?',
                style: AppFonts.display(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are about to delete: ${product.name}',
                  style: AppFonts.body(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Explanation of Permanent Consequences:',
                  style: AppFonts.body(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '• This product will be completely deleted from the catalog.\n'
                  '• All price submissions submitted by shoppers for this product will be permanently deleted.\n'
                  '• Shoppers will no longer be able to find this product or see its price history.\n'
                  '• This product will be removed from any active user carts.\n\n'
                  'This action is destructive, final, and cannot be undone.',
                  style: AppFonts.body(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  await ref
                      .read(adminProductsProvider.notifier)
                      .deleteProduct(product.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product deleted successfully'),
                      ),
                    );
                  }
                } catch (err) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting product: $err')),
                    );
                  }
                }
              },
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }

  // --- USERS CRUD PANEL ---
  Widget _buildUsersCrudPanel() {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(adminUsersProvider);
    final notifier = ref.read(adminUsersProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 240, maxWidth: 520),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l.usSearch,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: notifier.setSearchQuery,
                ),
              ),
              DsButton(
                label: l.usAdd,
                icon: Icons.person_add_rounded,
                expanded: false,
                compact: true,
                onPressed: () => _showUserFormDialog(context, null),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.users.isEmpty
                ? DsEmptyState(icon: Icons.people_outline, title: l.usEmpty)
                : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          itemCount: state.users.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final u = state.users[index];
                            return DsCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  DsAvatar(
                                    u.displayName,
                                    size: 48,
                                    photoUrl: u.avatarUrl,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              u.displayName,
                                              style: AppFonts.display(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.ink,
                                              ),
                                            ),
                                            if (u.isAdmin)
                                              DsTag(
                                                l.usAdminTag,
                                                tone: DsTone.bad,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l.usMeta(
                                            u.homeArea ?? '—',
                                            u.tokenBalance,
                                            u.accuracyRating.toStringAsFixed(0),
                                          ),
                                          style: AppFonts.body(
                                            fontSize: 14,
                                            color: AppTheme.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: l.modEdit,
                                    constraints: const BoxConstraints(
                                      minWidth: 48,
                                      minHeight: 48,
                                    ),
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      color: AppTheme.forestDeep,
                                    ),
                                    onPressed: () =>
                                        _showUserFormDialog(context, u),
                                  ),
                                  IconButton(
                                    tooltip: l.modDelete,
                                    constraints: const BoxConstraints(
                                      minWidth: 48,
                                      minHeight: 48,
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppTheme.redAccent,
                                    ),
                                    onPressed: () =>
                                        _confirmDeleteUser(context, u),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      _pager(
                        l.usTotal(state.total),
                        state.currentPage,
                        (state.currentPage + 1) * 20 < state.total,
                        notifier.setPage,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showUserFormDialog(BuildContext context, ProfileData? user) {
    final isEdit = user != null;
    final nameCtrl = TextEditingController(text: user?.displayName ?? '');
    final phoneCtrl = TextEditingController();
    final areaCtrl = TextEditingController(text: user?.homeArea ?? '');
    final tokensCtrl = TextEditingController(
      text: user?.tokenBalance.toString() ?? '0',
    );
    final firebaseUidCtrl = TextEditingController();
    String preferredLocale = user?.preferredLocale ?? 'en';
    bool isAdmin = user?.isAdmin ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isEdit ? 'Edit User Profile' : 'Add New User',
                style: AppFonts.display(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isEdit) ...[
                        TextField(
                          controller: firebaseUidCtrl,
                          decoration: const InputDecoration(
                            labelText:
                                'Firebase UID * (Must match auth account)',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Display Name *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number (optional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: areaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Home Area (e.g. Dubai Marina)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tokensCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Token Balance',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: preferredLocale,
                        decoration: const InputDecoration(
                          labelText: 'Preferred Locale *',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'en',
                            child: Text('English (en)'),
                          ),
                          DropdownMenuItem(
                            value: 'ar',
                            child: Text('Arabic (ar)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              preferredLocale = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Admin Privileges'),
                        value: isAdmin,
                        onChanged: (val) {
                          setDialogState(() {
                            isAdmin = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.forestDeep,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Display Name is required'),
                        ),
                      );
                      return;
                    }
                    if (!isEdit && firebaseUidCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Firebase UID is required for new users',
                          ),
                        ),
                      );
                      return;
                    }
                    final payload = {
                      'displayName': nameCtrl.text.trim(),
                      'homeArea': areaCtrl.text.trim().isEmpty
                          ? null
                          : areaCtrl.text.trim(),
                      'preferredLocale': preferredLocale,
                      'tokenBalance': int.tryParse(tokensCtrl.text.trim()) ?? 0,
                      'isAdmin': isAdmin,
                      if (phoneCtrl.text.trim().isNotEmpty)
                        'phoneNumber': phoneCtrl.text.trim(),
                      if (!isEdit) 'firebaseUid': firebaseUidCtrl.text.trim(),
                    };
                    try {
                      if (isEdit) {
                        await ref
                            .read(adminUsersProvider.notifier)
                            .updateUser(user.id, payload);
                      } else {
                        await ref
                            .read(adminUsersProvider.notifier)
                            .createUser(payload);
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit
                                  ? 'User updated successfully'
                                  : 'User created successfully',
                            ),
                          ),
                        );
                      }
                    } catch (err) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error saving user: $err')),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteUser(BuildContext context, ProfileData user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Text(
                'Are you sure?',
                style: AppFonts.display(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are about to delete user: ${user.displayName}',
                  style: AppFonts.body(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Explanation of Permanent Consequences:',
                  style: AppFonts.body(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '• The user\'s profile and login account will be permanently deleted.\n'
                  '• All tokens they have earned (${user.tokenBalance} tokens) will be permanently lost.\n'
                  '• All price submissions, receipt photos, and flags associated with this user will be deleted.\n'
                  '• All vouchers claimed or requested by this user will be removed or canceled.\n'
                  '• The user will be immediately logged out and will not be able to log back in.\n\n'
                  'This action is destructive, final, and cannot be undone.',
                  style: AppFonts.body(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  await ref
                      .read(adminUsersProvider.notifier)
                      .deleteUser(user.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User deleted successfully'),
                      ),
                    );
                  }
                } catch (err) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting user: $err')),
                    );
                  }
                }
              },
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar evidence thumbnail — shows the real photo when a URL is present,
// otherwise a placeholder icon. Tapping opens the full lightbox dialog.
// Right-click / secondary-click is blocked so the admin cannot save the image.
// ---------------------------------------------------------------------------
class _EvidenceThumbnail extends StatelessWidget {
  const _EvidenceThumbnail({
    required this.label,
    required this.url,
    required this.onTap,
  });

  final String label;
  final String? url;
  final VoidCallback? onTap;

  bool get _hasImage => url != null && url!.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onSecondaryTap: () {},
      onSecondaryTapDown: (_) {},
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: _hasImage ? Colors.black : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hasImage ? Colors.transparent : const Color(0xFFE8EEE4),
            ),
          ),
          child: _hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (e) {
                        if (e.buttons == kSecondaryMouseButton) {}
                      },
                      child: Image.network(
                        url!,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                        errorBuilder: (context, error, stack) => const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    // Label bar at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    // Expand icon hint
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.zoom_in,
                        color: Colors.white70,
                        size: 14,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      label == 'Receipt'
                          ? Icons.receipt_long_rounded
                          : Icons.camera_alt_rounded,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No $label',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AdminNavItem {
  const _AdminNavItem(this.tab, this.icon, this.label, {this.badge = 0});

  final String tab;
  final IconData icon;
  final String label;
  final int badge;
}

/// Shown to demo viewers: the console is real, but read-only.
class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.forestDeep,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.visibility_rounded, size: 18, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.modDemoBanner,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
