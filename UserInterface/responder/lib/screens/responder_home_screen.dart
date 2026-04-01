import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_theme/shared_theme.dart';

import '../app_palette.dart';
import '../app_config.dart';
import '../models/backup_alert.dart';
import '../models/incident.dart';
import '../models/open_tab_event.dart';
import '../services/backup_notification_service.dart';
import '../services/browser_notification_gateway.dart';
import '../services/open_tab_event_stream.dart';
import '../services/open_tab_event_stream_base.dart';
import '../services/responder_api.dart';
import '../services/web_push_service.dart';
import '../widgets/responder_brand.dart';

class ResponderHomeScreen extends StatefulWidget {
  const ResponderHomeScreen({super.key, required this.auth});

  final AuthController auth;

  @override
  State<ResponderHomeScreen> createState() => _ResponderHomeScreenState();
}

class _ResponderHomeScreenState extends State<ResponderHomeScreen> {
  final api = ResponderApi();
  final backupNotifications = BackupNotificationService();
  final webPush = WebPushService(publicKey: webPushPublicKey);
  late final OpenTabEventStream openTabEvents = createOpenTabEventStream(
    streamUrl: '${api.baseUrl}/events/stream',
  );
  List<ResponderIncident> incidents = const [];
  int selected = 0;
  String availability = 'Available';
  bool loading = true;
  String? loadError;
  StreamSubscription<BackupAlert>? alertSubscription;
  StreamSubscription<OpenTabEvent>? openTabEventSubscription;
  BackupAlert? activeBackupAlert;

  @override
  void initState() {
    super.initState();
    backupNotifications.initialize();
    webPush.initialize();
    final userEmail = widget.auth.currentUser?.email?.trim() ?? '';
    if (userEmail.isNotEmpty) {
      openTabEvents.connect(userEmail: userEmail);
    }
    _loadIncidents();
    alertSubscription = backupNotifications.alerts.listen((alert) {
      if (!mounted) {
        return;
      }

      setState(() {
        selected = incidents.isEmpty
            ? 0
            : alert.incidentIndex.clamp(0, incidents.length - 1) as int;
        activeBackupAlert = alert;
      });
    });
    openTabEventSubscription = openTabEvents.events.listen(_handleOpenTabEvent);
  }

