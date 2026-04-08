import 'dart:js_interop' as js;

import 'package:web/web.dart' as web;

import 'browser_notification_gateway.dart';

@js.JS('Notification')
extension type _NotificationApi._(js.JSObject _) implements js.JSObject {
  external String get permission;
  external js.JSPromise<js.JSString> requestPermission();
}

@js.JS('Notification')
external _NotificationApi? get _notificationApi;

class WebBrowserNotificationGateway implements BrowserNotificationGateway {
  @override
  BrowserNotificationPermissionState get permissionState {
    final notificationApi = _notificationApi;
    if (notificationApi == null) {
      return BrowserNotificationPermissionState.unsupported;
    }

    switch (notificationApi.permission) {
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
    final notificationApi = _notificationApi;
    if (notificationApi == null) {
      return BrowserNotificationPermissionState.unsupported;
    }

    final result = (await notificationApi.requestPermission().toDart).toDart;
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

    web.Notification(title, web.NotificationOptions(body: body));
  }
}

BrowserNotificationGateway createBrowserNotificationGatewayImpl() =>
    WebBrowserNotificationGateway();
