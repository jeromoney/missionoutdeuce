import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_auth/shared_auth.dart';

import '../app_palette.dart';
import '../data/demo_data.dart';
import '../models/backup_alert.dart';
import '../models/incident.dart';
import '../services/backup_notification_service.dart';
import '../services/browser_notification_gateway.dart';

class ResponderHomeScreen extends StatefulWidget {
  const ResponderHomeScreen({
    super.key,
    required this.auth,
  });

  final AuthController auth;

  @override
  State<ResponderHomeScreen> createState() => _ResponderHomeScreenState();
}

class _ResponderHomeScreenState extends State<ResponderHomeScreen> {
  final incidents = responderIncidents;
  final backupNotifications = BackupNotificationService();
  int selected = 0;
  String availability = 'Available';
  StreamSubscription<BackupAlert>? alertSubscription;
  BackupAlert? activeBackupAlert;

  @override
  void initState() {
    super.initState();
    backupNotifications.initialize();
    alertSubscription = backupNotifications.alerts.listen((alert) {
      if (!mounted) {
        return;
      }

      setState(() {
        selected = alert.incidentIndex;
        activeBackupAlert = alert;
      });
    });
  }

  @override
  void dispose() {
    alertSubscription?.cancel();
    backupNotifications.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 1000;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [ResponderPalette.surface, Color(0xFFDDE8F3)],
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
                  userInitials: widget.auth.currentUser?.initials ?? '--',
                  availability: availability,
                  onAvailabilityChanged: _changeAvailability,
                  onLogout: widget.auth.logout,
                ),
                const SizedBox(height: 16),
                _BackupNotificationBanner(
                  service: backupNotifications,
                  alert: activeBackupAlert,
                  onEnableNotifications: backupNotifications.requestPermission,
                  onDismissAlert: () {
                    setState(() => activeBackupAlert = null);
                  },
                  onOpenAlert: () {
                    if (activeBackupAlert == null) {
                      return;
                    }
                    setState(() {
                      selected = activeBackupAlert!.incidentIndex;
                      activeBackupAlert = null;
                    });
                  },
                  onSendTestAlert: incidents.isEmpty
                      ? null
                      : () => backupNotifications.sendTestAlert(
                            incidentIndex: selected,
                            incident: incidents[selected],
                          ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: incidents.isEmpty
                      ? const _NoMissionState()
                      : compact
                          ? ListView(
                              children: [
                                SizedBox(
                                  height: 320,
                                  child: _MissionList(
                                    incidents: incidents,
                                    selected: selected,
                                    onSelected: (index) {
                                      setState(() => selected = index);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 560,
                                  child: _IncidentCard(
                                    incident: incidents[selected],
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                SizedBox(
                                  width: 360,
                                  child: _MissionList(
                                    incidents: incidents,
                                    selected: selected,
                                    onSelected: (index) {
                                      setState(() => selected = index);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _IncidentCard(
                                    incident: incidents[selected],
                                  ),
                                ),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _changeAvailability(String value) async {
    if (availability == 'Available' && value == 'Unavailable') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Go unavailable?'),
          content: const Text(
            'If you switch to unavailable, you will not receive alerts until you change your status back.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Go unavailable'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) {
        return;
      }
    }

    setState(() => availability = value);
  }
}

class _BackupNotificationBanner extends StatelessWidget {
  const _BackupNotificationBanner({
    required this.service,
    required this.alert,
    required this.onEnableNotifications,
    required this.onDismissAlert,
    required this.onOpenAlert,
    required this.onSendTestAlert,
  });

  final BackupNotificationService service;
  final BackupAlert? alert;
  final Future<void> Function() onEnableNotifications;
  final VoidCallback onDismissAlert;
  final VoidCallback onOpenAlert;
  final Future<void> Function()? onSendTestAlert;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final permissionLabel = switch (service.permissionState) {
          BrowserNotificationPermissionState.granted => 'Enabled',
          BrowserNotificationPermissionState.denied => 'Blocked',
          BrowserNotificationPermissionState.unsupported => 'Unsupported',
          BrowserNotificationPermissionState.notDetermined => 'Not enabled',
        };

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: ResponderPalette.border),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 480,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Web Backup Notifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ResponderPalette.text,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(
                          label: permissionLabel,
                          color: service.isGranted
                              ? ResponderPalette.success
                              : ResponderPalette.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert != null
                          ? 'Incoming backup alert: ${alert!.title}'
                          : 'Browser notifications are supplemental only. Use them for backup awareness and testing, not primary paging.',
                      style: const TextStyle(
                        color: ResponderPalette.textSoft,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (alert != null)
                    FilledButton.tonal(
                      onPressed: onOpenAlert,
                      child: const Text('Open alert'),
                    ),
                  if (alert != null)
                    TextButton(
                      onPressed: onDismissAlert,
                      child: const Text('Dismiss'),
                    ),
                  if (!service.isGranted &&
                      service.permissionState !=
                          BrowserNotificationPermissionState.unsupported)
                    FilledButton(
                      onPressed: onEnableNotifications,
                      style: FilledButton.styleFrom(
                        backgroundColor: ResponderPalette.accent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Enable notifications'),
                    ),
                  if (onSendTestAlert != null)
                    OutlinedButton(
                      onPressed: onSendTestAlert,
                      child: const Text('Send test alert'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MissionList extends StatelessWidget {
  const _MissionList({
    required this.incidents,
    required this.selected,
    required this.onSelected,
  });

  final List<ResponderIncident> incidents;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ResponderPalette.card.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ResponderPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Missions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ResponderPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review active incidents and select one to update your response.',
            style: TextStyle(color: ResponderPalette.textSoft),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: incidents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final incident = incidents[index];
                final isSelected = index == selected;

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onSelected(index),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFDDE8F3)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? ResponderPalette.accent
                            : ResponderPalette.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ResponderPalette.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          incident.location,
                          style: const TextStyle(
                            color: ResponderPalette.textSoft,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _StatusPill(
                              label: incident.status,
                              color: incident.status == 'Responding'
                                  ? ResponderPalette.success
                                  : ResponderPalette.warning,
                            ),
                            const Spacer(),
                            Text(
                              incident.timeLabel,
                              style: const TextStyle(
                                color: ResponderPalette.textSoft,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMissionState extends StatelessWidget {
  const _NoMissionState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: ResponderPalette.card.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: ResponderPalette.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0F8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 36,
                color: ResponderPalette.accent,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No active mission',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: ResponderPalette.text,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You are currently clear. When a new incident is dispatched, it will appear here with your responder actions and mission notes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ResponderPalette.textSoft,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ResponderPalette.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Standing by',
                style: TextStyle(
                  color: ResponderPalette.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.userInitials,
    required this.availability,
    required this.onAvailabilityChanged,
    required this.onLogout,
  });

  final String userInitials;
  final String availability;
  final ValueChanged<String> onAvailabilityChanged;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ResponderPalette.primary,
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
                'MissionOut Responder',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Responder view for acknowledgements, readiness, and active mission context.',
                style: TextStyle(
                  color: Color(0xFFD9E7F5),
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
              _StatusPill(
                label: availability,
                color: availability == 'Available'
                    ? ResponderPalette.success
                    : ResponderPalette.warning,
              ),
              const SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: availability,
                  dropdownColor: ResponderPalette.primary,
                  style: const TextStyle(color: Colors.white),
                  iconEnabledColor: Colors.white,
                  items: const ['Available', 'Unavailable']
                      .map(
                        (status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onAvailabilityChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident});

  final ResponderIncident incident;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ResponderPalette.card.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ResponderPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            incident.title,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: ResponderPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaChip(icon: Icons.place_outlined, text: incident.location),
              _MetaChip(icon: Icons.schedule_rounded, text: incident.timeLabel),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Mission Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ResponderPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            incident.notes,
            style: const TextStyle(
              color: ResponderPalette.textSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: ResponderPalette.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
                icon: const Icon(Icons.directions_run_rounded),
                label: const Text('Responding'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: ResponderPalette.danger,
                  side: const BorderSide(color: ResponderPalette.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Not Available'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ResponderPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ResponderPalette.accent, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: ResponderPalette.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