  @override
  void dispose() {
    alertSubscription?.cancel();
    openTabEventSubscription?.cancel();
    backupNotifications.dispose();
    openTabEvents.dispose();
    webPush.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 1080;

    return Scaffold(
      body: MissionOutBackdrop(
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
                if (loadError != null) ...[
                  _LoadErrorBanner(message: loadError!),
                  const SizedBox(height: 16),
                ],
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
                _WebPushBanner(service: webPush, onEnable: webPush.enable),
                const SizedBox(height: 16),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : incidents.isEmpty
                      ? const _NoMissionState()
                      : compact
                      ? ListView(
                          children: [
                            SizedBox(
                              height: 340,
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
                              height: 600,
                              child: _IncidentCard(
                                incident: incidents[selected],
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 370,
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

  Future<void> _loadIncidents() async {
    setState(() {
      loading = true;
      loadError = null;
    });

    try {
      final loadedIncidents = await api.fetchIncidents(
        userEmail: widget.auth.currentUser?.email,
        userName: widget.auth.currentUser?.name,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        incidents = loadedIncidents;
        selected = loadedIncidents.isEmpty
            ? 0
            : selected.clamp(0, loadedIncidents.length - 1) as int;
        loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        incidents = const [];
        selected = 0;
        loading = false;
        loadError = 'Could not load missions from the API.';
      });
    }
  }

  Future<void> _handleOpenTabEvent(OpenTabEvent event) async {
    if (!event.isIncidentCreated) {
      return;
    }

    try {
      final loadedIncidents = await api.fetchIncidents(
        userEmail: widget.auth.currentUser?.email,
        userName: widget.auth.currentUser?.name,
      );

      if (!mounted) {
        return;
      }

      final incidentIndex = event.incidentId == null
          ? -1
          : loadedIncidents.indexWhere(
              (incident) => incident.id == event.incidentId,
            );
      final nextSelected = loadedIncidents.isEmpty
          ? 0
          : incidentIndex >= 0
          ? incidentIndex
          : selected.clamp(0, loadedIncidents.length - 1) as int;

      setState(() {
        incidents = loadedIncidents;
        selected = nextSelected;
        loading = false;
        loadError = null;
      });

      if (incidentIndex >= 0) {
        final incident = loadedIncidents[incidentIndex];
        await backupNotifications.presentAlert(
          incidentIndex: incidentIndex,
          title: event.title,
          body: '${incident.location} - ${incident.timeLabel}',
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        loadError = 'Could not refresh missions after a live event.';
      });
    }
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ResponderPalette.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: ResponderPalette.border),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const SizedBox(
            width: 620,
            child: ResponderBrandLockup(
              subtitle:
                  'Responder view for acknowledgements, readiness, and active mission context.',
              logoSize: 58,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  dropdownColor: ResponderPalette.cardAlt,
                  style: const TextStyle(color: ResponderPalette.text),
                  iconEnabledColor: ResponderPalette.text,
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
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                tooltip: 'Account',
                color: ResponderPalette.cardAlt,
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: ResponderPalette.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    userInitials,
                    style: const TextStyle(
                      color: ResponderPalette.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ResponderPalette.card.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: ResponderPalette.border),
          ),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 520,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Backup notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: ResponderPalette.text,
                          ),
                        ),
                        const SizedBox(width: 10),
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
                        height: 1.45,
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

class _WebPushBanner extends StatelessWidget {
  const _WebPushBanner({required this.service, required this.onEnable});

  final WebPushService service;
  final Future<void> Function() onEnable;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final statusColor = switch (service.state) {
          WebPushClientState.workerReady => ResponderPalette.accent,
          WebPushClientState.backendPending => ResponderPalette.success,
          WebPushClientState.error => ResponderPalette.danger,
          WebPushClientState.blocked => ResponderPalette.warning,
          WebPushClientState.unsupported => ResponderPalette.warning,
          WebPushClientState.registering => ResponderPalette.accent,
          WebPushClientState.notEnabled => ResponderPalette.warning,
        };

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ResponderPalette.card.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: ResponderPalette.border),
          ),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 560,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Closed-tab browser alerts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: ResponderPalette.text,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _StatusPill(
                          label: service.statusLabel,
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service.detailText,
                      style: const TextStyle(
                        color: ResponderPalette.textSoft,
                        height: 1.45,
                      ),
                    ),
                    if (service.subscription != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Local subscription ready: ${service.subscription!.endpoint}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ResponderPalette.textSoft,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (service.canEnable)
                    FilledButton(
                      onPressed: onEnable,
                      child: const Text('Enable browser alerts'),
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
        color: ResponderPalette.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ResponderPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active missions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
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
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => onSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ResponderPalette.cardAlt
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(22),
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
                            fontWeight: FontWeight.w800,
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
                                fontWeight: FontWeight.w700,
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

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident});

  final ResponderIncident incident;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ResponderPalette.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ResponderPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ResponderPalette.primary, ResponderPalette.cardAlt],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                    color: ResponderPalette.text,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetaChip(
                      icon: Icons.place_outlined,
                      text: incident.location,
                    ),
                    _MetaChip(
                      icon: Icons.schedule_rounded,
                      text: incident.timeLabel,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Mission notes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
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
          const Spacer(),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: ResponderPalette.success,
                ),
                icon: const Icon(Icons.directions_run_rounded),
                label: const Text('Responding'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: ResponderPalette.danger,
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

class _NoMissionState extends StatelessWidget {
  const _NoMissionState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: ResponderPalette.card.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: ResponderPalette.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ResponderBrandLogo(size: 74),
              const SizedBox(height: 18),
              const Text(
                'No active mission',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                  color: ResponderPalette.text,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'When a new mission is dispatched, it will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ResponderPalette.textSoft, height: 1.5),
              ),
              const SizedBox(height: 20),
              _StatusPill(
                label: 'Standing by',
                color: ResponderPalette.success,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ResponderPalette.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ResponderPalette.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: ResponderPalette.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: ResponderPalette.textSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
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
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
