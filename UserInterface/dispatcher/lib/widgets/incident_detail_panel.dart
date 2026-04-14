import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../models/records.dart';
import 'common_widgets.dart';
import 'panel.dart';

class IncidentDetailPanel extends StatelessWidget {
  const IncidentDetailPanel({
    super.key,
    required this.incident,
    required this.teamName,
    required this.responderNamesByPublicId,
    required this.onEditIncident,
  });

  final Incident incident;
  final String teamName;
  final Map<String, String> responderNamesByPublicId;
  final VoidCallback onEditIncident;

  @override
  Widget build(BuildContext context) {
    final ordered = [...incident.responses]
      ..sort((a, b) => a.rank.compareTo(b.rank));

    return Panel(
      title: 'Incident Detail',
      subtitle: 'Dispatch notes, responder roster, and mission context.',
      action: 'Edit incident',
      onActionPressed: onEditIncident,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppPalette.primary, AppPalette.panelSoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.title,
                  style: const TextStyle(
                    color: AppPalette.text,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  incident.notes,
                  style: const TextStyle(
                    color: AppPalette.headerText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    DarkChip(
                      icon: Icons.place_outlined,
                      text: incident.location,
                    ),
                    DarkChip(icon: Icons.groups_rounded, text: teamName),
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
                final responderName = _responderNameFor(response.userPublicId);
                final responderInitial = responderName.isEmpty
                    ? '?'
                    : responderName.substring(0, 1).toUpperCase();

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: responseColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: responseColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: responseColor,
                        foregroundColor: AppPalette.primary,
                        child: Text(responderInitial),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              responderName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppPalette.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Updated ${response.updated}',
                              style: const TextStyle(
                                color: AppPalette.textSoft,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
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
        return AppPalette.muted;
      default:
        return AppPalette.info;
    }
  }

  String _responderNameFor(String userPublicId) {
    final resolved = responderNamesByPublicId[userPublicId];
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
    }
    if (userPublicId.isEmpty) {
      return 'Unknown responder';
    }
    final end = userPublicId.length < 8 ? userPublicId.length : 8;
    return 'Responder ${userPublicId.substring(0, end)}';
  }
}
