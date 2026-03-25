import 'browser_notification_gateway.dart';

class StubBrowserNotificationGateway implements BrowserNotificationGateway {
  @override
  BrowserNotificationPermissionState get permissionState =>
      BrowserNotificationPermissionState.unsupported;

  @override
  Future<BrowserNotificationPermissionState> requestPermission() async {
    return BrowserNotificationPermissionState.unsupported;
  }

  @override
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {}
}

BrowserNotificationGateway createBrowserNotificationGatewayImpl() =>
    StubBrowserNotificationGateway();
