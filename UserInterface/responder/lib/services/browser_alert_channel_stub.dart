import 'browser_alert_channel.dart';

bool get browserAlertsSupported => false;

BrowserAlertPermission currentPermission() =>
    BrowserAlertPermission.unsupported;

Future<BrowserAlertPermission> requestPermission() async =>
    BrowserAlertPermission.unsupported;

Future<ServiceWorkerRegistrationResult> registerServiceWorker({
  required String scriptUrl,
}) async {
  return const ServiceWorkerRegistrationResult(
    success: false,
    error: 'Browser alerts are not supported on this platform.',
  );
}

Future<WebPushSubscriptionData?> subscribePush({
  required String applicationServerKey,
}) async {
  return null;
}

Future<void> showBrowserNotification({
  required String title,
  required String body,
}) async {}
