import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:dealsouk/features/admin/presentation/widgets/admin_panel_widgets.dart';
import 'package:dealsouk/features/admin/presentation/panels/analytics_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/features/auth/presentation/auth_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/features/admin/domain/admin_submission.dart';
import 'package:dealsouk/features/admin/domain/voucher_request.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:dealsouk/core/util/map_tiles.dart';
import 'package:latlong2/latlong.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/profile/data/profile_service.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  String? _selectedSubId;
  String _activeTab = 'moderation'; // 'moderation', 'analytics', 'settings'
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 840;
          if (isDesktop) {
            return _buildDesktopLayout(
              context,
              pendingSubs,
              currentSub,
              pendingCount,
              approvedCount,
              tokensIssuedCount,
              vouchers,
              voucherCount,
            );
          } else {
            return _buildMobileLayout(
              context,
              pendingSubs,
              pendingCount,
              approvedCount,
              tokensIssuedCount,
            );
          }
        },
      ),
    );
  }

  // --- DESKTOP SAAS SIDEBAR + MAIN AREA ---
  Widget _buildDesktopLayout(
    BuildContext context,
    List<AdminSubmission> pendingSubs,
    AdminSubmission? currentSub,
    int pendingCount,
    int approvedCount,
    int tokensIssuedCount,
    List<VoucherRequest> vouchers,
    int voucherCount,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. LEFT SIDEBAR (Dark Slate)
        Container(
          width: 240,
          color: const Color(0xFF0F172A), // Slate 900
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo area
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.limeAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: Color(0xFF0F172A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DealSouk',
                        style: AppFonts.display(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Moderator Console',
                        style: AppFonts.body(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Menu navigation
              _sidebarMenuItem(
                icon: Icons.gavel_rounded,
                label: 'Price Moderation',
                badgeCount: pendingCount,
                isActive: _activeTab == 'moderation',
                onTap: () => setState(() => _activeTab = 'moderation'),
              ),
              _sidebarMenuItem(
                icon: Icons.map_rounded,
                label: 'Map Density',
                isActive: _activeTab == 'map',
                onTap: () => setState(() => _activeTab = 'map'),
              ),
              _sidebarMenuItem(
                icon: Icons.bar_chart_rounded,
                label: 'Analytics',
                isActive: _activeTab == 'analytics',
                onTap: () => setState(() => _activeTab = 'analytics'),
              ),
              _sidebarMenuItem(
                icon: Icons.confirmation_num_rounded,
                label: 'Voucher Queue',
                badgeCount: voucherCount,
                isActive: _activeTab == 'vouchers',
                onTap: () => setState(() => _activeTab = 'vouchers'),
              ),
              _sidebarMenuItem(
                icon: Icons.inventory_2_rounded,
                label: 'Voucher Stock',
                isActive: _activeTab == 'stock',
                onTap: () => setState(() => _activeTab = 'stock'),
              ),
              _sidebarMenuItem(
                icon: Icons.settings_rounded,
                label: 'System Settings',
                isActive: _activeTab == 'settings',
                onTap: () => setState(() => _activeTab = 'settings'),
              ),
              _sidebarMenuItem(
                icon: Icons.shopping_bag_rounded,
                label: 'Manage Products',
                isActive: _activeTab == 'products_crud',
                onTap: () {
                  setState(() => _activeTab = 'products_crud');
                  ref.read(adminProductsProvider.notifier).fetch();
                },
              ),
              _sidebarMenuItem(
                icon: Icons.people_rounded,
                label: 'Manage Users',
                isActive: _activeTab == 'users_crud',
                onTap: () {
                  setState(() => _activeTab = 'users_crud');
                  ref.read(adminUsersProvider.notifier).fetch();
                },
              ),

              const Spacer(),

              // Bottom logout/back to app
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                title: Text(
                  'Back to App',
                  style: AppFonts.body(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Return to Profile',
                  style: AppFonts.body(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
                onTap: () => context.go('/profile'),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                ),
                title: Text(
                  'Log Out',
                  style: AppFonts.body(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Exit console',
                  style: AppFonts.body(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
                onTap: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/welcome');
                  }
                },
              ),
            ],
          ),
        ),

        // 2. MAIN CONSOLE PANEL
        Expanded(
          child: Column(
            children: [
              // Sticky Header
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _activeTab == 'moderation'
                          ? 'Audit & Verification'
                          : _activeTab == 'analytics'
                          ? 'Analytics & Performance'
                          : _activeTab == 'settings'
                          ? 'System Settings'
                          : _activeTab == 'vouchers'
                          ? 'Voucher Queue'
                          : _activeTab == 'products_crud'
                          ? 'Products Catalog Management'
                          : _activeTab == 'users_crud'
                          ? 'Users Directory Management'
                          : 'Sourcers Index',
                      style: AppFonts.display(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.security,
                                color: Colors.red,
                                size: 12,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Role: Admin Auditor',
                                style: AppFonts.body(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            if (_activeTab == 'vouchers') {
                              ref
                                  .read(adminVouchersProvider.notifier)
                                  .fetchVouchers();
                            } else if (_activeTab == 'analytics') {
                              ref
                                  .read(adminAnalyticsProvider.notifier)
                                  .fetchAnalytics();
                            } else if (_activeTab == 'moderation') {
                              ref
                                  .read(adminSubmissionsProvider.notifier)
                                  .fetchQueue();
                            } else if (_activeTab == 'map') {
                              ref
                                  .read(adminMapDataProvider.notifier)
                                  .fetchMapData();
                            } else if (_activeTab == 'stock') {
                              ref
                                  .read(adminVoucherInventoryProvider.notifier)
                                  .fetchInventoryStatus();
                            } else if (_activeTab == 'products_crud') {
                              ref.read(adminProductsProvider.notifier).fetch();
                            } else if (_activeTab == 'users_crud') {
                              ref.read(adminUsersProvider.notifier).fetch();
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Syncing queue with server...'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.sync_rounded, size: 15),
                          label: const Text('Refresh'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: _activeTab == 'moderation'
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left side: stats and list
                          Expanded(
                            flex: 5,
                            child: CustomScrollView(
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                // Stats Section
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      20,
                                      24,
                                      8,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: adminStatCard(
                                            'PENDING REVIEWS',
                                            '$pendingCount',
                                            Icons.hourglass_empty_rounded,
                                            Colors.orange,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: adminStatCard(
                                            'APPROVED TODAY',
                                            '$approvedCount',
                                            Icons.check_circle_outline_rounded,
                                            Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: adminStatCard(
                                            'TOKENS ISSUED',
                                            '$tokensIssuedCount',
                                            Icons.bolt_rounded,
                                            Colors.amber,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Header Row for queue
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      20,
                                      24,
                                      12,
                                    ),
                                    child: Text(
                                      'Submissions Review Queue',
                                      style: AppFonts.display(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ),
                                ),

                                // Submission items
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  sliver: pendingSubs.isEmpty
                                      ? SliverToBoxAdapter(
                                          child: _buildEmptyQueueCard(),
                                        )
                                      : SliverList(
                                          delegate: SliverChildBuilderDelegate((
                                            context,
                                            index,
                                          ) {
                                            final sub = pendingSubs[index];
                                            final isSelected =
                                                sub.id == _selectedSubId;
                                            return _buildSubmissionCard(
                                              context,
                                              sub,
                                              isSelected,
                                              true,
                                            );
                                          }, childCount: pendingSubs.length),
                                        ),
                                ),
                                const SliverPadding(
                                  padding: EdgeInsets.only(bottom: 40),
                                ),
                              ],
                            ),
                          ),

                          // Right side: Sticky detailed audit panel
                          VerticalDivider(
                            width: 1,
                            color: Colors.grey.shade200,
                          ),
                          Expanded(
                            flex: 3,
                            child: Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(24),
                              child: currentSub == null
                                  ? _buildSidebarIdleState()
                                  : _buildSidebarAuditState(
                                      context,
                                      currentSub,
                                    ),
                            ),
                          ),
                        ],
                      )
                    : _activeTab == 'map'
                    ? _buildMapDensityPanel()
                    : _activeTab == 'analytics'
                    ? const AnalyticsPanel()
                    : _activeTab == 'vouchers'
                    ? _buildVoucherQueuePanel(vouchers)
                    : _activeTab == 'stock'
                    ? _buildVoucherStockPanel()
                    : _activeTab == 'products_crud'
                    ? _buildProductsCrudPanel()
                    : _activeTab == 'users_crud'
                    ? _buildUsersCrudPanel()
                    : _buildMockPanelContent(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- MOBILE LAYOUT ---
  Widget _buildMobileLayout(
    BuildContext context,
    List<AdminSubmission> pendingSubs,
    int pendingCount,
    int approvedCount,
    int tokensIssuedCount,
  ) {
    return Column(
      children: [
        // App bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 8,
            16,
            12,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE8EEE4),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.forestDeep,
                    size: 16,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Admin Review',
                  textAlign: TextAlign.center,
                  style: AppFonts.display(
                    color: AppTheme.forestDeep,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),

        // Scrollable list
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Stats horizontally scrolling
              SliverToBoxAdapter(
                child: Container(
                  height: 94,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _mobileStatCard(
                        'Pending reviews',
                        '$pendingCount',
                        Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      _mobileStatCard(
                        'Approved today',
                        '$approvedCount',
                        Colors.green,
                      ),
                      const SizedBox(width: 10),
                      _mobileStatCard(
                        'Tokens issued',
                        '$tokensIssuedCount',
                        Colors.amber,
                      ),
                    ],
                  ),
                ),
              ),

              // Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Price Submissions (${pendingSubs.length})',
                    style: AppFonts.display(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ),

              // List items
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: pendingSubs.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyQueueCard())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final sub = pendingSubs[index];
                          return _buildSubmissionCard(
                            context,
                            sub,
                            false,
                            false,
                          );
                        }, childCount: pendingSubs.length),
                      ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
            ],
          ),
        ),
      ],
    );
  }

  // --- REUSABLE SAAS CARD COMPONENTS ---
  Widget _sidebarMenuItem({
    required IconData icon,
    required String label,
    int? badgeCount,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? const Border(
                      left: BorderSide(color: AppTheme.limeAccent, width: 3.5),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? AppTheme.limeAccent : Colors.grey.shade400,
                  size: 18,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: AppFonts.body(
                      color: isActive ? Colors.white : Colors.grey.shade400,
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobileStatCard(String label, String value, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEE4), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: AppFonts.body(
              fontSize: 9,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: AppFonts.display(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQueueCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEE4), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.done_all_rounded,
              color: Colors.green,
              size: 48,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Queue Cleared!',
            style: AppFonts.display(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No pending grocery price reports require verification.',
            textAlign: TextAlign.center,
            style: AppFonts.body(
              color: Colors.grey.shade500,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(
    BuildContext context,
    AdminSubmission sub,
    bool isSelected,
    bool isDesktop,
  ) {
    final isFlaggedReport = sub.promoType == 'Flagged Report';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isFlaggedReport
            ? const Color(
                0xFFFFF8F8,
              ) // Subtle red background for flagged reports
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppTheme.forestDeep
              : (isFlaggedReport
                    ? Colors.red.shade300
                    : const Color(0xFFE8EEE4)),
          width: isSelected ? 1.8 : 1.2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.forestDeep.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isDesktop
              ? () {
                  setState(() {
                    _selectedSubId = sub.id;
                  });
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isFlaggedReport) ...[
                                Icon(
                                  Icons.report_problem_rounded,
                                  color: Colors.red.shade700,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  sub.productName,
                                  style: AppFonts.display(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Brand: ${sub.brand} • Store: ${sub.storeName}',
                            style: AppFonts.body(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'AED ${sub.price.toStringAsFixed(2)}',
                      style: AppFonts.display(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isFlaggedReport
                            ? Colors.red
                            : AppTheme.forestDeep,
                        decoration: isFlaggedReport
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _attachmentChip(
                          icon: Icons.camera_alt_outlined,
                          label: 'Price Photo',
                          isAttached: sub.hasPhoto,
                          onTap: sub.hasPhoto
                              ? () => _showPricePhotoDialog(context, sub)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        _attachmentChip(
                          icon: Icons.receipt_long_outlined,
                          label: 'Receipt',
                          isAttached: sub.hasReceipt,
                          onTap: sub.hasReceipt
                              ? () => _showReceiptDialog(context, sub)
                              : null,
                        ),
                      ],
                    ),
                    if (isFlaggedReport)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Community Flagged',
                          style: AppFonts.body(
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            color: Colors.red.shade700,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.amberAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Reward: +${sub.tokensReward}T',
                          style: AppFonts.body(
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            color: const Color(0xFFC77C02),
                          ),
                        ),
                      ),
                  ],
                ),
                if (!isDesktop) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _reject(sub.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: AppFonts.body(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: Text(
                            isFlaggedReport ? 'Confirm Deletion' : 'Reject',
                          ),
                        ),
                      ),
                      if (!isFlaggedReport) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _showEditDialog(context, sub),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.forestDeep,
                            side: const BorderSide(color: AppTheme.forestDeep),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: AppFonts.body(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('Edit'),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _approve(sub.id, sub),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: AppFonts.body(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: Text(
                            isFlaggedReport ? 'Reinstate Price' : 'Approve',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- RIGHT DETAILS PANEL ---
  Widget _buildSidebarIdleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_empty_rounded,
              color: Colors.grey.shade400,
              size: 40,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'System Idle',
            style: AppFonts.display(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a queue item to audit',
            style: AppFonts.body(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarAuditState(BuildContext context, AdminSubmission sub) {
    final isFlaggedReport = sub.promoType == 'Flagged Report';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isFlaggedReport ? 'Moderation Review' : 'Submission Audit',
                style: AppFonts.display(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isFlaggedReport
                    ? Colors.red.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isFlaggedReport
                      ? Colors.red.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Text(
                isFlaggedReport ? 'FLAGGED' : 'PENDING',
                style: AppFonts.body(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: isFlaggedReport
                      ? Colors.red.shade800
                      : Colors.orange.shade800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'ID: ${sub.id}  ·  Submitted ${sub.timestampLabel}',
          style: AppFonts.body(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),

        if (isFlaggedReport) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.report_problem_rounded,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Accuracy Verification Alert',
                      style: AppFonts.display(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'This price entry has been flagged 3+ times by DealSouk shoppers. The price of AED ${sub.price.toStringAsFixed(2)} is reported as incorrect for ${sub.productName} at ${sub.storeName}.',
                  style: AppFonts.body(
                    fontSize: 11.5,
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ] else ...[
          // Visual Thumbnail previews of attachments
          Text(
            'ATTACHED EVIDENCE (TAP TO VIEW):',
            style: AppFonts.body(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _EvidenceThumbnail(
                  label: 'Price Label',
                  url: sub.priceLabelUrl,
                  onTap: sub.hasPhoto
                      ? () => _showPricePhotoDialog(context, sub)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _EvidenceThumbnail(
                  label: 'Receipt',
                  url: sub.receiptUrl,
                  onTap: sub.hasReceipt
                      ? () => _showReceiptDialog(context, sub)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],

        // Guidelines Checklist
        const Divider(height: 1),
        const SizedBox(height: 20),
        Text(
          isFlaggedReport ? 'INVESTIGATION PROTOCOLS:' : 'CHECKLIST PROTOCOLS:',
          style: AppFonts.body(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        if (isFlaggedReport) ...[
          _auditCheckItem(
            'Cross-check price with latest online store catalog',
            true,
          ),
          _auditCheckItem(
            'Verify if the item has a regional distributor price change',
            true,
          ),
          _auditCheckItem(
            'Verify if this price entry was submitted by a trusted user',
            false,
          ),
          _auditCheckItem(
            'Flag reason: Shopper claims price is outdated/wrong',
            true,
          ),
        ] else ...[
          _auditCheckItem(
            'Confirm receipt matches store: ${sub.storeName}',
            true,
          ),
          _auditCheckItem('Validate price matches packaging size', true),
          _auditCheckItem(
            'Double-check for discount/promo tags',
            sub.promoType != 'None',
          ),
          _auditCheckItem(
            'Freshness: Check receipt timestamp matches',
            sub.hasReceipt,
          ),
        ],
        const Spacer(),

        // Audit health KPI
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFlaggedReport
                ? const Color(0xFFFFF3E0)
                : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFlaggedReport
                  ? const Color(0xFFFFE0B2)
                  : const Color(0xFFC8E6C9),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isFlaggedReport
                      ? const Color(0xFFFFE0B2)
                      : const Color(0xFFC8E6C9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFlaggedReport
                      ? Icons.warning_amber_rounded
                      : Icons.health_and_safety_outlined,
                  color: isFlaggedReport
                      ? Colors.orange.shade800
                      : AppTheme.forestDeep,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFlaggedReport
                          ? 'Community Trust Level'
                          : 'Auditing Accuracy Score',
                      style: AppFonts.display(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isFlaggedReport
                            ? Colors.orange.shade900
                            : AppTheme.forestDeep,
                      ),
                    ),
                    Text(
                      isFlaggedReport
                          ? 'Based on reporter history'
                          : 'Sourcer trustworthiness KPI',
                      style: AppFonts.body(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isFlaggedReport ? '92.0%' : '98.4%',
                style: AppFonts.display(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isFlaggedReport
                      ? Colors.orange.shade900
                      : AppTheme.forestDeep,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Sidebar Actions (Reject / Edit / Approve)
        if (!isFlaggedReport)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton.icon(
              onPressed: () => _showEditDialog(context, sub),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(
                'Edit Submission',
                style: AppFonts.body(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.forestDeep,
                side: const BorderSide(color: AppTheme.forestDeep),
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        _buildUserModerationActions(sub),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _reject(sub.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isFlaggedReport ? 'Confirm Deletion' : 'Reject',
                  style: AppFonts.body(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _approve(sub.id, sub),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isFlaggedReport ? 'Reinstate Price' : 'Approve',
                  style: AppFonts.body(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserModerationActions(AdminSubmission sub) {
    if (sub.sourcerId.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sourcer controls',
          style: AppFonts.body(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _moderateUser(sub, action: 'warn'),
              icon: const Icon(Icons.notification_important_outlined, size: 16),
              label: const Text('Warn'),
            ),
            OutlinedButton.icon(
              onPressed: () => _moderateUser(sub, action: 'suspend'),
              icon: const Icon(Icons.pause_circle_outline, size: 16),
              label: const Text('Suspend'),
            ),
            OutlinedButton.icon(
              onPressed: () => _moderateUser(sub, action: 'ban'),
              icon: const Icon(Icons.block, size: 16),
              label: const Text('Ban'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _auditCheckItem(String label, bool initialVal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            initialVal
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            color: initialVal ? Colors.green : Colors.grey.shade400,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppFonts.body(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
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
    if (vouchers.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EEE4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.confirmation_num_outlined,
                size: 46,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No voucher requests',
                style: AppFonts.display(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'New requests appear here when shoppers reach the token threshold.',
                textAlign: TextAlign.center,
                style: AppFonts.body(
                  color: Colors.grey.shade600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: vouchers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final voucher = vouchers[index];
        return Container(
          padding: const EdgeInsets.all(16),
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
                decoration: BoxDecoration(
                  color: AppTheme.limeAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
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
                      '${voucher.userName} - AED ${voucher.denominationAed} ${voucher.supermarket}',
                      style: AppFonts.display(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${voucher.userHomeArea ?? 'Dubai'} | ${voucher.userTokenBalance} tokens available | cost ${voucher.tokenCost}',
                      style: AppFonts.body(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _reviewVoucher(voucher, approve: false),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reject'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _reviewVoucher(voucher, approve: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.forestDeep,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Approve'),
              ),
            ],
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
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.forestDeep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Visualizing active grocery price submissions across Dubai. Circles show submission density. Tap any marker pin to inspect store details.',
                      style: AppFonts.body(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search stores by name, branch, or area...',
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Store List Panel (Desktop Sidebar)
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: filteredStores.isEmpty
                    ? Center(
                        child: Text(
                          'No stores match filters.',
                          style: AppFonts.body(color: Colors.grey),
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
                            title: Text(
                              '$chain $branchName',
                              style: AppFonts.body(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.textDark,
                              ),
                            ),
                            subtitle: Text(
                              'Area: $area • Approved: $count',
                              style: AppFonts.body(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 14),
                            onTap: () {
                              _mapController.move(LatLng(lat, lng), 14.0);
                            },
                          );
                        },
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
                            ? Colors.green.withValues(alpha: 0.4)
                            : count < 6
                            ? Colors.orange.withValues(alpha: 0.4)
                            : Colors.red.withValues(alpha: 0.4);
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
                                        'Area: ${store['area'] ?? 'Dubai'}',
                                        style: AppFonts.body(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Approved submissions count: $count',
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
                                      child: const Text('Close'),
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
    final inventory = ref.watch(adminVoucherInventoryProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Voucher Stock Levels',
                style: AppFonts.display(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showImportVouchersDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Import Voucher Codes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.forestDeep,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: inventory.isEmpty
                ? Center(
                    child: Text(
                      'No voucher stock records. Click import to add voucher codes.',
                      style: AppFonts.body(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : ListView.separated(
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

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8EEE4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isUsed
                                        ? Colors.grey.shade100
                                        : AppTheme.limeAccent.withValues(
                                            alpha: 0.2,
                                          )),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.confirmation_num_rounded,
                                    color: isUsed
                                        ? Colors.grey
                                        : AppTheme.forestDeep,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$supermarket (AED $denom)',
                                      style: AppFonts.display(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isUsed
                                          ? 'Used Vouchers'
                                          : 'Available Unused Stock',
                                      style: AppFonts.body(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isUsed
                                    ? Colors.grey.shade100
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$count codes',
                                style: AppFonts.body(
                                  fontWeight: FontWeight.w900,
                                  color: isUsed
                                      ? Colors.grey.shade700
                                      : Colors.green.shade800,
                                ),
                              ),
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
    final settings = ref.watch(adminSettingsProvider);
    final notifier = ref.read(adminSettingsProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Token Economy Settings',
            style: AppFonts.display(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),
          _settingsSlider(
            label: 'Token Earn Rate (base)',
            value: settings.tokenEarnRate.toDouble(),
            min: 10,
            max: 100,
            divisions: 18,
            displayValue: '${settings.tokenEarnRate} tokens',
            onChanged: (v) => notifier.setTokenEarnRate(v.round()),
          ),
          const SizedBox(height: 20),
          _settingsSlider(
            label: 'Voucher Threshold (tokens)',
            value: settings.voucherThreshold.toDouble(),
            min: 200,
            max: 1000,
            divisions: 16,
            displayValue: '${settings.voucherThreshold} tokens',
            onChanged: (v) => notifier.setVoucherThreshold(v.round()),
          ),
          const SizedBox(height: 20),
          _settingsSlider(
            label: 'Daily Submission Cap',
            value: settings.dailySubmissionCap.toDouble(),
            min: 5,
            max: 50,
            divisions: 9,
            displayValue: '${settings.dailySubmissionCap} per day',
            onChanged: (v) => notifier.setDailySubmissionCap(v.round()),
          ),
          const SizedBox(height: 20),
          _settingsSlider(
            label: 'Request Cost',
            value: settings.requestCostTokens.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            displayValue: '${settings.requestCostTokens} tokens',
            onChanged: (v) => notifier.setRequestCostTokens(v.round()),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.forestDeep,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Changes take effect immediately across the live demo session.',
                    style: AppFonts.body(
                      fontSize: 12,
                      color: AppTheme.forestDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppFonts.body(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.textDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.limeAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayValue,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.forestDeep,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.forestDeep,
            thumbColor: AppTheme.forestDeep,
            inactiveTrackColor: Colors.grey.shade200,
            overlayColor: AppTheme.forestDeep.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Products Catalog Management',
                style: AppFonts.display(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showProductFormDialog(context, null),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.forestDeep,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products by name, brand, or barcode...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (val) {
                    notifier.setSearchQuery(val);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.selectedCategory ?? 'All',
                    items: categories.map((c) {
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
                      notifier.setCategory(val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.products.isEmpty
                ? Center(
                    child: Text(
                      'No products found matching filters.',
                      style: AppFonts.body(color: Colors.grey, fontSize: 15),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: state.products.length,
                            separatorBuilder: (context, index) =>
                                Divider(color: Colors.grey.shade100, height: 1),
                            itemBuilder: (context, index) {
                              final p = state.products[index];
                              return ListTile(
                                leading: p.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          p.imageUrl,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Container(
                                                width: 40,
                                                height: 40,
                                                color: Colors.grey.shade100,
                                                child: const Icon(
                                                  Icons.shopping_bag_outlined,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                        ),
                                      )
                                    : Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.shopping_bag_outlined,
                                          color: Colors.grey,
                                        ),
                                      ),
                                title: Text(
                                  p.name,
                                  style: AppFonts.body(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                subtitle: Text(
                                  'Brand: ${p.brand.isNotEmpty ? p.brand : "—"} • Size: ${p.packSize.isNotEmpty ? p.packSize : "—"} • Category: ${p.category} • Barcode: ${p.barcode.isNotEmpty ? p.barcode : "—"}',
                                  style: AppFonts.body(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        color: Colors.blueAccent,
                                      ),
                                      onPressed: () =>
                                          _showProductFormDialog(context, p),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.redAccent,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Products: ${state.total}',
                                style: AppFonts.body(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: state.currentPage > 0
                                        ? () => notifier.setPage(
                                            state.currentPage - 1,
                                          )
                                        : null,
                                  ),
                                  Text(
                                    'Page ${state.currentPage + 1}',
                                    style: AppFonts.body(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed:
                                        (state.currentPage + 1) * 20 <
                                            state.total
                                        ? () => notifier.setPage(
                                            state.currentPage + 1,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
    final state = ref.watch(adminUsersProvider);
    final notifier = ref.read(adminUsersProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Users Directory Management',
                style: AppFonts.display(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showUserFormDialog(context, null),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Add User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.forestDeep,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users by name, phone, or UID...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (val) {
                    notifier.setSearchQuery(val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.users.isEmpty
                ? Center(
                    child: Text(
                      'No users found matching search.',
                      style: AppFonts.body(color: Colors.grey, fontSize: 15),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: state.users.length,
                            separatorBuilder: (context, index) =>
                                Divider(color: Colors.grey.shade100, height: 1),
                            itemBuilder: (context, index) {
                              final u = state.users[index];
                              return ListTile(
                                leading:
                                    u.avatarUrl != null &&
                                        u.avatarUrl!.isNotEmpty
                                    ? CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          u.avatarUrl!,
                                        ),
                                        radius: 20,
                                      )
                                    : const CircleAvatar(
                                        radius: 20,
                                        child: Icon(Icons.person_outline),
                                      ),
                                title: Row(
                                  children: [
                                    Text(
                                      u.displayName,
                                      style: AppFonts.body(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    if (u.isAdmin) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          'Admin',
                                          style: TextStyle(
                                            color: Colors.red.shade900,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  'ID: ${u.id} • Locale: ${u.preferredLocale} • Home Area: ${u.homeArea ?? "—"} • Tokens: ${u.tokenBalance} • Accuracy: ${u.accuracyRating.toStringAsFixed(1)}%',
                                  style: AppFonts.body(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        color: Colors.blueAccent,
                                      ),
                                      onPressed: () =>
                                          _showUserFormDialog(context, u),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.redAccent,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Users: ${state.total}',
                                style: AppFonts.body(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: state.currentPage > 0
                                        ? () => notifier.setPage(
                                            state.currentPage - 1,
                                          )
                                        : null,
                                  ),
                                  Text(
                                    'Page ${state.currentPage + 1}',
                                    style: AppFonts.body(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed:
                                        (state.currentPage + 1) * 20 <
                                            state.total
                                        ? () => notifier.setPage(
                                            state.currentPage + 1,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
