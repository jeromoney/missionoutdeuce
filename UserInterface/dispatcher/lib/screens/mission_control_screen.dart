import 'package:flutter/material.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_theme/shared_theme.dart';

import '../app_palette.dart';
import '../models/dashboard_snapshot.dart';
import '../models/incident_draft.dart';
import '../models/incident_update.dart';
import '../models/records.dart';
import '../services/mission_out_api.dart';
import '../widgets/common_widgets.dart';
import '../widgets/delivery_feed_panel.dart';
import '../widgets/incident_board.dart';
import '../widgets/incident_detail_panel.dart';
import '../widgets/summary_card.dart';
import 'create_incident_screen.dart';
import 'edit_incident_screen.dart';

class MissionControlScreen extends StatefulWidget {
  const MissionControlScreen({super.key, required this.auth});

  final AuthController auth;

  @override
  State<MissionControlScreen> createState() => _MissionControlScreenState();
}

class _MissionControlScreenState extends State<MissionControlScreen> {
  final api = MissionOutApi();

  List<Incident> incidents = const [];
  List<EventRecord> events = const [];
  Map<String, String> teamNamesByPublicId = const {};
  Map<String, String> responderNamesByPublicId = const {};
  var selected = 0;
  var loading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 1150;

    return Scaffold(
      body: MissionOutBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _Header(
                  role: widget.auth.roleLabel,
                  userInitials: widget.auth.currentUser?.initials ?? '--',
                  incidents: incidents,
                  onLogout: widget.auth.logout,
                ),
                if (loadError != null) ...[
                  const SizedBox(height: 16),
                  _LoadErrorBanner(message: loadError!),
                ],
                const SizedBox(height: 18),
                _SummaryStrip(incidents: incidents),
                const SizedBox(height: 18),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : incidents.isEmpty
                      ? _EmptyIncidentState(
                          message: loadError,
                          onCreateIncident: _openCreateIncident,
                        )
                      : _buildDashboardLayout(compact),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardLayout(bool compact) {
    final incident = incidents[selected];

    if (compact) {
      return ListView(
        children: [
          SizedBox(
            height: 440,
            child: IncidentBoard(
              incidents: incidents,
              teamNamesByPublicId: teamNamesByPublicId,
              selectedIndex: selected,
              onSelect: _selectIncident,
              onCreateIncident: _openCreateIncident,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 580,
            child: IncidentDetailPanel(
              incident: incident,
              teamName: _teamNameFor(incident.teamPublicId),
              responderNamesByPublicId: responderNamesByPublicId,
              onEditIncident: _openEditIncident,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 380, child: DeliveryFeedPanel(events: events)),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 7,
          child: IncidentBoard(
            incidents: incidents,
            teamNamesByPublicId: teamNamesByPublicId,
            selectedIndex: selected,
            onSelect: _selectIncident,
            onCreateIncident: _openCreateIncident,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: IncidentDetailPanel(
            incident: incident,
            teamName: _teamNameFor(incident.teamPublicId),
            responderNamesByPublicId: responderNamesByPublicId,
            onEditIncident: _openEditIncident,
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(width: 340, child: DeliveryFeedPanel(events: events)),
      ],
    );
  }

  Future<void> _loadDashboard() async {
    setState(() {
      loading = true;
      loadError = null;
    });

    try {
      final DashboardSnapshot snapshot = await api.fetchDashboard(
        userEmail: widget.auth.currentUser?.email,
        memberships: widget.auth.currentUser?.teamMemberships ?? const [],
      );

      if (!mounted) {
        return;
      }

      setState(() {
        incidents = snapshot.incidents;
        events = snapshot.events;
        teamNamesByPublicId = snapshot.teamNamesByPublicId;
        responderNamesByPublicId = snapshot.responderNamesByPublicId;
        selected = 0;
        loading = false;
      });
    } catch (error) {
      debugPrint(
        '[Dispatcher] Dashboard load failed: baseUrl=${api.baseUrl}, error=$error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        incidents = const [];
        events = const [];
        teamNamesByPublicId = const {};
        responderNamesByPublicId = const {};
        selected = 0;
        loading = false;
        loadError = 'Could not load incident data.';
      });
    }
  }

  String _teamNameFor(String teamPublicId) {
    return teamNamesByPublicId[teamPublicId] ?? 'Assigned team';
  }

  void _selectIncident(int index) {
    setState(() => selected = index);
  }

  Future<void> _openCreateIncident() async {
    final draft = await Navigator.of(context).push<IncidentDraft>(
      MaterialPageRoute(builder: (_) => const CreateIncidentScreen()),
    );

    if (!mounted || draft == null) {
      return;
    }

    try {
      final memberships = widget.auth.currentUser?.teamMemberships ?? const [];
      final teamPublicId = memberships.isNotEmpty
          ? memberships.first.teamPublicId
          : '';
      if (teamPublicId.isEmpty) {
        throw Exception(
          'No team_public_id available for dispatcher incident creation.',
        );
      }
      final newIncident = await api.createIncident(
        draft,
        teamPublicId: teamPublicId,
        userEmail: widget.auth.currentUser?.email,
      );
      debugPrint(
        '[Dispatcher] Incident created: public_id=${newIncident.publicId}, title=${newIncident.title}',
      );
      if (!mounted) {
        return;
      }

      setState(() {
        incidents = [newIncident, ...incidents];
        selected = 0;
      });
    } catch (error) {
      debugPrint('[Dispatcher] Could not create incident: $error');
      if (!mounted) {
        return;
      }
    }
  }

  Future<void> _openEditIncident() async {
    if (incidents.isEmpty) {
      return;
    }

    final update = await Navigator.of(context).push<IncidentUpdate>(
      MaterialPageRoute(
        builder: (_) => EditIncidentScreen(incident: incidents[selected]),
      ),
    );

    if (!mounted || update == null) {
      return;
    }

    try {
      final updatedIncident = await api.updateIncident(
        incidents[selected].publicId,
        update,
      );
      debugPrint(
        '[Dispatcher] Incident updated: public_id=${updatedIncident.publicId}, title=${updatedIncident.title}',
      );
      if (!mounted) {
        return;
      }

      setState(() {
        incidents = [
          for (var index = 0; index < incidents.length; index++)
            if (index == selected) updatedIncident else incidents[index],
        ];
      });
    } catch (error) {
      debugPrint('[Dispatcher] Could not save incident changes: $error');
      if (!mounted) {
        return;
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.role,
    required this.userInitials,
    required this.incidents,
    required this.onLogout,
  });

  final String role;
  final String userInitials;
  final List<Incident> incidents;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final active = incidents.where((incident) => incident.active).length;
    final responders = incidents.fold<int>(
      0,
      (sum, incident) =>
          sum +
          incident.responses
              .where((response) => response.status == 'Responding')
              .length,
    );

    return SectionShell(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 620,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MissionOutBrandLockup(
                  subtitle:
                      'Mission control for recent dispatch activity, team visibility, and live responder coordination.',
                  logoSize: 60,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [StatusPill(label: role, color: AppPalette.info)],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MetricBadge(label: 'Active', value: '$active'),
                  const SizedBox(width: 12),
                  MetricBadge(label: 'Responding', value: '$responders'),
                  const SizedBox(width: 12),
                  PopupMenuButton<String>(
                    tooltip: 'Account',
                    color: AppPalette.panelSoft,
                    onSelected: (value) {
                      if (value == 'logout') {
                        onLogout();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Text('Log out'),
                      ),
                    ],
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppPalette.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        userInitials,
                        style: const TextStyle(
                          color: AppPalette.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.incidents});

  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) {
    final active = incidents.where((incident) => incident.active).length;
    final responding = incidents.fold<int>(
      0,
      (sum, incident) =>
          sum +
          incident.responses
              .where((response) => response.status == 'Responding')
              .length,
    );
    final pending = incidents.fold<int>(
      0,
      (sum, incident) =>
          sum +
          incident.responses
              .where((response) => response.status == 'Pending')
              .length,
    );

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SummaryCard(
          title: 'Active',
          value: '$active',
          subtitle: 'Open incidents from the last 7 days in the current feed.',
          icon: Icons.radar_rounded,
          color: AppPalette.info,
        ),
        SummaryCard(
          title: 'Responding',
          value: '$responding',
          subtitle:
              'Confirmed field responders across the recent incident feed.',
          icon: Icons.hiking_rounded,
          color: AppPalette.success,
        ),
        SummaryCard(
          title: 'Pending',
          value: '$pending',
          subtitle:
              'Awaiting acknowledgement in the last-7-days incident feed.',
          icon: Icons.notifications_active_outlined,
          color: AppPalette.muted,
        ),
      ],
    );
  }
}

class _EmptyIncidentState extends StatelessWidget {
  const _EmptyIncidentState({required this.onCreateIncident, this.message});

  final VoidCallback onCreateIncident;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SectionShell(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MissionOutLogo(size: 78),
              const SizedBox(height: 20),
              const Text(
                'No active incidents yet',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: AppPalette.text,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCreateIncident,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create incident'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadErrorBanner extends StatelessWidget {
  const _LoadErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SectionShell(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: MissionOutColors.alertRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: MissionOutColors.alertRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
