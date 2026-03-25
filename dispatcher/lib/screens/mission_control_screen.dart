import 'package:flutter/material.dart';
import 'package:shared_auth/shared_auth.dart';

import '../app_palette.dart';
import '../models/incident_draft.dart';
import '../models/dashboard_snapshot.dart';
import '../models/incident_update.dart';
import '../models/records.dart';
import 'create_incident_screen.dart';
import 'edit_incident_screen.dart';
import '../services/mission_out_api.dart';
import '../widgets/delivery_feed_panel.dart';
import '../widgets/incident_board.dart';
import '../widgets/incident_detail_panel.dart';
import '../widgets/common_widgets.dart';
import '../widgets/summary_card.dart';

class MissionControlScreen extends StatefulWidget {
  const MissionControlScreen({
    super.key,
    required this.auth,
  });

  final AuthController auth;

  @override
  State<MissionControlScreen> createState() => _MissionControlScreenState();
}

class _MissionControlScreenState extends State<MissionControlScreen> {
  final api = MissionOutApi();

  List<Incident> incidents = const [];
  List<EventRecord> events = const [];
  var selected = 0;
  var loading = true;
  String? statusMessage;

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppPalette.gradientTop, AppPalette.gradientBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _Header(
                  role: widget.auth.roleLabel,
                  userInitials: widget.auth.currentUser?.initials ?? '--',
                  onLogout: widget.auth.logout,
                ),
                const SizedBox(height: 16),
                if (statusMessage != null) ...[
                  _StatusBanner(message: statusMessage!),
                  const SizedBox(height: 16),
                ],
                _SummaryStrip(incidents: incidents),
                const SizedBox(height: 16),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : incidents.isEmpty
                          ? _EmptyIncidentState(
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
            height: 420,
            child: IncidentBoard(
              incidents: incidents,
              selectedIndex: selected,
              onSelect: _selectIncident,
              onCreateIncident: _openCreateIncident,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 560,
            child: IncidentDetailPanel(
              incident: incident,
              onEditIncident: _openEditIncident,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 360,
            child: DeliveryFeedPanel(events: events),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 7,
          child: IncidentBoard(
            incidents: incidents,
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
            onEditIncident: _openEditIncident,
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 340,
          child: DeliveryFeedPanel(events: events),
        ),
      ],
    );
  }

  Future<void> _loadDashboard() async {
    setState(() {
      loading = true;
      statusMessage = null;
    });

    final DashboardSnapshot snapshot = await api.fetchDashboard();

    if (!mounted) {
      return;
    }

    setState(() {
      incidents = snapshot.incidents;
      events = snapshot.events;
      selected = 0;
      loading = false;
      if (snapshot.usingFallback) {
        statusMessage =
            'FastAPI unavailable. Showing demo data from local fallback.';
      } else {
        statusMessage = 'Connected to FastAPI at runtime.';
      }
    });
  }

  void _selectIncident(int index) {
    setState(() {
      selected = index;
    });
  }

  Future<void> _openCreateIncident() async {
    final draft = await Navigator.of(context).push<IncidentDraft>(
      MaterialPageRoute(
        builder: (_) => const CreateIncidentScreen(),
      ),
    );

    if (!mounted || draft == null) {
      return;
    }

      setState(() {
        statusMessage = 'Creating incident...';
      });

    try {
      final newIncident = await api.createIncident(draft);
      if (!mounted) {
        return;
      }

      setState(() {
        incidents = [newIncident, ...incidents];
        selected = 0;
        statusMessage = 'Incident created and saved to the backend.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        statusMessage = 'Could not create incident: $error';
      });
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

    setState(() {
      statusMessage = 'Saving incident changes...';
    });

    final selectedIncident = incidents[selected];

    try {
      final updatedIncident = await api.updateIncident(
        selectedIncident.id,
        update,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        incidents = [
          for (var index = 0; index < incidents.length; index++)
            if (index == selected) updatedIncident else incidents[index],
        ];
        statusMessage = 'Incident changes saved to the backend.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        statusMessage = 'Could not save incident changes: $error';
      });
    }
  }
}

class _EmptyIncidentState extends StatelessWidget {
  const _EmptyIncidentState({
    required this.onCreateIncident,
  });

  final VoidCallback onCreateIncident;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppPalette.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.campaign_outlined,
              size: 44,
              color: AppPalette.info,
            ),
            const SizedBox(height: 16),
            const Text(
              'No incidents yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppPalette.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create the first incident to start the dispatcher workflow and populate the response board.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppPalette.textSoft,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreateIncident,
              icon: const Icon(Icons.add_rounded),
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.info,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
              ),
              label: const Text('Create incident'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppPalette.textSoft,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.role,
    required this.userInitials,
    required this.onLogout,
  });

  final String role;
  final String userInitials;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MissionOut',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Web mission board for dispatch, team visibility, and live SAR response tracking.',
                style: TextStyle(
                  color: AppPalette.headerText,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                tooltip: 'Account',
                color: Colors.white,
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    userInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const StatusPill(
                label: 'System Healthy',
                color: Color(0xFF2F8F63),
              ),
              const SizedBox(width: 12),
              StatusPill(label: role, color: AppPalette.muted),
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
          title: 'Active incidents',
          value: '$active',
          subtitle: 'mission windows currently open',
          icon: Icons.campaign_rounded,
          color: AppPalette.info,
        ),
        SummaryCard(
          title: 'Responding',
          value: '$responding',
          subtitle: 'confirmed field responders',
          icon: Icons.hiking_rounded,
          color: AppPalette.success,
        ),
        SummaryCard(
          title: 'Pending',
          value: '$pending',
          subtitle: 'still awaiting acknowledgement',
          icon: Icons.timer_outlined,
          color: AppPalette.muted,
        ),
      ],
    );
  }
}
