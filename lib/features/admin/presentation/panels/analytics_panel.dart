import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/network/api_client.dart';
import 'package:dealsouk/core/network/file_download_helper.dart';
import 'package:dealsouk/features/admin/data/admin_service.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/features/admin/presentation/widgets/admin_panel_widgets.dart';

/// Admin analytics dashboard (R1): trends, coverage, and CSV/PDF exports.
/// Self-contained ConsumerWidget lifted verbatim from the admin_screen State.
class AnalyticsPanel extends ConsumerWidget {
  const AnalyticsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(adminAnalyticsProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: adminStatCard(
                'TODAY',
                '${analytics.submissionsToday}',
                Icons.today_rounded,
                Colors.green,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: adminStatCard(
                'THIS MONTH',
                '${analytics.submissionsThisMonth}',
                Icons.calendar_month_rounded,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: adminStatCard(
                'PENDING VOUCHERS',
                '${analytics.pendingVouchers}',
                Icons.confirmation_num_rounded,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        adminAnalyticsSection(
          title: 'Trending Products',
          emptyText: 'No product trends yet.',
          children: analytics.trendingProducts
              .map(
                (item) => adminAnalyticsRow(
                  title: item.name,
                  subtitle: item.category,
                  value: '${item.submissions} submissions',
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        adminAnalyticsSection(
          title: 'Coverage Hotspots',
          emptyText: 'No coverage data yet.',
          children: analytics.coverageAreas
              .map(
                (area) => adminAnalyticsRow(
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
                style: AppFonts.display(
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
                        try {
                          ScaffoldMessenger.of(context).showSnackBar(
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
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
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
                        try {
                          ScaffoldMessenger.of(context).showSnackBar(
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
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
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
}
