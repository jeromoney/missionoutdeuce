import 'browser_notification_gateway.dart';
import 'web_push_gateway.dart';

class StubWebPushGateway implements WebPushGateway {
  @override
  bool get isSupported => false;

  @override
  bool get supportsPush => false;

  @override
  bool get supportsServiceWorker => false;

  @override
  BrowserNotificationPermissionState get permissionState =>
      BrowserNotificationPermissionState.unsupported;

  @override
  Future<WebPushRegistrationResult> registerServiceWorker({
    required String scriptUrl,
  }) async {
    return const WebPushRegistrationResult(
      success: false,
      error: 'Web Push is not supported on this platform.',
    );
  }

  @override
  Future<WebPushSubscriptionData?> subscribeToPush({
    required String applicationServerKey,
  }) async {
    return null;
  }
}

WebPushGateway createWebPushGatewayImpl() => StubWebPushGateway();
