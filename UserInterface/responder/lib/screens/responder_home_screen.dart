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
  bool submittingResponse = false;
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
            : alert.incidentIndex.clamp(0, incidents.length - 1);
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
    final selectedIncident = incidents.isEmpty ? null : incidents[selected];

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
                if (activeBackupAlert != null) ...[
                  _IncomingAlertStrip(
                    alert: activeBackupAlert!,
                    onDismiss: () {
                      setState(() => activeBackupAlert = null);
                    },
                    onOpen: () {
                      if (activeBackupAlert == null) {
                        return;
                      }
                      setState(() {
                        selected = activeBackupAlert!.incidentIndex;
                        activeBackupAlert = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : incidents.isEmpty
                      ? _StandbyWorkspace(
                          availability: availability,
                          notifications: backupNotifications,
                          webPush: webPush,
                          onEnableNotifications:
                              backupNotifications.requestPermission,
                          onEnableWebPush: webPush.enable,
                        )
                      : _ActiveMissionWorkspace(
                          compact: compact,
                          incidents: incidents,
                          selected: selected,
                          availability: availability,
                          selectedIncident: selectedIncident!,
                          notifications: backupNotifications,
                          webPush: webPush,
                          submittingResponse: submittingResponse,
                          onEnableNotifications:
                              backupNotifications.requestPermission,
                          onEnableWebPush: webPush.enable,
                          onSendTestAlert: () =>
                              backupNotifications.sendTestAlert(
                                incidentIndex: selected,
                                incident: selectedIncident,
                              ),
                          onResponding: () => _submitResponse(
                            status: 'Responding',
                            detail: 'Responder acknowledged and is en route.',
                          ),
                          onNotAvailable: () => _submitResponse(
                            status: 'Not Available',
                            detail:
                                'Responder is not available for this mission.',
                          ),
                          onSelected: (index) {
                            setState(() => selected = index);
                          },
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

      final incidentIndex = event.incidentPublicId == null
          ? -1
          : loadedIncidents.indexWhere(
              (incident) => incident.publicId == event.incidentPublicId,
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

  Future<void> _submitResponse({
    required String status,
    required String detail,
  }) async {
    if (incidents.isEmpty || submittingResponse) {
      return;
    }

    final incident = incidents[selected];
    if (incident.publicId.isEmpty) {
      setState(() {
        loadError =
            'Could not submit response because the incident public ID is missing.';
      });
      return;
    }

    setState(() {
      submittingResponse = true;
      loadError = null;
    });

    try {
      await api.submitResponse(
        incidentPublicId: incident.publicId,
        status: status,
        detail: detail,
        userEmail: widget.auth.currentUser?.email,
      );
      await _loadIncidents();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        loadError = 'Could not submit your responder status.';
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        submittingResponse = false;
      });
    }
  }
}

class _StandbyWorkspace extends StatelessWidget {
  const _StandbyWorkspace({
    required this.availability,
    required this.notifications,
    required this.webPush,
    required this.onEnableNotifications,
    required this.onEnableWebPush,
  });

  final String availability;
  final BackupNotificationService notifications;
  final WebPushService webPush;
  final Future<void> Function() onEnableNotifications;
  final Future<void> Function() onEnableWebPush;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 1080;

        if (narrow) {
          return ListView(
            children: [
              _StandbyHero(availability: availability),
              const SizedBox(height: 16),
              _ReadinessPanel(
                notifications: notifications,
                webPush: webPush,
                onEnableNotifications: onEnableNotifications,
                onEnableWebPush: onEnableWebPush,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: _StandbyHero(availability: availability)),
            const SizedBox(width: 16),
            SizedBox(
              width: 360,
              child: _ReadinessPanel(
                notifications: notifications,
                webPush: webPush,
                onEnableNotifications: onEnableNotifications,
                onEnableWebPush: onEnableWebPush,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActiveMissionWorkspace extends StatelessWidget {
  const _ActiveMissionWorkspace({
    required this.compact,
    required this.incidents,
    required this.selected,
    required this.availability,
    required this.selectedIncident,
    required this.notifications,
    required this.webPush,
    required this.submittingResponse,
    required this.onEnableNotifications,
    required this.onEnableWebPush,
    required this.onSendTestAlert,
    required this.onResponding,
    required this.onNotAvailable,
    required this.onSelected,
  });

  final bool compact;
  final List<ResponderIncident> incidents;
  final int selected;
  final String availability;
  final ResponderIncident selectedIncident;
  final BackupNotificationService notifications;
  final WebPushService webPush;
  final bool submittingResponse;
  final Future<void> Function() onEnableNotifications;
  final Future<void> Function() onEnableWebPush;
  final Future<void> Function() onSendTestAlert;
  final Future<void> Function() onResponding;
  final Future<void> Function() onNotAvailable;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return ListView(
        children: [
          SizedBox(
            height: 460,
            child: _IncidentCard(
              incident: selectedIncident,
              submittingResponse: submittingResponse,
              onResponding: onResponding,
              onNotAvailable: onNotAvailable,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _MissionList(
              incidents: incidents,
              selected: selected,
              onSelected: onSelected,
            ),
          ),
          const SizedBox(height: 16),
          _ReadinessPanel(
            availability: availability,
            notifications: notifications,
            webPush: webPush,
            onEnableNotifications: onEnableNotifications,
            onEnableWebPush: onEnableWebPush,
            onSendTestAlert: onSendTestAlert,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 4,
          child: _IncidentCard(
            incident: selectedIncident,
            submittingResponse: submittingResponse,
            onResponding: onResponding,
            onNotAvailable: onNotAvailable,
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 360,
          child: Column(
            children: [
              Expanded(
                child: _MissionList(
                  incidents: incidents,
                  selected: selected,
                  onSelected: onSelected,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: _ReadinessPanel(
                  availability: availability,
                  notifications: notifications,
                  webPush: webPush,
                  onEnableNotifications: onEnableNotifications,
                  onEnableWebPush: onEnableWebPush,
                  onSendTestAlert: onSendTestAlert,
                ),
              ),
            ],
          ),
        ),
      ],
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

class _IncomingAlertStrip extends StatelessWidget {
  const _IncomingAlertStrip({
    required this.alert,
    required this.onDismiss,
    required this.onOpen,
  });

  final BackupAlert alert;
  final VoidCallback onDismiss;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: ResponderPalette.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: ResponderPalette.accent.withValues(alpha: 0.34),
        ),
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
                const Text(
                  'Incoming mission alert',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ResponderPalette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ResponderPalette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.body,
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
              FilledButton(
                onPressed: onOpen,
                child: const Text('Open mission'),
              ),
              TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StandbyHero extends StatelessWidget {
  const _StandbyHero({required this.availability});

  final String availability;

  @override
  Widget build(BuildContext context) {
    final available = availability == 'Available';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.05),
            ResponderPalette.card.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: ResponderPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusPill(
            label: available ? 'Standing by' : 'Unavailable',
            color: available
                ? ResponderPalette.success
                : ResponderPalette.warning,
          ),
          const SizedBox(height: 56),
          const ResponderBrandLogo(size: 82),
          const SizedBox(height: 24),
          const Text(
            'Quiet until a mission arrives.',
            style: TextStyle(
              fontSize: 42,
              height: 1.05,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.6,
              color: ResponderPalette.text,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            available
                ? 'This screen stays minimal by default. When dispatch starts, the mission view takes over and response actions move to the front.'
                : 'You are currently unavailable, so the app stays in standby and no responder actions are active until you switch back.',
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: ResponderPalette.textSoft,
            ),
          ),
          const SizedBox(height: 26),
          Wrap(
            spacing: 24,
            runSpacing: 14,
            children: [
              _StandbyMetric(
                label: 'State',
                value: available ? 'Ready for interrupt' : 'Alerts paused',
              ),
              const _StandbyMetric(
                label: 'Default mode',
                value: 'Idle, not queue-driven',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadinessPanel extends StatelessWidget {
  const _ReadinessPanel({
    required this.notifications,
    required this.webPush,
    required this.onEnableNotifications,
    required this.onEnableWebPush,
    this.availability,
    this.onSendTestAlert,
  });

  final BackupNotificationService notifications;
  final WebPushService webPush;
  final Future<void> Function() onEnableNotifications;
  final Future<void> Function() onEnableWebPush;
  final String? availability;
  final Future<void> Function()? onSendTestAlert;

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
          const Text(
            'Readiness',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              color: ResponderPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep this device ready for the next interrupt. Notification channels are supplemental to native mobile alerting.',
            style: TextStyle(color: ResponderPalette.textSoft, height: 1.5),
          ),
          if (availability != null) ...[
            const SizedBox(height: 18),
            _ReadinessRow(
              title: 'Availability',
              status: availability!,
              statusColor: availability == 'Available'
                  ? ResponderPalette.success
                  : ResponderPalette.warning,
              detail: availability == 'Available'
                  ? 'Responder actions will surface when a mission is assigned.'
                  : 'Alert actions stay out of the way until you are available again.',
            ),
          ],
          const SizedBox(height: 18),
          ListenableBuilder(
            listenable: notifications,
            builder: (context, _) {
              final permissionLabel = switch (notifications.permissionState) {
                BrowserNotificationPermissionState.granted => 'Enabled',
                BrowserNotificationPermissionState.denied => 'Blocked',
                BrowserNotificationPermissionState.unsupported => 'Unsupported',
                BrowserNotificationPermissionState.notDetermined =>
                  'Not enabled',
              };

              return _ReadinessRow(
                title: 'Open-tab alerts',
                status: permissionLabel,
                statusColor: notifications.isGranted
                    ? ResponderPalette.success
                    : ResponderPalette.warning,
                detail:
                    'Use browser notifications for backup awareness while this tab is open.',
                action:
                    !notifications.isGranted &&
                        notifications.permissionState !=
                            BrowserNotificationPermissionState.unsupported
                    ? FilledButton(
                        onPressed: onEnableNotifications,
                        child: const Text('Enable'),
                      )
                    : onSendTestAlert != null
                    ? OutlinedButton(
                        onPressed: onSendTestAlert,
                        child: const Text('Test alert'),
                      )
                    : null,
              );
            },
          ),
          const SizedBox(height: 18),
          ListenableBuilder(
            listenable: webPush,
            builder: (context, _) {
              final statusColor = switch (webPush.state) {
                WebPushClientState.workerReady => ResponderPalette.accent,
                WebPushClientState.backendPending => ResponderPalette.success,
                WebPushClientState.error => ResponderPalette.danger,
                WebPushClientState.blocked => ResponderPalette.warning,
                WebPushClientState.unsupported => ResponderPalette.warning,
                WebPushClientState.registering => ResponderPalette.accent,
                WebPushClientState.notEnabled => ResponderPalette.warning,
              };

              return _ReadinessRow(
                title: 'Closed-tab browser alerts',
                status: webPush.statusLabel,
                statusColor: statusColor,
                detail: webPush.detailText,
                action: webPush.canEnable
                    ? FilledButton(
                        onPressed: onEnableWebPush,
                        child: const Text('Enable'),
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({
    required this.title,
    required this.status,
    required this.statusColor,
    required this.detail,
    this.action,
  });

  final String title;
  final String status;
  final Color statusColor;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ResponderPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: ResponderPalette.text,
                  ),
                ),
              ),
              _StatusPill(label: status, color: statusColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            detail,
            style: const TextStyle(
              color: ResponderPalette.textSoft,
              height: 1.5,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

class _StandbyMetric extends StatelessWidget {
  const _StandbyMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: ResponderPalette.textSoft,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: ResponderPalette.text,
          ),
        ),
      ],
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
  const _IncidentCard({
    required this.incident,
    required this.submittingResponse,
    required this.onResponding,
    required this.onNotAvailable,
  });

  final ResponderIncident incident;
  final bool submittingResponse;
  final Future<void> Function() onResponding;
  final Future<void> Function() onNotAvailable;

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
                onPressed: submittingResponse ? null : onResponding,
                style: FilledButton.styleFrom(
                  backgroundColor: ResponderPalette.success,
                ),
                icon: const Icon(Icons.directions_run_rounded),
                label: Text(submittingResponse ? 'Saving...' : 'Responding'),
              ),
              OutlinedButton.icon(
                onPressed: submittingResponse ? null : onNotAvailable,
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
