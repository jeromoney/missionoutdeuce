import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mission_time_text.dart';
import '../models/backup_alert.dart';
import '../models/incident.dart';
import 'browser_alert_channel_stub.dart'
    if (dart.library.html) 'browser_alert_channel_web.dart' as platform;
import 'responder_api.dart';

enum BrowserAlertPermission { unsupported, notDetermined, granted, denied }

enum BrowserAlertState {
  unsupported,
  notEnabled,
  blocked,
  registering,
  subscribed,
  error,
}

class WebPushSubscriptionData {
  const WebPushSubscriptionData({
    required this.endpoint,
    required this.p256dh,
    required this.auth,
  });

  final String endpoint;
  final String p256dh;
  final String auth;
}

class ServiceWorkerRegistrationResult {
  const ServiceWorkerRegistrationResult({required this.success, this.error});

  final bool success;
  final String? error;
}

class BrowserAlertChannel extends ChangeNotifier {
  BrowserAlertChannel({
    required ResponderApi api,
    required String publicKey,
  })  : _api = api,
        _publicKey = publicKey.trim();

  final ResponderApi _api;
  final String _publicKey;

  BrowserAlertState _state = BrowserAlertState.notEnabled;
  String? _errorMessage;
  WebPushSubscriptionData? _subscription;

  final StreamController<BackupAlert> _alertsController =
      StreamController<BackupAlert>.broadcast();

  Stream<BackupAlert> get alerts => _alertsController.stream;

  BrowserAlertState get state => _state;
  String? get errorMessage => _errorMessage;
  WebPushSubscriptionData? get subscription => _subscription;
  bool get isSupported => platform.browserAlertsSupported;
  BrowserAlertPermission get permission => platform.currentPermission();
  bool get isSubscribed => _state == BrowserAlertState.subscribed;
  bool get canEnable =>
      isSupported &&
      permission != BrowserAlertPermission.denied &&
      _state != BrowserAlertState.registering;

  String get statusLabel {
    switch (_state) {
      case BrowserAlertState.unsupported:
        return 'Unsupported';
      case BrowserAlertState.notEnabled:
        return 'Not enabled';
      case BrowserAlertState.blocked:
        return 'Blocked';
      case BrowserAlertState.registering:
        return 'Preparing';
      case BrowserAlertState.subscribed:
        return 'Enabled';
      case BrowserAlertState.error:
        return 'Error';
    }
  }

  String get detailText {
    switch (_state) {
      case BrowserAlertState.unsupported:
        return 'This browser does not support browser alerts.';
      case BrowserAlertState.notEnabled:
        return 'Enable browser alerts to receive open-tab and closed-tab notifications.';
      case BrowserAlertState.blocked:
        return 'Browser notification permission is blocked for this site.';
      case BrowserAlertState.registering:
        return 'Preparing the service worker and registering with MissionOut.';
      case BrowserAlertState.subscribed:
        return 'Browser alerts will appear in this tab and as system notifications when the tab is closed.';
      case BrowserAlertState.error:
        return _errorMessage ?? 'Browser alert setup failed.';
    }
  }

  Future<void> ensureSubscribed() async {
    if (!isSupported) {
      _state = BrowserAlertState.unsupported;
      notifyListeners();
      return;
    }

    switch (permission) {
      case BrowserAlertPermission.unsupported:
        _state = BrowserAlertState.unsupported;
        notifyListeners();
        return;
      case BrowserAlertPermission.denied:
        _state = BrowserAlertState.blocked;
        notifyListeners();
        return;
      case BrowserAlertPermission.notDetermined:
        _state = BrowserAlertState.notEnabled;
        notifyListeners();
        return;
      case BrowserAlertPermission.granted:
        await _subscribe();
        return;
    }
  }

  Future<void> requestPermissionAndSubscribe() async {
    if (!isSupported) {
      _state = BrowserAlertState.unsupported;
      notifyListeners();
      return;
    }

    if (permission != BrowserAlertPermission.granted) {
      final next = await platform.requestPermission();
      if (next == BrowserAlertPermission.denied) {
        _state = BrowserAlertState.blocked;
        notifyListeners();
        return;
      }
      if (next != BrowserAlertPermission.granted) {
        _state = BrowserAlertState.notEnabled;
        notifyListeners();
        return;
      }
    }

    await _subscribe();
  }

  Future<void> unsubscribe() async {
    final endpoint = _subscription?.endpoint;
    _subscription = null;
    _state = BrowserAlertState.notEnabled;
    notifyListeners();

    if (endpoint == null || endpoint.isEmpty) {
      return;
    }

    try {
      await _api.unregisterWebPush(endpoint: endpoint);
    } catch (_) {
      // Best-effort unregister; the backend can also reap stale subscriptions.
    }
  }

  Future<void> presentInTab(ResponderIncident incident) async {
    final title = incident.title;
    final body =
        '${incident.location} - ${formatMissionTimeNoContext(incident.created)}';

    if (kIsWeb && permission == BrowserAlertPermission.granted) {
      await platform.showBrowserNotification(title: title, body: body);
    }

    _alertsController.add(
      BackupAlert(
        incidentPublicId: incident.publicId,
        title: title,
        body: body,
      ),
    );
  }

  Future<void> _subscribe() async {
    _errorMessage = null;
    _state = BrowserAlertState.registering;
    notifyListeners();

    final registration = await platform.registerServiceWorker(
      scriptUrl: 'missionout_push_sw.js',
    );
    if (!registration.success) {
      _errorMessage =
          registration.error ?? 'Service worker registration failed.';
      _state = BrowserAlertState.error;
      notifyListeners();
      return;
    }

    if (_publicKey.isEmpty) {
      _state = BrowserAlertState.subscribed;
      notifyListeners();
      return;
    }

    final subscription = await platform.subscribePush(
      applicationServerKey: _publicKey,
    );
    if (subscription == null) {
      _errorMessage = 'Could not create a browser push subscription.';
      _state = BrowserAlertState.error;
      notifyListeners();
      return;
    }

    _subscription = subscription;

    try {
      await _api.registerWebPush(
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh,
        auth: subscription.auth,
      );
      _state = BrowserAlertState.subscribed;
    } catch (error) {
      _errorMessage = 'Backend registration failed: $error';
      _state = BrowserAlertState.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _alertsController.close();
    super.dispose();
  }
}
