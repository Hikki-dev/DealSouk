import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/state/state.dart';
import '../../core/theme/theme.dart';
import '../../core/models/models.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  String? _selectedSubId;
  String _activeTab = 'moderation'; // 'moderation', 'analytics', 'settings'

  @override
  Widget build(BuildContext context) {
    final pendingSubs = ref.watch(adminSubmissionsProvider);
    final int pendingCount = pendingSubs.length;

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
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Moderator Console',
                        style: GoogleFonts.nunito(
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
                icon: Icons.bar_chart_rounded,
                label: 'Analytics',
                isActive: _activeTab == 'analytics',
                onTap: () => setState(() => _activeTab = 'analytics'),
              ),
              _sidebarMenuItem(
                icon: Icons.people_rounded,
                label: 'Sourcers Index',
                isActive: _activeTab == 'sourcers',
                onTap: () => setState(() => _activeTab = 'sourcers'),
              ),
              _sidebarMenuItem(
                icon: Icons.settings_rounded,
                label: 'System Settings',
                isActive: _activeTab == 'settings',
                onTap: () => setState(() => _activeTab = 'settings'),
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
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Return to Profile',
                  style: GoogleFonts.nunito(
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
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Exit console',
                  style: GoogleFonts.nunito(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
                onTap: () => context.go('/welcome'),
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
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _activeTab == 'moderation'
                          ? 'Audit & Verification'
                          : _activeTab == 'analytics'
                              ? 'Analytics & Performance'
                              : 'System Settings',
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.security, color: Colors.red, size: 12),
                              const SizedBox(width: 6),
                              Text(
                                'Role: Admin Auditor',
                                style: GoogleFonts.nunito(
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Syncing queue with server...')),
                            );
                          },
                          icon: const Icon(Icons.sync_rounded, size: 15),
                          label: const Text('Refresh'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _statCard(
                                            'PENDING REVIEWS',
                                            '$pendingCount',
                                            Icons.hourglass_empty_rounded,
                                            Colors.orange,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: _statCard(
                                            'APPROVED TODAY',
                                            '$approvedCount',
                                            Icons.check_circle_outline_rounded,
                                            Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: _statCard(
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
                                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                                    child: Text(
                                      'Submissions Review Queue',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ),
                                ),

                                // Submission items
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  sliver: pendingSubs.isEmpty
                                      ? SliverToBoxAdapter(child: _buildEmptyQueueCard())
                                      : SliverList(
                                          delegate: SliverChildBuilderDelegate(
                                            (context, index) {
                                              final sub = pendingSubs[index];
                                              final isSelected = sub.id == _selectedSubId;
                                              return _buildSubmissionCard(
                                                context,
                                                sub,
                                                isSelected,
                                                true,
                                              );
                                            },
                                            childCount: pendingSubs.length,
                                          ),
                                        ),
                                ),
                                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                              ],
                            ),
                          ),

                          // Right side: Sticky detailed audit panel
                          VerticalDivider(width: 1, color: Colors.grey.shade200),
                          Expanded(
                            flex: 3,
                            child: Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(24),
                              child: currentSub == null
                                  ? _buildSidebarIdleState()
                                  : _buildSidebarAuditState(context, currentSub),
                            ),
                          ),
                        ],
                      )
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
                    border: Border.all(color: const Color(0xFFE8EEE4), width: 1.2),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.forestDeep, size: 16),
                ),
              ),
              Expanded(
                child: Text(
                  'Admin Review',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
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
                      _mobileStatCard('Pending reviews', '$pendingCount', Colors.orange),
                      const SizedBox(width: 10),
                      _mobileStatCard('Approved today', '$approvedCount', Colors.green),
                      const SizedBox(width: 10),
                      _mobileStatCard('Tokens issued', '$tokensIssuedCount', Colors.amber),
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
                    style: GoogleFonts.fredoka(
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
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final sub = pendingSubs[index];
                            return _buildSubmissionCard(context, sub, false, false);
                          },
                          childCount: pendingSubs.length,
                        ),
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
              color: isActive ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? const Border(left: BorderSide(color: AppTheme.limeAccent, width: 3.5))
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
                    style: GoogleFonts.nunito(
                      color: isActive ? Colors.white : Colors.grey.shade400,
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEE4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
              height: 1.0,
            ),
          ),
        ],
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
            style: GoogleFonts.nunito(
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
                style: GoogleFonts.fredoka(
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
            child: const Icon(Icons.done_all_rounded, color: Colors.green, size: 48),
          ),
          const SizedBox(height: 18),
          Text(
            'Queue Cleared!',
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No pending grocery price reports require verification.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
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
            ? const Color(0xFFFFF8F8) // Subtle red background for flagged reports
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
                                Icon(Icons.report_problem_rounded, color: Colors.red.shade700, size: 16),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  sub.productName,
                                  style: GoogleFonts.fredoka(
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
                            style: GoogleFonts.nunito(
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
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isFlaggedReport ? Colors.red : AppTheme.forestDeep,
                        decoration: isFlaggedReport ? TextDecoration.lineThrough : null,
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
                          onTap: sub.hasPhoto ? () => _showPricePhotoDialog(context, sub) : null,
                        ),
                        const SizedBox(width: 8),
                        _attachmentChip(
                          icon: Icons.receipt_long_outlined,
                          label: 'Receipt',
                          isAttached: sub.hasReceipt,
                          onTap: sub.hasReceipt ? () => _showReceiptDialog(context, sub) : null,
                        ),
                      ],
                    ),
                    if (isFlaggedReport)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Community Flagged',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            color: Colors.red.shade700,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.amberAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Reward: +${sub.tokensReward}T',
                          style: GoogleFonts.nunito(
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          child: Text(isFlaggedReport ? 'Confirm Deletion' : 'Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _approve(sub.id, sub),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          child: Text(isFlaggedReport ? 'Reinstate Price' : 'Approve'),
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
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.hourglass_empty_rounded, color: Colors.grey.shade400, size: 40),
          ),
          const SizedBox(height: 14),
          Text(
            'System Idle',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a queue item to audit',
            style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey.shade500),
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
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isFlaggedReport ? Colors.red.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isFlaggedReport ? Colors.red.shade200 : Colors.orange.shade200),
              ),
              child: Text(
                isFlaggedReport ? 'FLAGGED' : 'PENDING',
                style: GoogleFonts.nunito(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: isFlaggedReport ? Colors.red.shade800 : Colors.orange.shade800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'ID: ${sub.id}  ·  Submitted ${sub.timestampLabel}',
          style: GoogleFonts.nunito(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
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
                    Icon(Icons.report_problem_rounded, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Accuracy Verification Alert',
                      style: GoogleFonts.fredoka(
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
                  style: GoogleFonts.nunito(
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
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: sub.hasPhoto ? () => _showPricePhotoDialog(context, sub) : null,
                  child: Container(
                    height: 84,
                    decoration: BoxDecoration(
                      color: sub.hasPhoto ? const Color(0xFFE3F2FD) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sub.hasPhoto ? const Color(0xFF90CAF9) : const Color(0xFFE8EEE4),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          color: sub.hasPhoto ? Colors.blue.shade700 : Colors.grey.shade400,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sub.hasPhoto ? 'Price Label Pic' : 'No Photo',
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: sub.hasPhoto ? Colors.blue.shade800 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: sub.hasReceipt ? () => _showReceiptDialog(context, sub) : null,
                  child: Container(
                    height: 84,
                    decoration: BoxDecoration(
                      color: sub.hasReceipt ? const Color(0xFFE0F2F1) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sub.hasReceipt ? const Color(0xFF80CBC4) : const Color(0xFFE8EEE4),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          color: sub.hasReceipt ? Colors.teal.shade700 : Colors.grey.shade400,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sub.hasReceipt ? 'Receipt Scan' : 'No Receipt',
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: sub.hasReceipt ? Colors.teal.shade800 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
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
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        if (isFlaggedReport) ...[
          _auditCheckItem('Cross-check price with latest online store catalog', true),
          _auditCheckItem('Verify if the item has a regional distributor price change', true),
          _auditCheckItem('Verify if this price entry was submitted by a trusted user', false),
          _auditCheckItem('Flag reason: Shopper claims price is outdated/wrong', true),
        ] else ...[
          _auditCheckItem('Confirm receipt matches store: ${sub.storeName}', true),
          _auditCheckItem('Validate price matches packaging size', true),
          _auditCheckItem('Double-check for discount/promo tags', sub.promoType != 'None'),
          _auditCheckItem('Freshness: Check receipt timestamp matches', sub.hasReceipt),
        ],
        const Spacer(),

        // Audit health KPI
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFlaggedReport ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isFlaggedReport ? const Color(0xFFFFE0B2) : const Color(0xFFC8E6C9)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isFlaggedReport ? const Color(0xFFFFE0B2) : const Color(0xFFC8E6C9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFlaggedReport ? Icons.warning_amber_rounded : Icons.health_and_safety_outlined,
                  color: isFlaggedReport ? Colors.orange.shade800 : AppTheme.forestDeep,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFlaggedReport ? 'Community Trust Level' : 'Auditing Accuracy Score',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isFlaggedReport ? Colors.orange.shade900 : AppTheme.forestDeep,
                      ),
                    ),
                    Text(
                      isFlaggedReport ? 'Based on reporter history' : 'Sourcer trustworthiness KPI',
                      style: GoogleFonts.nunito(
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
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isFlaggedReport ? Colors.orange.shade900 : AppTheme.forestDeep,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Sidebar Actions (Reject / Approve)
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _reject(sub.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isFlaggedReport ? 'Confirm Deletion' : 'Reject',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isFlaggedReport ? 'Reinstate Price' : 'Approve',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                ),
              ),
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
            initialVal ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: initialVal ? Colors.green : Colors.grey.shade400,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunito(
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
    final sub = pendingSubs.firstWhere((s) => s.id == id, orElse: () => pendingSubs.first);
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
              style: GoogleFonts.nunito(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: isAttached ? AppTheme.forestDeep : Colors.grey.shade600,
              ),
            ),
            if (isAttached && onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.open_in_new_rounded, size: 8, color: AppTheme.forestDeep),
            ],
          ],
        ),
      ),
    );
  }

  // Dialog / mock panels support
  Widget _buildMockPanelContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 48),
          const SizedBox(height: 14),
          Text(
            'Restricted View',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'This tab is mock-only in the DealSouk prototype.',
            style: GoogleFonts.nunito(fontSize: 12.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // --- HIGH FIDELITY MOCK DIALOGS ---
  void _showReceiptDialog(BuildContext context, AdminSubmission sub) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Receipt Container
              Container(
                width: 300,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Receipt Jagged Edge Accent
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        15,
                        (index) => Container(
                          width: 12,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Receipt Content
                    Text(
                      sub.storeName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      'DUBAI BR., UAE\nTRN: 1003482910003\nTEL: 04-2983742',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '--------------------------------',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Products List
                    _receiptRow(sub.productName.toUpperCase(), sub.price),
                    if (sub.promoType == 'Discount')
                      _receiptRow('  PROMO DISCOUNT', -1.50, isDiscount: true),
                    _receiptRow('AL AIN WATER 6X1.5L', 8.50),
                    _receiptRow('AL BAKER CHAKKI ATTA 5K', 12.95),
                    const SizedBox(height: 8),
                    const Text(
                      '--------------------------------',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Totals
                    _receiptRow(
                      'SUBTOTAL',
                      sub.price +
                          8.50 +
                          12.95 +
                          (sub.promoType == 'Discount' ? -1.50 : 0),
                      isBold: true,
                    ),
                    _receiptRow(
                      '5% VAT INCL.',
                      (sub.price +
                              8.50 +
                              12.95 +
                              (sub.promoType == 'Discount' ? -1.50 : 0)) *
                          0.05,
                    ),
                    const SizedBox(height: 4),
                    _receiptRow(
                      'TOTAL',
                      sub.price +
                          8.50 +
                          12.95 +
                          (sub.promoType == 'Discount' ? -1.50 : 0),
                      isBold: true,
                      isLarge: true,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '--------------------------------',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'DATE: 2026-06-11 11:24\nCASHIER: AMIN\nOPID: 98324\nMODE: CASH',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Barcode Lines
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(24, (index) {
                        final double width = (index % 4 == 0)
                            ? 3.0
                            : (index % 2 == 0)
                            ? 1.5
                            : 0.8;
                        return Container(
                          width: width,
                          height: 30,
                          margin: const EdgeInsets.only(right: 1.5),
                          color: Colors.black87,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '*** THANK YOU FOR SHOPPING ***',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Close Button
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.white, size: 40),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _receiptRow(
    String name,
    double value, {
    bool isBold = false,
    bool isLarge = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isLarge ? 14 : 11,
                color: isDiscount ? Colors.red : Colors.black87,
              ),
            ),
          ),
          Text(
            value >= 0
                ? 'AED ${value.toStringAsFixed(2)}'
                : '-AED ${value.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isLarge ? 14 : 11,
              color: isDiscount ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showPricePhotoDialog(BuildContext context, AdminSubmission sub) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Simulated Supermarket Shelf Photo Container
              Container(
                width: 320,
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Shelf Visuals (Wood/Metal pattern)
                      Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              color: Colors.grey.shade300,
                              child: Center(
                                child: Icon(
                                  sub.productName.contains('Milk')
                                      ? Icons.local_cafe
                                      : sub.productName.contains('Eggs')
                                      ? Icons.egg
                                      : Icons.breakfast_dining,
                                  size: 84,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(color: Colors.blueGrey.shade800),
                          ),
                        ],
                      ),

                      // Product packaging model sitting on shelf
                      Positioned(
                        bottom: 45,
                        left: 110,
                        child: Container(
                          width: 100,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                sub.productName.contains('Milk')
                                    ? Icons.local_cafe
                                    : sub.productName.contains('Eggs')
                                    ? Icons.egg
                                    : Icons.breakfast_dining,
                                color: AppTheme.emeraldPrimary,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                sub.brand,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                sub.productName.split(' ').first,
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Price Tag sticker stuck to shelf strip
                      Positioned(
                        bottom: 8,
                        left: 60,
                        child: Container(
                          width: 200,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFDE7), // Yellow tag
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.amber.shade400,
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      sub.productName.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'BARCODE: 62911000${sub.id.hashCode.abs().toString().substring(0, 4)}',
                                      style: const TextStyle(
                                        fontSize: 5,
                                        fontFamily: 'monospace',
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'AED ${sub.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Shelf Label Overlay (e.g. Lulu / Carrefour)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sub.storeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Promo Indicator badge
                      if (sub.promoType != 'None')
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sub.promoType.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Close Button
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.white, size: 40),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
