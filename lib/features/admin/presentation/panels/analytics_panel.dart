import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/network/api_client.dart';
import 'package:dealsouk/core/network/file_download_helper.dart';
import 'package:dealsouk/features/admin/data/admin_service.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/features/admin/presentation/widgets/admin_panel_widgets.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

/// Admin analytics dashboard: trends, coverage, and CSV/PDF exports.
class AnalyticsPanel extends ConsumerWidget {
  const AnalyticsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final analytics = ref.watch(adminAnalyticsProvider);
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.7);

    Future<void> downloadCsv() async {
      try {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.anDownloadingCsv)));
        final res = await apiClient.get('/admin/exports/submissions.csv');
        final csvContent = res.data as String;
        await FileDownloadHelper.downloadFile(
          csvContent.codeUnits,
          'dealsouk-submissions.csv',
        );
      } catch (err) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.anFailed('$err'))));
      }
    }

    Future<void> downloadPdf() async {
      try {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.anGeneratingPdf)));
        final bytes = await adminService.downloadAnalyticsPdf();
        await FileDownloadHelper.downloadFile(bytes, 'dealsouk-analytics.pdf');
      } catch (err) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.anFailed('$err'))));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        AdaptiveGrid(
          minTileWidth: 150,
          spacing: 12,
          maxColumns: 3,
          mainAxisExtent: 112 * scale,
          children: [
            adminStatCard(
              l.anToday,
              '${analytics.submissionsToday}',
              Icons.today_rounded,
              AppTheme.good,
            ),
            adminStatCard(
              l.anMonth,
              '${analytics.submissionsThisMonth}',
              Icons.calendar_month_rounded,
              AppTheme.forestDeep,
            ),
            adminStatCard(
              l.anPendingVouchers,
              '${analytics.pendingVouchers}',
              Icons.confirmation_num_rounded,
              AppTheme.warnText,
            ),
          ],
        ),
        const SizedBox(height: 16),
        adminAnalyticsSection(
          title: l.anTrending,
          emptyText: l.anTrendingEmpty,
          children: analytics.trendingProducts
              .map(
                (item) => adminAnalyticsRow(
                  title: item.name,
                  subtitle: item.category,
                  value: l.anSubmissions(item.submissions),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        adminAnalyticsSection(
          title: l.anCoverage,
          emptyText: l.anCoverageEmpty,
          children: analytics.coverageAreas
              .map(
                (area) => adminAnalyticsRow(
                  title: '${area.chain} ${area.branchName}'.trim(),
                  subtitle: area.area,
                  value: l.anRecent(area.recentSubmissions),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        DsCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.anExports,
                style: AppFonts.display(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  DsButton(
                    label: l.anCsvBtn,
                    style: DsButtonStyle.secondary,
                    icon: Icons.table_view_rounded,
                    expanded: false,
                    onPressed: downloadCsv,
                  ),
                  DsButton(
                    label: l.anPdfBtn,
                    icon: Icons.picture_as_pdf_rounded,
                    expanded: false,
                    onPressed: downloadPdf,
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
