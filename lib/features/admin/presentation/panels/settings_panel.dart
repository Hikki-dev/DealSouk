import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';

class SettingsPanel extends ConsumerWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(adminSettingsProvider);
    final notifier = ref.read(adminSettingsProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Token Economy Settings',
            style: GoogleFonts.fredoka(
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
                    style: GoogleFonts.nunito(
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
              style: GoogleFonts.nunito(
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
}
