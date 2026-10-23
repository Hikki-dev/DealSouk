import 'package:flutter/material.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final sections = <(String, List<String>)>[
      (
        l.privacySummaryTitle,
        [
          l.privacySummaryItem1,
          l.privacySummaryItem2,
          l.privacySummaryItem3,
          l.privacySummaryItem4,
          l.privacySummaryItem5,
          l.privacySummaryItem6,
        ],
      ),
      (
        l.privacyCollectTitle,
        [
          l.privacyCollectItem1,
          l.privacyCollectItem2,
          l.privacyCollectItem3,
          l.privacyCollectItem4,
          l.privacyCollectItem5,
        ],
      ),
      (
        l.privacyUseTitle,
        [
          l.privacyUseItem1,
          l.privacyUseItem2,
          l.privacyUseItem3,
          l.privacyUseItem4,
          l.privacyUseItem5,
        ],
      ),
      (
        l.privacyChoicesTitle,
        [
          l.privacyChoicesItem1,
          l.privacyChoicesItem2,
          l.privacyChoicesItem3,
          l.privacyChoicesItem4,
        ],
      ),
      (
        l.privacyArabicTitle,
        [
          l.privacyArabicItem1,
          l.privacyArabicItem2,
          l.privacyArabicItem3,
          l.privacyArabicItem4,
        ],
      ),
      (
        l.privacyCreditsTitle,
        const [
          'Dubai Marina: Norlando Pobre, CC BY 2.0 (Wikimedia Commons).',
          'Vegetable market: Ithra Dubai, CC BY-SA 4.0 (Wikimedia Commons).',
          'Carrefour, UAE: CC BY-SA 4.0 (Wikimedia Commons, "Dates at Carrefour, UAE").',
          'Dubai Creek: public domain (Wikimedia Commons).',
          'Burj Khalifa and desert dunes: Wikimedia Commons, free licences.',
          'Maps: © Mapbox, © OpenStreetMap contributors.',
          'Supermarket names and logos belong to their owners.',
        ],
      ),
    ];
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: DsAppBar(title: l.privacyTitle),
      body: ListView(
        children: [
          PageContainer(
            maxWidth: 760,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              child: Column(
                children: [
                  for (final s in sections)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PolicySection(title: s.$1, items: s.$2),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: AppFonts.display(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 9, end: 10),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.forestDeep,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: AppFonts.body(
                        fontSize: 16,
                        height: 1.5,
                        color: AppTheme.ink,
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
}
