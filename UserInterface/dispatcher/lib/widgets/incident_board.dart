import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../app_palette.dart';
import '../l10n/generated/app_localizations.dart';
import '../mission_time_text.dart';
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
    final l10n = AppLocalizations.of(context);
    return Panel(
      title: l10n.dispatchBoardTitle,
      subtitle: l10n.dispatchBoardSubtitle,
      action: l10n.createIncidentButton,
      primaryAction: true,
      onActionPressed: onCreateIncident,
      child: ListView.separated(
        itemCount: incidents.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final incident = incidents[index];
          final responding = incident.responses
              .where((response) => response.status == ResponseStatus.responding)
              .length;
          final pending = incident.responses
              .where((response) => response.status == ResponseStatus.pending)
              .length;
          final teamName =
              teamNamesByPublicId[incident.teamPublicId] ??
              l10n.teamFallbackName;
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
                        label: incident.active
                            ? l10n.incidentStateActive
                            : l10n.incidentStateResolved,
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
                      MetricBadge(
                        label: l10n.responseStatus(
                          ResponseStatus.responding.name,
                        ),
                        value: '$responding',
                      ),
                      MetricBadge(
                        label: l10n.responseStatus(ResponseStatus.pending.name),
                        value: '$pending',
                      ),
                      MetricBadge(
                        label: l10n.metricCreatedLabel,
                        value: formatMissionTime(incident.created, context),
                      ),
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
