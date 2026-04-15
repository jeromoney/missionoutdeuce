import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../models/records.dart';
import 'common_widgets.dart';
import 'panel.dart';

class IncidentBoard extends StatelessWidget {
  const IncidentBoard({
    super.key,
    required this.incidents,
    required this.teamNamesByPublicId,
    required this.selectedIndex,
    required this.onSelect,
    required this.onCreateIncident,
  });

  final List<Incident> incidents;
  final Map<String, String> teamNamesByPublicId;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreateIncident;

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'Dispatch Board',
      subtitle:
          'Open missions, team load, and responder acknowledgement state.',
      action: 'Create incident',
      primaryAction: true,
      onActionPressed: onCreateIncident,
      child: ListView.separated(
        itemCount: incidents.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final incident = incidents[index];
          final responding = incident.responses
              .where((response) => response.status == 'Responding')
              .length;
          final pending = incident.responses
              .where((response) => response.status == 'Pending')
              .length;
          final teamName =
              teamNamesByPublicId[incident.teamPublicId] ?? 'Assigned team';
          final selected = index == selectedIndex;

          return InkWell(
            onTap: () => onSelect(index),
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: selected
                    ? AppPalette.panelSoft
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected ? AppPalette.info : AppPalette.border,
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          incident.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: AppPalette.text,
                          ),
                        ),
                      ),
                      StatusPill(
                        label: incident.active ? 'Active' : 'Resolved',
                        color: incident.active
                            ? AppPalette.success
                            : AppPalette.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    teamName,
                    style: const TextStyle(
                      color: AppPalette.info,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    incident.location,
                    style: const TextStyle(
                      color: AppPalette.textSoft,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      MetricBadge(label: 'Responding', value: '$responding'),
                      MetricBadge(label: 'Pending', value: '$pending'),
                      MetricBadge(label: 'Created', value: incident.created),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
