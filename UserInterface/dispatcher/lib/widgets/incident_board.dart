import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../models/records.dart';
import 'common_widgets.dart';
import 'panel.dart';

class IncidentBoard extends StatelessWidget {
  const IncidentBoard({
    super.key,
    required this.incidents,
    required this.selectedIndex,
    required this.onSelect,
    required this.onCreateIncident,
  });

  final List<Incident> incidents;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreateIncident;

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'Dispatch Board',
      subtitle: 'Incidents, team coverage, and responder status.',
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
          final selected = index == selectedIndex;

          return InkWell(
            onTap: () => onSelect(index),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: selected ? AppPalette.selectedSurface : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? AppPalette.info : AppPalette.border,
                  width: selected ? 1.5 : 1,
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
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.text,
                          ),
                        ),
                      ),
                      StatusPill(
                        label: incident.active ? 'Active' : 'Resolved',
                        color: incident.active
                            ? AppPalette.success
                            : const Color(0xFF6D8197),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${incident.team} - ${incident.location}',
                    style: const TextStyle(
                      color: AppPalette.textSoft,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      MetricText(label: 'Responding', value: '$responding'),
                      MetricText(label: 'Pending', value: '$pending'),
                      MetricText(label: 'Created', value: incident.created),
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
