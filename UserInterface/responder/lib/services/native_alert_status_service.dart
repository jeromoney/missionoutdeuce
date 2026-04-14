import 'dart:async';

import 'package:flutter/widgets.dart';

import 'native_alert_bridge.dart';

class NativeAlertStatusService extends ChangeNotifier
    with WidgetsBindingObserver {
  NativeAlertStatusService({NativeAlertBridge? bridge})
    : _bridge = bridge ?? nativeAlertBridge;

  final NativeAlertBridge _bridge;

  NativeAlertCapabilities _capabilities =
      const NativeAlertCapabilities.unsupported();
  bool _loading = false;
  bool _initialized = false;

  bool get isSupported => _bridge.isSupported;
  bool get isLoading => _loading;
  bool get isReady =>
      notificationPermissionGranted &&
      canUseFullScreenIntent &&
      notificationPolicyAccessGranted;
  bool get notificationPermissionGranted =>
      _capabilities.notificationPermissionGranted;
  bool get notificationPolicyAccessGranted =>
      _capabilities.notificationPolicyAccessGranted;
  bool get canUseFullScreenIntent => _capabilities.canUseFullScreenIntent;
  bool get supportsFullScreenIntentManagement =>
      _capabilities.supportsFullScreenIntentManagement;

  bool get canRequestPermission =>
      isSupported && !_loading && !notificationPermissionGranted;
  bool get canOpenPolicySettings =>
      isSupported &&
      !_loading &&
      notificationPermissionGranted &&
      !notificationPolicyAccessGranted;
  bool get canOpenFullScreenSettings =>
      isSupported &&
      !_loading &&
      notificationPermissionGranted &&
      supportsFullScreenIntentManagement &&
      !canUseFullScreenIntent;

  String get statusLabel {
    if (!isSupported) {
      return 'Unavailable';
    }
    if (!notificationPermissionGranted) {
      return 'Needs permission';
    }
    if (!canUseFullScreenIntent) {
      return 'Check settings';
    }
    if (!notificationPolicyAccessGranted) {
      return 'DND access needed';
    }
    return 'Ready';
  }

  String get detailText {
    if (!isSupported) {
      return 'Native Android alerts are only available on the responder mobile app.';
    }
    if (!notificationPermissionGranted) {
      return 'Allow Android notifications so MissionOut can raise full-screen responder alerts.';
    }
    if (!canUseFullScreenIntent) {
      return 'Full-screen alerts are disabled for this app. Enable them in Android settings.';
    }
    if (!notificationPolicyAccessGranted) {
      return 'Grant Do Not Disturb access so urgent responder alerts can break through when the device is silenced.';
    }
    return 'Android alert permissions are ready for urgent responder interrupts.';
  }

  Future<void> initialize() async {
    if (!isSupported || _initialized) {
      return;
    }

    WidgetsBinding.instance.addObserver(this);
    _capabilities = await _bridge.initialize();
    _initialized = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!isSupported) {
      return;
    }

    _loading = true;
    notifyListeners();
    _capabilities = _initialized
        ? await _bridge.refreshCapabilities()
        : await _bridge.initialize();
    _loading = false;
    notifyListeners();
  }

  Future<void> requestNotificationPermission() async {
    if (!canRequestPermission) {
      return;
    }

    _loading = true;
    notifyListeners();
    _capabilities = await _bridge.requestNotificationPermission();
    _loading = false;
    notifyListeners();
  }

  Future<void> openNotificationPolicySettings() async {
    if (!canOpenPolicySettings) {
      return;
    }

    await _bridge.openNotificationPolicySettings();
  }

  Future<void> openFullScreenIntentSettings() async {
    if (!canOpenFullScreenSettings) {
      return;
    }

    await _bridge.openFullScreenIntentSettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _initialized) {
      unawaited(refresh());
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }
}
