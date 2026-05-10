import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_theme/shared_theme.dart';

import '../app_palette.dart';
import '../app_config.dart';
import '../mission_time_text.dart';
import '../models/backup_alert.dart';
import '../models/incident.dart';
import '../models/open_tab_event.dart';
import '../services/browser_alert_channel.dart';
import '../services/native_alert_bridge.dart';
import '../services/native_alert_status_service.dart';
import '../services/open_tab_event_stream.dart';
import '../services/open_tab_event_stream_base.dart';
import '../services/responder_api.dart';
import '../widgets/responder_brand.dart';

class ResponderHomeScreen extends StatefulWidget {
  const ResponderHomeScreen({super.key, required this.auth});

  final AuthController auth;

  @override
  State<ResponderHomeScreen> createState() => _ResponderHomeScreenState();
}

class _ResponderHomeScreenState extends State<ResponderHomeScreen> {
  final api = ResponderApi();
  final nativeAlerts = NativeAlertStatusService();
  late final BrowserAlertChannel browserAlerts = BrowserAlertChannel(
    api: api,
    publicKey: webPushPublicKey,
    accessToken: widget.auth.ensureFreshAccessToken,
  );
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
  StreamSubscription<NativeAlertEvent>? nativeAlertSubscription;
  BackupAlert? activeBackupAlert;

  @override
  void initState() {
    super.initState();
    nativeAlerts.initialize();
    browserAlerts.ensureSubscribed();
    _connectOpenTabEvents();
    _loadIncidents();
    alertSubscription = browserAlerts.alerts.listen((alert) {
      if (!mounted) {
        return;
      }

      final idx = incidents.indexWhere(
        (i) => i.publicId == alert.incidentPublicId,
      );
      setState(() {
        if (idx >= 0) {
          selected = idx;
        }
        activeBackupAlert = alert;
      });
    });
    openTabEventSubscription = openTabEvents.events.listen(_handleOpenTabEvent);
    nativeAlertSubscription = nativeAlertBridge.events.listen(
      _handleNativeAlertEvent,
    );
  }

