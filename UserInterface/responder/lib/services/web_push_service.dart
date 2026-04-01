import 'package:flutter/foundation.dart';

import 'browser_notification_gateway.dart';
import 'web_push_gateway.dart';

enum WebPushClientState {
  unsupported,
  notEnabled,
  blocked,
  registering,
  workerReady,
  backendPending,
  error,
}

class WebPushService extends ChangeNotifier {
  WebPushService({WebPushGateway? gateway, required String publicKey})
    : _gateway = gateway ?? createWebPushGateway(),
      _publicKey = publicKey.trim();

  final WebPushGateway _gateway;
  final String _publicKey;

  WebPushClientState _state = WebPushClientState.notEnabled;
  String? _errorMessage;
  WebPushSubscriptionData? _subscription;

  WebPushClientState get state => _state;
  String? get errorMessage => _errorMessage;
  WebPushSubscriptionData? get subscription => _subscription;
  bool get isSupported => _gateway.isSupported;
  bool get canEnable =>
      isSupported &&
      _gateway.permissionState != BrowserNotificationPermissionState.denied &&
      _state != WebPushClientState.registering;

  String get statusLabel {
    switch (_state) {
      case WebPushClientState.unsupported:
        return 'Unsupported';
      case WebPushClientState.notEnabled:
        return 'Not enabled';
      case WebPushClientState.blocked:
        return 'Blocked';
      case WebPushClientState.registering:
        return 'Preparing';
      case WebPushClientState.workerReady:
        return 'Worker ready';
      case WebPushClientState.backendPending:
        return 'Backend pending';
      case WebPushClientState.error:
        return 'Error';
    }
  }

  String get detailText {
    switch (_state) {
      case WebPushClientState.unsupported:
        return 'This browser does not support service workers and Web Push.';
      case WebPushClientState.notEnabled:
        return 'Enable browser alerts to prepare closed-tab notifications with a service worker.';
      case WebPushClientState.blocked:
        return 'Browser notification permission is blocked for this site.';
      case WebPushClientState.registering:
        return 'Registering the MissionOut service worker for browser push.';
      case WebPushClientState.workerReady:
        return 'The service worker is ready. Add a WEB_PUSH_PUBLIC_KEY to finish local push subscription setup.';
      case WebPushClientState.backendPending:
        return _subscription == null
            ? 'The client skeleton is ready, but backend subscription registration is still pending.'
            : 'A browser push subscription was created locally. Backend registration still needs a contract route.';
      case WebPushClientState.error:
        return _errorMessage ?? 'Web Push setup failed.';
    }
  }

  Future<void> initialize() async {
    if (!_gateway.isSupported ||
        !_gateway.supportsServiceWorker ||
        !_gateway.supportsPush) {
      _state = WebPushClientState.unsupported;
      notifyListeners();
      return;
    }

    switch (_gateway.permissionState) {
      case BrowserNotificationPermissionState.denied:
        _state = WebPushClientState.blocked;
        notifyListeners();
        return;
      case BrowserNotificationPermissionState.granted:
        await _preparePush();
        return;
      case BrowserNotificationPermissionState.unsupported:
        _state = WebPushClientState.unsupported;
        notifyListeners();
        return;
      case BrowserNotificationPermissionState.notDetermined:
        _state = WebPushClientState.notEnabled;
        notifyListeners();
        return;
    }
  }

  Future<void> enable() async {
    if (!_gateway.isSupported) {
      _state = WebPushClientState.unsupported;
      notifyListeners();
      return;
    }

    if (_gateway.permissionState !=
        BrowserNotificationPermissionState.granted) {
      final permission = await htmlRequestPermission();
      if (permission == BrowserNotificationPermissionState.denied) {
        _state = WebPushClientState.blocked;
        notifyListeners();
        return;
      }
      if (permission != BrowserNotificationPermissionState.granted) {
        _state = WebPushClientState.notEnabled;
        notifyListeners();
        return;
      }
    }

    await _preparePush();
  }

  Future<BrowserNotificationPermissionState> htmlRequestPermission() async {
    final gatewayPermission = _gateway.permissionState;
    if (gatewayPermission == BrowserNotificationPermissionState.granted) {
      return gatewayPermission;
    }
    return createBrowserNotificationGateway().requestPermission();
  }

  Future<void> _preparePush() async {
    _errorMessage = null;
    _state = WebPushClientState.registering;
    notifyListeners();

    final registration = await _gateway.registerServiceWorker(
      scriptUrl: 'missionout_push_sw.js',
    );
    if (!registration.success) {
      _errorMessage =
          registration.error ?? 'Service worker registration failed.';
      _state = WebPushClientState.error;
      notifyListeners();
      return;
    }

    if (_publicKey.isEmpty) {
      _state = WebPushClientState.workerReady;
      notifyListeners();
      return;
    }

    _subscription = await _gateway.subscribeToPush(
      applicationServerKey: _publicKey,
    );
    _state = WebPushClientState.backendPending;
    notifyListeners();
  }
}
