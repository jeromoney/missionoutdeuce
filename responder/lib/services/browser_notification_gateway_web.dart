import 'dart:html' as html;

import 'browser_notification_gateway.dart';

class WebBrowserNotificationGateway implements BrowserNotificationGateway {
  @override
  BrowserNotificationPermissionState get permissionState {
    if (!html.Notification.supported) {
      return BrowserNotificationPermissionState.unsupported;
    }

    switch (html.Notification.permission) {
      case 'granted':
        return BrowserNotificationPermissionState.granted;
      case 'denied':
        return BrowserNotificationPermissionState.denied;
      default:
        return BrowserNotificationPermissionState.notDetermined;
    }
  }

  @override
  Future<BrowserNotificationPermissionState> requestPermission() async {
    if (!html.Notification.supported) {
      return BrowserNotificationPermissionState.unsupported;
    }

    final result = await html.Notification.requestPermission();
    switch (result) {
      case 'granted':
        return BrowserNotificationPermissionState.granted;
      case 'denied':
        return BrowserNotificationPermissionState.denied;
      default:
        return BrowserNotificationPermissionState.notDetermined;
    }
  }

  @override
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (permissionState != BrowserNotificationPermissionState.granted) {
      return;
    }

    html.Notification(title, body: body);
  }
}

BrowserNotificationGateway createBrowserNotificationGatewayImpl() =>
    WebBrowserNotificationGateway();