  @override
  void dispose() {
    alertSubscription?.cancel();
    openTabEventSubscription?.cancel();
    nativeAlertSubscription?.cancel();
    nativeAlerts.dispose();
    openTabEvents.dispose();
    browserAlerts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIncident = incidents.isEmpty ? null : incidents[selected];

    return ResponderHomeBody(
      userInitials: widget.auth.currentUser?.initials ?? '--',
      availability: availability,
      incidents: incidents,
      selected: selected,
      selectedIncident: selectedIncident,
      loading: loading,
      loadError: loadError,
      activeBackupAlert: activeBackupAlert,
      submittingResponse: submittingResponse,
      browserAlerts: browserAlerts,
      nativeAlerts: nativeAlerts,
      onLogout: widget.auth.logout,
      onAvailabilityChanged: _changeAvailability,
      onSelected: (index) => setState(() => selected = index),
      onDismissAlert: () => setState(() => activeBackupAlert = null),
      onOpenAlert: () {
        final alert = activeBackupAlert;
        if (alert == null) {
          return;
        }
        final idx = incidents.indexWhere(
          (i) => i.publicId == alert.incidentPublicId,
        );
        setState(() {
          if (idx >= 0) {
            selected = idx;
          }
          activeBackupAlert = null;
        });
      },
      onEnableBrowserAlerts: browserAlerts.requestPermissionAndSubscribe,
      onSendTestAlert: selectedIncident == null
          ? () async {}
          : () => _sendSupplementalAlert(incident: selectedIncident),
      onResponding: () => _submitResponse(
        status: ResponseStatus.responding,
        source: 'android_app',
      ),
      onNotAvailable: () => _submitResponse(
        status: ResponseStatus.notAvailable,
        source: 'android_app',
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

  Future<void> _connectOpenTabEvents() async {
    final accessToken = await widget.auth.ensureFreshAccessToken();
    if (!mounted || accessToken == null || accessToken.isEmpty) {
      return;
    }
    openTabEvents.connect(accessToken: accessToken);
  }

  Future<void> _loadIncidents() async {
    setState(() {
      loading = true;
      loadError = null;
    });

    try {
      final accessToken = await widget.auth.ensureFreshAccessToken();
      final loadedIncidents = await api.fetchIncidents(
        accessToken: accessToken,
        userPublicId: widget.auth.currentUser?.publicId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        incidents = loadedIncidents;
        selected = loadedIncidents.isEmpty
            ? 0
            : selected.clamp(0, loadedIncidents.length - 1);
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
      final accessToken = await widget.auth.ensureFreshAccessToken();
      final loadedIncidents = await api.fetchIncidents(
        accessToken: accessToken,
        userPublicId: widget.auth.currentUser?.publicId,
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
          : selected.clamp(0, loadedIncidents.length - 1);

      setState(() {
        incidents = loadedIncidents;
        selected = nextSelected;
        loading = false;
        loadError = null;
      });

      if (incidentIndex >= 0) {
        final incident = loadedIncidents[incidentIndex];
        await nativeAlertBridge.showNativeAlert(
          incidentPublicId: incident.publicId,
          title: event.title,
          body:
              '${incident.location} - ${formatMissionTime(incident.created, context)}',
        );
        await browserAlerts.presentInTab(incident);
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
    required ResponseStatus status,
    required String source,
    String? incidentPublicId,
  }) async {
    if (incidents.isEmpty || submittingResponse) {
      return;
    }

    final incidentIndex = incidentPublicId == null
        ? selected
        : incidents.indexWhere(
            (incident) => incident.publicId == incidentPublicId,
          );
    final resolvedIncidentPublicId = incidentPublicId ??
        (incidentIndex >= 0 ? incidents[incidentIndex].publicId : '');
    if (resolvedIncidentPublicId.isEmpty) {
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
      final accessToken = await widget.auth.ensureFreshAccessToken();
      final updatedResponse = await api.submitResponse(
        incidentPublicId: resolvedIncidentPublicId,
        status: status,
        source: source,
        accessToken: accessToken,
      );

      if (!mounted) {
        return;
      }

      if (incidentIndex >= 0 && incidentIndex < incidents.length) {
        setState(() {
          incidents = [
            for (var i = 0; i < incidents.length; i++)
              if (i == incidentIndex)
                incidents[i].withResponderResponse(updatedResponse)
              else
                incidents[i],
          ];
        });
      }
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

  Future<void> _handleNativeAlertEvent(NativeAlertEvent event) async {
    if (event.incidentPublicId.isEmpty) {
      return;
    }

    final incidentIndex = incidents.indexWhere(
      (incident) => incident.publicId == event.incidentPublicId,
    );

    if (incidentIndex >= 0 && mounted) {
      setState(() {
        selected = incidentIndex;
        activeBackupAlert = BackupAlert(
          incidentPublicId: event.incidentPublicId,
          title: event.title,
          body: event.body,
        );
      });
    }

    if (event.isReceived) {
      await _loadIncidents();
    } else if (event.isResponding) {
      await _submitResponse(
        status: ResponseStatus.responding,
        source: 'android_alert',
        incidentPublicId: event.incidentPublicId,
      );
    } else if (event.isNotAvailable) {
      await _submitResponse(
        status: ResponseStatus.notAvailable,
        source: 'android_alert',
        incidentPublicId: event.incidentPublicId,
      );
    }
  }

  Future<void> _sendSupplementalAlert({
    required ResponderIncident incident,
  }) async {
    if (nativeAlertBridge.isSupported && incident.publicId.isNotEmpty) {
      await nativeAlertBridge.showNativeAlert(
        incidentPublicId: incident.publicId,
        title: incident.title,
        body:
            '${incident.location} - ${formatMissionTime(incident.created, context)}',
      );
      return;
    }

    await browserAlerts.presentInTab(incident);
  }
}

class ResponderHomeBody extends StatelessWidget {
  const ResponderHomeBody({
    super.key,
    required this.userInitials,
    required this.availability,
    required this.incidents,
    required this.selected,
    required this.selectedIncident,
    required this.loading,
    required this.loadError,
    required this.activeBackupAlert,
    required this.submittingResponse,
    required this.browserAlerts,
    required this.nativeAlerts,
    required this.onLogout,
    required this.onAvailabilityChanged,
    required this.onSelected,
    required this.onDismissAlert,
    required this.onOpenAlert,
    required this.onEnableBrowserAlerts,
    required this.onSendTestAlert,
    required this.onResponding,
    required this.onNotAvailable,
  });

  final String userInitials;
  final String availability;
  final List<ResponderIncident> incidents;
  final int selected;
  final ResponderIncident? selectedIncident;
  final bool loading;
  final String? loadError;
  final BackupAlert? activeBackupAlert;
  final bool submittingResponse;
  final BrowserAlertChannel browserAlerts;
  final NativeAlertStatusService nativeAlerts;
  final VoidCallback onLogout;
  final ValueChanged<String> onAvailabilityChanged;
  final ValueChanged<int> onSelected;
  final VoidCallback onDismissAlert;
  final VoidCallback onOpenAlert;
  final Future<void> Function() onEnableBrowserAlerts;
  final Future<void> Function() onSendTestAlert;
  final Future<void> Function() onResponding;
  final Future<void> Function() onNotAvailable;

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
                  userInitials: userInitials,
                  availability: availability,
                  onAvailabilityChanged: onAvailabilityChanged,
                  onLogout: onLogout,
                ),
                const SizedBox(height: 16),
                if (loadError != null) ...[
                  _LoadErrorBanner(message: loadError!),
                  const SizedBox(height: 16),
                ],
                if (activeBackupAlert != null) ...[
                  _IncomingAlertStrip(
                    alert: activeBackupAlert!,
                    onDismiss: onDismissAlert,
                    onOpen: onOpenAlert,
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : incidents.isEmpty || selectedIncident == null
                      ? _StandbyWorkspace(
                          availability: availability,
                          browserAlerts: browserAlerts,
                          nativeAlerts: nativeAlerts,
                          onEnableBrowserAlerts: onEnableBrowserAlerts,
                        )
                      : _ActiveMissionWorkspace(
                          compact: compact,
                          incidents: incidents,
                          selected: selected,
                          availability: availability,
                          selectedIncident: selectedIncident!,
                          browserAlerts: browserAlerts,
                          nativeAlerts: nativeAlerts,
                          submittingResponse: submittingResponse,
                          onEnableBrowserAlerts: onEnableBrowserAlerts,
                          onSendTestAlert: onSendTestAlert,
                          onResponding: onResponding,
                          onNotAvailable: onNotAvailable,
                          onSelected: onSelected,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StandbyWorkspace extends StatelessWidget {
  const _StandbyWorkspace({
    required this.availability,
    required this.browserAlerts,
    required this.nativeAlerts,
    required this.onEnableBrowserAlerts,
  });

  final String availability;
  final BrowserAlertChannel browserAlerts;
  final NativeAlertStatusService nativeAlerts;
  final Future<void> Function() onEnableBrowserAlerts;

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
                browserAlerts: browserAlerts,
                nativeAlerts: nativeAlerts,
                onEnableBrowserAlerts: onEnableBrowserAlerts,
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
                browserAlerts: browserAlerts,
                nativeAlerts: nativeAlerts,
                onEnableBrowserAlerts: onEnableBrowserAlerts,
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
    required this.browserAlerts,
    required this.nativeAlerts,
    required this.submittingResponse,
    required this.onEnableBrowserAlerts,
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
  final BrowserAlertChannel browserAlerts;
  final NativeAlertStatusService nativeAlerts;
  final bool submittingResponse;
  final Future<void> Function() onEnableBrowserAlerts;
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
            browserAlerts: browserAlerts,
            nativeAlerts: nativeAlerts,
            onEnableBrowserAlerts: onEnableBrowserAlerts,
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
                  browserAlerts: browserAlerts,
                  nativeAlerts: nativeAlerts,
                  onEnableBrowserAlerts: onEnableBrowserAlerts,
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
    required this.browserAlerts,
    required this.nativeAlerts,
    required this.onEnableBrowserAlerts,
    this.availability,
    this.onSendTestAlert,
  });

  final BrowserAlertChannel browserAlerts;
  final NativeAlertStatusService nativeAlerts;
  final Future<void> Function() onEnableBrowserAlerts;
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
          if (nativeAlerts.isSupported) ...[
            const SizedBox(height: 18),
            ListenableBuilder(
              listenable: nativeAlerts,
              builder: (context, _) {
                final statusColor = nativeAlerts.isReady
                    ? ResponderPalette.success
                    : nativeAlerts.isLoading
                    ? ResponderPalette.accent
                    : ResponderPalette.warning;

                Widget? action;
                if (nativeAlerts.canRequestPermission) {
                  action = FilledButton(
                    onPressed: nativeAlerts.requestNotificationPermission,
                    child: const Text('Enable'),
                  );
                } else if (nativeAlerts.canOpenFullScreenSettings) {
                  action = OutlinedButton(
                    onPressed: nativeAlerts.openFullScreenIntentSettings,
                    child: const Text('Full-screen settings'),
                  );
                } else if (nativeAlerts.canOpenPolicySettings) {
                  action = OutlinedButton(
                    onPressed: nativeAlerts.openNotificationPolicySettings,
                    child: const Text('DND settings'),
                  );
                }

                return _ReadinessRow(
                  title: 'Native Android alerts',
                  status: nativeAlerts.statusLabel,
                  statusColor: statusColor,
                  detail: nativeAlerts.detailText,
                  action: action,
                );
              },
            ),
          ],
          if (browserAlerts.isSupported) ...[
            const SizedBox(height: 18),
            ListenableBuilder(
              listenable: browserAlerts,
              builder: (context, _) {
                final statusColor = switch (browserAlerts.state) {
                  BrowserAlertState.subscribed => ResponderPalette.success,
                  BrowserAlertState.registering => ResponderPalette.accent,
                  BrowserAlertState.error => ResponderPalette.danger,
                  BrowserAlertState.blocked => ResponderPalette.warning,
                  BrowserAlertState.unsupported => ResponderPalette.warning,
                  BrowserAlertState.notEnabled => ResponderPalette.warning,
                };

                Widget? action;
                if (browserAlerts.canEnable && !browserAlerts.isSubscribed) {
                  action = FilledButton(
                    onPressed: onEnableBrowserAlerts,
                    child: const Text('Enable'),
                  );
                } else if (browserAlerts.isSubscribed &&
                    onSendTestAlert != null) {
                  action = OutlinedButton(
                    onPressed: onSendTestAlert,
                    child: const Text('Test alert'),
                  );
                }

                return _ReadinessRow(
                  title: 'Browser alerts',
                  status: browserAlerts.statusLabel,
                  statusColor: statusColor,
                  detail: browserAlerts.detailText,
                  action: action,
                );
              },
            ),
          ],
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
                              label: incident.status?.label ?? 'Unknown',
                              color: switch (incident.status) {
                                ResponseStatus.responding =>
                                  ResponderPalette.success,
                                ResponseStatus.notAvailable =>
                                  ResponderPalette.textSoft,
                                ResponseStatus.pending => ResponderPalette
                                    .warning,
                                null => ResponderPalette.textSoft,
                              },
                            ),
                            const Spacer(),
                            Text(
                              formatMissionTime(incident.created, context),
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
                      text: formatMissionTime(incident.created, context),
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
          _ResponseSegmentedControl(
            currentStatus: incident.status,
            submitting: submittingResponse,
            onResponding: onResponding,
            onNotAvailable: onNotAvailable,
          ),
        ],
      ),
    );
  }
}

enum _ResponseChoice { responding, notAvailable }

class _ResponseSegmentedControl extends StatelessWidget {
  const _ResponseSegmentedControl({
    required this.currentStatus,
    required this.submitting,
    required this.onResponding,
    required this.onNotAvailable,
  });

  final ResponseStatus? currentStatus;
  final bool submitting;
  final Future<void> Function() onResponding;
  final Future<void> Function() onNotAvailable;

  @override
  Widget build(BuildContext context) {
    final groupValue = switch (currentStatus) {
      ResponseStatus.responding => _ResponseChoice.responding,
      ResponseStatus.notAvailable => _ResponseChoice.notAvailable,
      ResponseStatus.pending || null => null,
    };

    final children = <_ResponseChoice, Widget>{
      _ResponseChoice.responding: _segmentLabel(
        ResponseStatus.responding.label,
        selected: groupValue == _ResponseChoice.responding,
      ),
      _ResponseChoice.notAvailable: _segmentLabel(
        ResponseStatus.notAvailable.label,
        selected: groupValue == _ResponseChoice.notAvailable,
      ),
    };

    final control = CupertinoSlidingSegmentedControl<_ResponseChoice>(
      groupValue: groupValue,
      backgroundColor: Colors.white.withValues(alpha: 0.06),
      thumbColor: ResponderPalette.cardAlt,
      padding: const EdgeInsets.all(4),
      onValueChanged: (_) {},
      children: children,
    );

    final stack = Stack(
      children: [
        control,
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: submitting ? null : onResponding,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: submitting ? null : onNotAvailable,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: submitting ? 0.55 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          stack,
          if (submitting) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Saving...',
                  style: TextStyle(color: ResponderPalette.textSoft),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _segmentLabel(String text, {required bool selected}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? ResponderPalette.text : ResponderPalette.textSoft,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 14,
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
            color: ResponderPalette.danger,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: ResponderPalette.danger,
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
