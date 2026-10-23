// Shared admin-panel UI builders (R1 step 1). Extracted verbatim from the
// admin_screen State so panels can be split into separate widgets without
// duplicating these pure, stateless builders.
import 'package:flutter/material.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';

Widget adminStatCard(String label, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.body(
                  fontSize: 14,
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, color: color, size: 22),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            style: AppFonts.display(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              height: 1.0,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget adminAnalyticsSection({
  required String title,
  required String emptyText,
  required List<Widget> children,
}) {
  return DsCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFonts.display(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        if (children.isEmpty)
          Text(
            emptyText,
            style: AppFonts.body(fontSize: 15, color: AppTheme.textLight),
          )
        else
          ...children,
      ],
    ),
  );
}

Widget adminAnalyticsRow({
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
                style: AppFonts.body(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              Text(
                subtitle,
                style: AppFonts.body(fontSize: 14, color: AppTheme.textLight),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        DsTag(value, tone: DsTone.teal),
      ],
    ),
  );
}
