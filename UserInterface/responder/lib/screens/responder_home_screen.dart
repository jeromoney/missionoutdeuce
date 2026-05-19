import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_theme/shared_theme.dart';

import '../app_palette.dart';
import '../app_config.dart';
import '../l10n/generated/app_localizations.dart';
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
  late final ResponderApi api;
  final nativeAlerts = NativeAlertStatusService();
  late final BrowserAlertChannel browserAlerts;
  late final OpenTabEventStream openTabEvents;
  List<ResponderIncident> incidents = const [];
  int selected = 0;
  AvailabilityStatus availability = AvailabilityStatus.available;
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
    api = ResponderApi(
      client: AuthHeaderClient(
        http.Client(),
        widget.auth.getIdToken,
        teamIdProvider: () => widget.auth.activeTeam?.teamPublicId,
      ),
    );
    browserAlerts = BrowserAlertChannel(api: api, publicKey: webPushPublicKey);
    openTabEvents = createOpenTabEventStream(
      streamUrl: '${api.baseUrl}/events/stream',
    );
    nativeAlerts.initialize();
    browserAlerts.ensureSubscribed();
    _connectOpenTabEvents();
    _loadIncidents();
    _registerFcmToken();
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

  Future<void> _changeAvailability(AvailabilityStatus value) async {
    if (availability == AvailabilityStatus.available &&
        value == AvailabilityStatus.unavailable) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(l10n.dialogGoUnavailableTitle),
            content: Text(l10n.dialogGoUnavailableContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancelButton),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.dialogGoUnavailableConfirm),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) {
        return;
      }
    }

    setState(() => availability = value);
    _syncAvailability(value);
  }

  Future<void> _syncAvailability(AvailabilityStatus value) async {
    final token = await nativeAlertBridge.getToken();
    if (token == null) return;
    try {
      await api.setAvailability(
        pushToken: token,
        available: value == AvailabilityStatus.available,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorSubmitResponse),
        ),
      );
    }
  }

  Future<void> _registerFcmToken() async {
    final token = await nativeAlertBridge.getToken();
    if (token == null) return;
    try {
      await api.registerDevice(pushToken: token, platform: 'android');
    } catch (_) {}
  }

  Future<void> _connectOpenTabEvents() async {
    final accessToken = await widget.auth.getIdToken();
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
      final loadedIncidents = await api.fetchIncidents(
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
        loadError = AppLocalizations.of(context).errorLoadIncidents;
      });
    }
  }

  Future<void> _handleOpenTabEvent(OpenTabEvent event) async {
    if (!event.isIncidentCreated) {
      return;
    }

    try {
      final loadedIncidents = await api.fetchIncidents(
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
        loadError = AppLocalizations.of(context).errorRefreshIncidents;
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
            AppLocalizations.of(context).errorMissingIncidentId;
      });
      return;
    }

    setState(() {
      submittingResponse = true;
      loadError = null;
    });

    try {
      final updatedResponse = await api.submitResponse(
        incidentPublicId: resolvedIncidentPublicId,
        status: status,
        source: source,
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
        loadError = AppLocalizations.of(context).errorSubmitResponse;
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
  final AvailabilityStatus availability;
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
  final ValueChanged<AvailabilityStatus> onAvailabilityChanged;
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

  final AvailabilityStatus availability;
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
  final AvailabilityStatus availability;
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
  final AvailabilityStatus availability;
  final ValueChanged<AvailabilityStatus> onAvailabilityChanged;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          SizedBox(
            width: 620,
            child: ResponderBrandLockup(
              subtitle: l10n.brandSubtitle,
              logoSize: 58,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusPill(
                label: l10n.availabilityStatus(availability.name),
                color: availability == AvailabilityStatus.available
                    ? ResponderPalette.success
                    : ResponderPalette.warning,
              ),
              const SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: DropdownButton<AvailabilityStatus>(
                  value: availability,
                  dropdownColor: ResponderPalette.cardAlt,
                  style: const TextStyle(color: ResponderPalette.text),
                  iconEnabledColor: ResponderPalette.text,
                  items: AvailabilityStatus.values
                      .map(
                        (status) => DropdownMenuItem<AvailabilityStatus>(
                          value: status,
                          child: Text(l10n.availabilityStatus(status.name)),
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
                tooltip: l10n.tooltipAccount,
                color: ResponderPalette.cardAlt,
                onSelected: (value) {
                  if (value == 'logout') {
                    onLogout();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Text(l10n.logOut),
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
    final l10n = AppLocalizations.of(context);
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
                Text(
                  l10n.incomingAlertTitle,
                  style: const TextStyle(
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
                child: Text(l10n.openMissionButton),
              ),
              TextButton(onPressed: onDismiss, child: Text(l10n.dismissButton)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StandbyHero extends StatelessWidget {
  const _StandbyHero({required this.availability});

  final AvailabilityStatus availability;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final available = availability == AvailabilityStatus.available;

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
            label: available
                ? l10n.statusStandingBy
                : l10n.availabilityStatus(AvailabilityStatus.unavailable.name),
            color: available
                ? ResponderPalette.success
                : ResponderPalette.warning,
          ),
          const SizedBox(height: 56),
          const ResponderBrandLogo(size: 82),
          const SizedBox(height: 24),
          Text(
            l10n.standbyHeroTitle,
            style: const TextStyle(
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
                ? l10n.standbyHeroDescriptionAvailable
                : l10n.standbyHeroDescriptionUnavailable,
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
                label: l10n.metricStateLabel,
                value: available
                    ? l10n.metricStateReadyValue
                    : l10n.metricStateAlertsPausedValue,
              ),
              _StandbyMetric(
                label: l10n.metricDefaultModeLabel,
                value: l10n.metricDefaultModeValue,
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
  final AvailabilityStatus? availability;
  final Future<void> Function()? onSendTestAlert;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          Text(
            l10n.readinessHeading,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              color: ResponderPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.readinessSubtitle,
            style: const TextStyle(
              color: ResponderPalette.textSoft,
              height: 1.5,
            ),
          ),
          if (availability != null) ...[
            const SizedBox(height: 18),
            _ReadinessRow(
              title: l10n.readinessAvailabilityTitle,
              status: l10n.availabilityStatus(availability!.name),
              statusColor: availability == AvailabilityStatus.available
                  ? ResponderPalette.success
                  : ResponderPalette.warning,
              detail: availability == AvailabilityStatus.available
                  ? l10n.readinessAvailabilityDetailAvailable
                  : l10n.readinessAvailabilityDetailUnavailable,
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
                    child: Text(l10n.enableButton),
                  );
                } else if (nativeAlerts.canOpenFullScreenSettings) {
                  action = OutlinedButton(
                    onPressed: nativeAlerts.openFullScreenIntentSettings,
                    child: Text(l10n.fullScreenSettingsButton),
                  );
                } else if (nativeAlerts.canOpenPolicySettings) {
                  action = OutlinedButton(
                    onPressed: nativeAlerts.openNotificationPolicySettings,
                    child: Text(l10n.dndSettingsButton),
                  );
                }

                return _ReadinessRow(
                  title: l10n.readinessNativeAlertsTitle,
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
                    child: Text(l10n.enableButton),
                  );
                } else if (browserAlerts.isSubscribed &&
                    onSendTestAlert != null) {
                  action = OutlinedButton(
                    onPressed: onSendTestAlert,
                    child: Text(l10n.testAlertButton),
                  );
                }

                return _ReadinessRow(
                  title: l10n.readinessBrowserAlertsTitle,
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
    final l10n = AppLocalizations.of(context);
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
          Text(
            l10n.missionListTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              color: ResponderPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.missionListSubtitle,
            style: const TextStyle(color: ResponderPalette.textSoft),
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
                              label: incident.status == null
                                  ? l10n.statusUnknown
                                  : l10n.responseStatus(
                                      incident.status!.name,
                                    ),
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
    final l10n = AppLocalizations.of(context);
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
          Text(
            l10n.missionNotesHeading,
            style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
    final groupValue = switch (currentStatus) {
      ResponseStatus.responding => _ResponseChoice.responding,
      ResponseStatus.notAvailable => _ResponseChoice.notAvailable,
      ResponseStatus.pending || null => null,
    };

    final children = <_ResponseChoice, Widget>{
      _ResponseChoice.responding: _segmentLabel(
        l10n.responseStatus(ResponseStatus.responding.name),
        selected: groupValue == _ResponseChoice.responding,
      ),
      _ResponseChoice.notAvailable: _segmentLabel(
        l10n.responseStatus(ResponseStatus.notAvailable.name),
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
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.savingButton,
                  style: const TextStyle(color: ResponderPalette.textSoft),
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
