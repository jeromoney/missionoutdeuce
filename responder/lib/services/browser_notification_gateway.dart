import 'browser_notification_gateway_stub.dart'
    if (dart.library.html) 'browser_notification_gateway_web.dart';

enum BrowserNotificationPermissionState {
  unsupported,
  notDetermined,
  granted,
  denied,
}

abstract class BrowserNotificationGateway {
  BrowserNotificationPermissionState get permissionState;
  Future<BrowserNotificationPermissionState> requestPermission();
  Future<void> showNotification({
    required String title,
    required String body,
  });
}

BrowserNotificationGateway createBrowserNotificationGateway() =>
    createBrowserNotificationGatewayImpl();
