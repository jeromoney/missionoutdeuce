import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../models/records.dart';
import 'common_widgets.dart';
import 'panel.dart';

class IncidentDetailPanel extends StatelessWidget {
  const IncidentDetailPanel({
    super.key,
    required this.incident,
    required this.onEditIncident,
  });

  final Incident incident;
  final VoidCallback onEditIncident;

  @override
  Widget build(BuildContext context) {
    final ordered = [...incident.responses]
      ..sort((a, b) => a.rank.compareTo(b.rank));

    return Panel(
      title: 'Incident Detail',
      subtitle: 'Dispatch notes, response roster, and mission context.',
      action: 'Edit incident',
      onActionPressed: onEditIncident,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppPalette.primary,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  incident.notes,
                  style: const TextStyle(
                    color: AppPalette.headerText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    DarkChip(
                      icon: Icons.place_outlined,
                      text: incident.location,
                    ),
                    DarkChip(
                      icon: Icons.groups_rounded,
                      text: incident.team,
                    ),
                    DarkChip(
                      icon: Icons.schedule_rounded,
                      text: incident.created,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: ordered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final response = ordered[index];
                final responseColor = _responseColor(response.status);
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: responseColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: responseColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: responseColor,
                        foregroundColor: Colors.white,
                        child: Text(response.name.substring(0, 1)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              response.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppPalette.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              response.detail,
                              style: const TextStyle(
                                color: AppPalette.textSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusPill(label: response.status, color: responseColor),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _responseColor(String status) {
    switch (status) {
      case 'Responding':
        return AppPalette.success;
      case 'Not Available':
        return const Color(0xFF7A8EA5);
      default:
        return AppPalette.muted;
    }
  }
}
