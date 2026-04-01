import 'browser_notification_gateway.dart';
import 'web_push_gateway_stub.dart'
    if (dart.library.html) 'web_push_gateway_web.dart';

class WebPushRegistrationResult {
  const WebPushRegistrationResult({required this.success, this.error});

  final bool success;
  final String? error;
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

abstract class WebPushGateway {
  bool get isSupported;
  bool get supportsServiceWorker;
  bool get supportsPush;
  BrowserNotificationPermissionState get permissionState;

  Future<WebPushRegistrationResult> registerServiceWorker({
    required String scriptUrl,
  });

  Future<WebPushSubscriptionData?> subscribeToPush({
    required String applicationServerKey,
  });
}

WebPushGateway createWebPushGateway() => createWebPushGatewayImpl();
