import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/backup_alert.dart';
import '../models/incident.dart';
import 'browser_notification_gateway.dart';

class BackupNotificationService extends ChangeNotifier {
  BackupNotificationService({
    BrowserNotificationGateway? gateway,
  }) : _gateway = gateway ?? createBrowserNotificationGateway();

  final BrowserNotificationGateway _gateway;
  final StreamController<BackupAlert> _alertsController =
      StreamController<BackupAlert>.broadcast();

  Stream<BackupAlert> get alerts => _alertsController.stream;

  BrowserNotificationPermissionState _permissionState =
      BrowserNotificationPermissionState.notDetermined;

  BrowserNotificationPermissionState get permissionState => _permissionState;
  bool get isSupported =>
      _permissionState != BrowserNotificationPermissionState.unsupported;
  bool get isGranted =>
      _permissionState == BrowserNotificationPermissionState.granted;

  Future<void> initialize() async {
    _permissionState = _gateway.permissionState;
    notifyListeners();
  }

  Future<void> requestPermission() async {
    _permissionState = await _gateway.requestPermission();
    notifyListeners();
  }

  Future<void> sendTestAlert({
    required int incidentIndex,
    required ResponderIncident incident,
  }) async {
    final alert = BackupAlert(
      incidentIndex: incidentIndex,
      title: incident.title,
      body: '${incident.location} • ${incident.timeLabel}',
    );

    if (kIsWeb && isGranted) {
      await _gateway.showNotification(
        title: incident.title,
        body: '${incident.location} • ${incident.timeLabel}',
      );
    }

    _alertsController.add(alert);
  }

  @override
  void dispose() {
    _alertsController.close();
    super.dispose();
  }
}
