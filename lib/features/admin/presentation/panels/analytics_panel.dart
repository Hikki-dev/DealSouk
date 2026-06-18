import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/network/file_download_helper.dart';
import 'package:dealsouk/features/admin/data/admin_service.dart';
import 'package:dealsouk/core/network/api_client.dart';

class AnalyticsPanel extends ConsumerStatefulWidget {
  const AnalyticsPanel({super.key});

  @override
  ConsumerState<AnalyticsPanel> createState() => _AnalyticsPanelState();
}

class _AnalyticsPanelState extends ConsumerState<AnalyticsPanel> {
  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(adminAnalyticsProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                'TODAY',
                '${analytics.submissionsToday}',
                Icons.today_rounded,
                Colors.green,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _statCard(
                'THIS MONTH',
                '${analytics.submissionsThisMonth}',
                Icons.calendar_month_rounded,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _statCard(
                'PENDING VOUCHERS',
                '${analytics.pendingVouchers}',
                Icons.confirmation_num_rounded,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _analyticsSection(
          title: 'Trending Products',
          emptyText: 'No product trends yet.',
          children: analytics.trendingProducts
              .map(
                (item) => _analyticsRow(
                  title: item.name,
                  subtitle: item.category,
                  value: '${item.submissions} submissions',
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        _analyticsSection(
          title: 'Coverage Hotspots',
          emptyText: 'No coverage data yet.',
          children: analytics.coverageAreas
              .map(
                (area) => _analyticsRow(
                  title: '${area.chain} ${area.branchName}'.trim(),
                  subtitle: area.area,
                  value: '${area.recentSubmissions} recent',
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EEE4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Exports & Reports',
                style: GoogleFonts.fredoka(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Downloading CSV...')),
                          );
                          final res = await apiClient.get(
                            '/admin/exports/submissions.csv',
                          );
                          final csvContent = res.data as String;
                          final bytes = csvContent.codeUnits;
                          await FileDownloadHelper.downloadFile(
                            bytes,
                            'dealsouk-submissions.csv',
                          );
                        } catch (err) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed to download CSV: $err'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.table_view_rounded),
                      label: const Text('Download CSV Report'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.forestDeep,
                        side: const BorderSide(color: AppTheme.forestDeep),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Generating Analytics PDF...'),
                            ),
                          );
                          final bytes = await adminService
                              .downloadAnalyticsPdf();
                          await FileDownloadHelper.downloadFile(
                            bytes,
                            'dealsouk-analytics.pdf',
                          );
                        } catch (err) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed to generate PDF: $err'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('Export PDF Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.forestDeep,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
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

  Widget _analyticsSection({
    required String title,
    required String emptyText,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            Text(emptyText, style: TextStyle(color: Colors.grey.shade600))
          else
            ...children,
        ],
      ),
    );
  }

  Widget _analyticsRow({
    required String title,
    required String subtitle,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.forestDeep,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
