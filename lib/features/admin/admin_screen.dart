import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingSubs = ref.watch(adminSubmissionsProvider);
    final int pendingCount = pendingSubs.length;

    // Reactively adjust other dashboard stats
    final int approvedCount = 48 + (3 - pendingCount);
    final int tokensIssuedCount = 18450 + ((3 - pendingCount) * 15);

    // Initialize or correct the selected submission
    if (pendingSubs.isNotEmpty) {
      if (_selectedSubId == null || !pendingSubs.any((s) => s.id == _selectedSubId)) {
        _selectedSubId = pendingSubs.first.id;
      }
    } else {
      _selectedSubId = null;
    }

    final currentSub = _selectedSubId != null
        ? pendingSubs.firstWhere((s) => s.id == _selectedSubId, orElse: () => pendingSubs.first)
        : null;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 768;
          if (isDesktop) {
            return _buildDesktopLayout(context, theme, pendingSubs, currentSub, pendingCount, approvedCount, tokensIssuedCount);
          } else {
            return _buildMobileLayout(context, theme, pendingSubs, pendingCount, approvedCount, tokensIssuedCount);
          }
        },
      ),
    );
  }

  // --- DESKTOP SPLIT SAAS LAYOUT ---
  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    List<AdminSubmission> pendingSubs,
    AdminSubmission? currentSub,
    int pendingCount,
    int approvedCount,
    int tokensIssuedCount,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column (Dashboard stats + Pending queue list)
        Expanded(
          flex: 5,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.security, color: Colors.red.shade800, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'SaaS Moderator Console',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Audit Dashboard',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Sync Queue'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              minimumSize: Size.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Horizontal Grid for stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(child: _statCard('PENDING REVIEWS', '$pendingCount', Icons.hourglass_empty, Colors.orange, theme)),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('APPROVED TODAY', '$approvedCount', Icons.check_circle_outline, Colors.green, theme)),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('ACTIVE SOURCE FLOW', '1,240', Icons.people_outline, Colors.blue, theme)),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('TOKENS ISSUED', '$tokensIssuedCount', Icons.bolt, Colors.amber, theme)),
                    ],
                  ),
                ),
              ),

              // Pending Submissions Queue
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 8.0),
                  child: Text(
                    'Submissions Queue ($pendingCount)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textDark),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: pendingSubs.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyQueueCard())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final sub = pendingSubs[index];
                            final isSelected = sub.id == _selectedSubId;
                            return _buildSubmissionCard(context, sub, isSelected, true);
                          },
                          childCount: pendingSubs.length,
                        ),
                      ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
        ),

        // Vertical Separator
        VerticalDivider(width: 1, color: Colors.grey.shade200),

        // Right Column (Sticky Quick Audit detail sidebar panel)
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(20),
            child: currentSub == null
                ? _buildSidebarIdleState()
                : _buildSidebarAuditState(context, currentSub),
          ),
        )
      ],
    );
  }

  // --- MOBILE SINGLE COLUMN LAYOUT ---
  Widget _buildMobileLayout(
    BuildContext context,
    ThemeData theme,
    List<AdminSubmission> pendingSubs,
    int pendingCount,
    int approvedCount,
    int tokensIssuedCount,
  ) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.security, color: Colors.red.shade800, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Admin Portal',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Moderation Deck',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {},
                )
              ],
            ),
          ),
        ),

        // Statistics Grid Deck
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _statCard('Pending Reviews', '$pendingCount', Icons.hourglass_top, Colors.orange, theme),
                _statCard('Approved Today', '$approvedCount', Icons.check_circle_outline, Colors.green, theme),
                _statCard('Active Users', '1,240', Icons.people_outline, Colors.blue, theme),
                _statCard('Tokens Issued', '$tokensIssuedCount', Icons.bolt, Colors.amber, theme),
              ],
            ),
          ),
        ),

        // Pending Submissions Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
            child: Text(
              'Pending Price Reviews ($pendingCount)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // List
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
        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  // --- REUSABLE CARD WIDGETS ---
  Widget _buildEmptyQueueCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
        child: Column(
          children: [
            Icon(Icons.verified, color: Colors.green.shade400, size: 54),
            const SizedBox(height: 16),
            const Text(
              'All Clean!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'There are no pending price submissions left to moderate.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(BuildContext context, AdminSubmission sub, bool isSelected, bool isDesktop) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.grey.shade200,
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                        Text(
                          sub.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Brand: ${sub.brand} • Store: ${sub.storeName}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'AED ${sub.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  )
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
                        icon: Icons.camera_alt,
                        label: 'Price Photo',
                        isAttached: sub.hasPhoto,
                        onTap: sub.hasPhoto ? () => _showPricePhotoDialog(context, sub) : null,
                      ),
                      const SizedBox(width: 8),
                      _attachmentChip(
                        icon: Icons.receipt_long,
                        label: 'Receipt',
                        isAttached: sub.hasReceipt,
                        onTap: sub.hasReceipt ? () => _showReceiptDialog(context, sub) : null,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.amberLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Reward: +${sub.tokensReward}T',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: Color(0xFFC77C02),
                      ),
                    ),
                  )
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _approve(sub.id, sub),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  // --- RIGHT SIDEBAR DETAILS PANEL ---
  Widget _buildSidebarIdleState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory, color: Colors.grey, size: 48),
          SizedBox(height: 12),
          Text(
            'System Idle',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Text(
            'All submissions moderated.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarAuditState(BuildContext context, AdminSubmission sub) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Submission Review',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                'PENDING',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.orange.shade800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'ID: ${sub.id}  ·  Submitted ${sub.timestampLabel}',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Visual Thumbnail previews of attachments
        const Text(
          'Evidence — tap to expand:',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: sub.hasPhoto ? () => _showPricePhotoDialog(context, sub) : null,
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: sub.hasPhoto ? Colors.blue.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sub.hasPhoto ? Colors.blue.shade200 : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: sub.hasPhoto ? Colors.blue.shade700 : Colors.grey.shade400,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sub.hasPhoto ? 'Price Tag Pic' : 'No Photo',
                        style: TextStyle(
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
                  height: 90,
                  decoration: BoxDecoration(
                    color: sub.hasReceipt ? Colors.teal.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sub.hasReceipt ? Colors.teal.shade200 : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: sub.hasReceipt ? Colors.teal.shade700 : Colors.grey.shade400,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sub.hasReceipt ? 'Receipt Scan' : 'No Receipt',
                        style: TextStyle(
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
        const SizedBox(height: 20),

        // Guidelines Checklist
        const Divider(height: 1),
        const SizedBox(height: 16),
        const Text(
          'Moderator Checklist',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        _auditCheckItem('Confirm receipt matches store: ${sub.storeName}', true),
        _auditCheckItem('Validate price matches packaging size', true),
        _auditCheckItem('Double-check for discount/promo tags', sub.promoType != 'None'),
        _auditCheckItem('Freshness: Check receipt timestamp matches', sub.hasReceipt),
        const Spacer(),

        // Audit health KPI
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.health_and_safety_outlined, color: Colors.green.shade700, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Audit Health Score',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    Text(
                      'Historical match accuracy',
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Text(
                '98.4%',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

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
                ),
                child: const Text('Reject'),
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
                ),
                child: const Text('Approve'),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _auditCheckItem(String label, bool initialVal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            initialVal ? Icons.check_circle_outline : Icons.help_outline,
            color: initialVal ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
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
        content: Text('Submission approved! ${sub.tokensReward} tokens awarded to Hessa.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _reject(String id) {
    ref.read(adminSubmissionsProvider.notifier).rejectSubmission(id);
    _selectNextAfterRemoval(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Submission rejected.'),
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

  // --- STAT CARD ---
  Widget _statCard(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentChip({
    required IconData icon,
    required String label,
    required bool isAttached,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isAttached ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isAttached ? Colors.green.shade200 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAttached ? Icons.check : icon,
              color: isAttached ? Colors.green.shade800 : Colors.grey.shade600,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isAttached ? Colors.green.shade900 : Colors.grey.shade600,
              ),
            ),
            if (isAttached && onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.open_in_new, size: 8, color: Colors.green.shade700),
            ],
          ],
        ),
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
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    )
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
                      style: TextStyle(fontFamily: 'monospace', color: Colors.grey),
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
                      style: TextStyle(fontFamily: 'monospace', color: Colors.grey),
                    ),
                    const SizedBox(height: 8),

                    // Totals
                    _receiptRow('SUBTOTAL', sub.price + 8.50 + 12.95 + (sub.promoType == 'Discount' ? -1.50 : 0), isBold: true),
                    _receiptRow('5% VAT INCL.', (sub.price + 8.50 + 12.95 + (sub.promoType == 'Discount' ? -1.50 : 0)) * 0.05),
                    const SizedBox(height: 4),
                    _receiptRow('TOTAL', sub.price + 8.50 + 12.95 + (sub.promoType == 'Discount' ? -1.50 : 0), isBold: true, isLarge: true),
                    const SizedBox(height: 12),
                    const Text(
                      '--------------------------------',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'monospace', color: Colors.grey),
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
                        final double width = (index % 4 == 0) ? 3.0 : (index % 2 == 0) ? 1.5 : 0.8;
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

  Widget _receiptRow(String name, double value, {bool isBold = false, bool isLarge = false, bool isDiscount = false}) {
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
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    )
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
                            child: Container(
                              color: Colors.blueGrey.shade800,
                            ),
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
                              )
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textDark),
                              ),
                              Text(
                                sub.productName.split(' ').first,
                                style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFDE7), // Yellow tag
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber.shade400, width: 1.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              )
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
                                      style: const TextStyle(fontSize: 5, fontFamily: 'monospace', color: Colors.black54),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sub.storeName,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      // Promo Indicator badge
                      if (sub.promoType != 'None')
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
