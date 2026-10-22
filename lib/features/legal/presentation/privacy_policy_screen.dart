import 'package:flutter/material.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          l.privacyTitle,
          style: const TextStyle(
            color: AppTheme.textDark,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.background,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _PolicySection(
            title: l.privacySummaryTitle,
            items: [
              l.privacySummaryItem1,
              l.privacySummaryItem2,
              l.privacySummaryItem3,
              l.privacySummaryItem4,
              l.privacySummaryItem5,
              l.privacySummaryItem6,
            ],
          ),
          _PolicySection(
            title: l.privacyCollectTitle,
            items: [
              l.privacyCollectItem1,
              l.privacyCollectItem2,
              l.privacyCollectItem3,
              l.privacyCollectItem4,
              l.privacyCollectItem5,
            ],
          ),
          _PolicySection(
            title: l.privacyUseTitle,
            items: [
              l.privacyUseItem1,
              l.privacyUseItem2,
              l.privacyUseItem3,
              l.privacyUseItem4,
              l.privacyUseItem5,
            ],
          ),
          _PolicySection(
            title: l.privacyChoicesTitle,
            items: [
              l.privacyChoicesItem1,
              l.privacyChoicesItem2,
              l.privacyChoicesItem3,
              l.privacyChoicesItem4,
            ],
          ),
          _PolicySection(
            title: l.privacyArabicTitle,
            items: [
              l.privacyArabicItem1,
              l.privacyArabicItem2,
              l.privacyArabicItem3,
              l.privacyArabicItem4,
            ],
          ),
          const _PolicySection(
            title: 'Photo and map credits',
            items: [
              'Dubai Marina: Norlando Pobre, CC BY 2.0 (Wikimedia Commons).',
              'Vegetable market: Ithra Dubai, CC BY-SA 4.0 (Wikimedia Commons).',
              'Carrefour, UAE: CC BY-SA 4.0 (Wikimedia Commons, "Dates at Carrefour, UAE").',
              'Dubai Creek: public domain (Wikimedia Commons).',
              'Maps: OpenStreetMap contributors.',
              'Supermarket names and logos belong to their owners.',
            ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '- ',
                    style: TextStyle(
                      color: AppTheme.forestDeep,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        height: 1.4,
                      ),
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
}
