import 'package:web/web.dart' as web;
import 'dart:js_interop' as js;

import 'browser_notification_gateway.dart';
import 'web_push_gateway.dart';

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

class WebBrowserPushGateway implements WebPushGateway {
  @override
  bool get isSupported {
    final bridge = _bridge;
    if (bridge == null) {
      return false;
    }
    return bridge.isSupported();
  }

  @override
  bool get supportsPush {
    final bridge = _bridge;
    if (bridge == null) {
      return false;
    }
    return bridge.supportsPush();
  }

  @override
  bool get supportsServiceWorker {
    final bridge = _bridge;
    if (bridge == null) {
      return false;
    }
    return bridge.supportsServiceWorker();
  }

  @override
  BrowserNotificationPermissionState get permissionState {
    if (!isSupported) {
      return BrowserNotificationPermissionState.unsupported;
    }
    switch (web.Notification.permission) {
      case 'granted':
        return BrowserNotificationPermissionState.granted;
      case 'denied':
        return BrowserNotificationPermissionState.denied;
      default:
        return BrowserNotificationPermissionState.notDetermined;
    }
  }

  @override
  Future<WebPushRegistrationResult> registerServiceWorker({
    required String scriptUrl,
  }) async {
    final bridge = _bridge;
    if (bridge == null) {
      return const WebPushRegistrationResult(
        success: false,
        error: 'Web Push bridge is not available.',
      );
    }

    try {
      final result = await bridge.registerServiceWorker(scriptUrl).toDart;
      if (result == null) {
        return const WebPushRegistrationResult(success: true);
      }

      final success = result.success;
      final error = result.error;
      return WebPushRegistrationResult(success: success, error: error);
    } catch (error) {
      return WebPushRegistrationResult(success: false, error: error.toString());
    }
  }

  @override
  Future<WebPushSubscriptionData?> subscribeToPush({
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
}

WebPushGateway createWebPushGatewayImpl() => WebBrowserPushGateway();
