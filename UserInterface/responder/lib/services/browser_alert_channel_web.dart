import 'dart:js_interop' as js;

import 'package:web/web.dart' as web;

import 'browser_alert_channel.dart';

@js.JS()
extension type _MissionOutWebPush._(js.JSObject _) implements js.JSObject {
  external bool isSupported();
  external bool supportsPush();
  external bool supportsServiceWorker();
  external js.JSPromise<_RegistrationResult?> registerServiceWorker(
    String scriptUrl,
  );
  external js.JSPromise<_SubscriptionData?> subscribe(
    String applicationServerKey,
  );
}

@js.JS()
extension type _RegistrationResult._(js.JSObject _) implements js.JSObject {
  external bool get success;
  external String? get error;
}

@js.JS()
extension type _SubscriptionData._(js.JSObject _) implements js.JSObject {
  external String? get endpoint;
  external String? get p256dh;
  external String? get auth;
}

@js.JS('missionOutWebPush')
external _MissionOutWebPush? get _bridge;

@js.JS('Notification')
extension type _NotificationApi._(js.JSObject _) implements js.JSObject {
  external String get permission;
  external js.JSPromise<js.JSString> requestPermission();
}

@js.JS('Notification')
external _NotificationApi? get _notificationApi;

bool get browserAlertsSupported {
  final bridge = _bridge;
  if (bridge == null) {
    return false;
  }
  return bridge.isSupported() &&
      bridge.supportsServiceWorker() &&
      bridge.supportsPush();
}

BrowserAlertPermission currentPermission() {
  final api = _notificationApi;
  if (api == null) {
    return BrowserAlertPermission.unsupported;
  }
  switch (api.permission) {
    case 'granted':
      return BrowserAlertPermission.granted;
    case 'denied':
      return BrowserAlertPermission.denied;
    default:
      return BrowserAlertPermission.notDetermined;
  }
}

Future<BrowserAlertPermission> requestPermission() async {
  final api = _notificationApi;
  if (api == null) {
    return BrowserAlertPermission.unsupported;
  }

  final result = (await api.requestPermission().toDart).toDart;
  switch (result) {
    case 'granted':
      return BrowserAlertPermission.granted;
    case 'denied':
      return BrowserAlertPermission.denied;
    default:
      return BrowserAlertPermission.notDetermined;
  }
}

Future<ServiceWorkerRegistrationResult> registerServiceWorker({
  required String scriptUrl,
}) async {
  final bridge = _bridge;
  if (bridge == null) {
    return const ServiceWorkerRegistrationResult(
      success: false,
      error: 'Web Push bridge is not available.',
    );
  }

  try {
    final result = await bridge.registerServiceWorker(scriptUrl).toDart;
    if (result == null) {
      return const ServiceWorkerRegistrationResult(success: true);
    }
    return ServiceWorkerRegistrationResult(
      success: result.success,
      error: result.error,
    );
  } catch (error) {
    return ServiceWorkerRegistrationResult(
      success: false,
      error: error.toString(),
    );
  }
}

Future<WebPushSubscriptionData?> subscribePush({
  required String applicationServerKey,
}) async {
  final bridge = _bridge;
  if (bridge == null || applicationServerKey.isEmpty) {
    return null;
  }

  try {
    final result = await bridge.subscribe(applicationServerKey).toDart;
    if (result == null) {
      return null;
    }
    final endpoint = result.endpoint;
    final p256dh = result.p256dh;
    final auth = result.auth;
    if (endpoint == null || p256dh == null || auth == null) {
      return null;
    }
    return WebPushSubscriptionData(
      endpoint: endpoint,
      p256dh: p256dh,
      auth: auth,
    );
  } catch (_) {
    return null;
  }
}

Future<void> showBrowserNotification({
  required String title,
  required String body,
}) async {
  if (currentPermission() != BrowserAlertPermission.granted) {
    return;
  }
  web.Notification(title, web.NotificationOptions(body: body));
}
