import 'package:flutter/material.dart';

import '../app_palette.dart';
import 'common_widgets.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: SectionShell(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
                StatusPill(label: title, color: color),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              value,
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.4,
                color: AppPalette.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: AppPalette.textSoft, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
