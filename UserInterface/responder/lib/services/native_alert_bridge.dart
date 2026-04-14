import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeAlertCapabilities {
  const NativeAlertCapabilities({
    required this.supportsPostNotifications,
    required this.supportsFullScreenIntentManagement,
    required this.notificationPermissionGranted,
    required this.notificationPolicyAccessGranted,
    required this.canUseFullScreenIntent,
  });

  const NativeAlertCapabilities.unsupported()
    : supportsPostNotifications = false,
      supportsFullScreenIntentManagement = false,
      notificationPermissionGranted = false,
      notificationPolicyAccessGranted = false,
      canUseFullScreenIntent = false;

  final bool supportsPostNotifications;
  final bool supportsFullScreenIntentManagement;
  final bool notificationPermissionGranted;
  final bool notificationPolicyAccessGranted;
  final bool canUseFullScreenIntent;

  factory NativeAlertCapabilities.fromMap(Map<dynamic, dynamic> map) {
    return NativeAlertCapabilities(
      supportsPostNotifications:
          map['supportsPostNotifications'] as bool? ?? false,
      supportsFullScreenIntentManagement:
          map['supportsFullScreenIntentManagement'] as bool? ?? false,
      notificationPermissionGranted:
          map['notificationPermissionGranted'] as bool? ?? false,
      notificationPolicyAccessGranted:
          map['notificationPolicyAccessGranted'] as bool? ?? false,
      canUseFullScreenIntent: map['canUseFullScreenIntent'] as bool? ?? false,
    );
  }
}

class NativeAlertEvent {
  const NativeAlertEvent({
    required this.action,
    required this.incidentPublicId,
    required this.title,
    required this.body,
  });

  final String action;
  final String incidentPublicId;
  final String title;
  final String body;

  bool get isReceived => action == 'received';
  bool get isResponding => action == 'responding';
  bool get isNotAvailable => action == 'not_available';

  factory NativeAlertEvent.fromMap(Map<dynamic, dynamic> map) {
    return NativeAlertEvent(
      action: map['action'] as String? ?? '',
      incidentPublicId: map['incidentPublicId'] as String? ?? '',
      title: map['title'] as String? ?? 'Mission alert',
      body: map['body'] as String? ?? '',
    );
  }
}

class NativeAlertBridge {
  static const _methodChannel = MethodChannel(
    'com.missionout.responder/native_alert',
  );
  static const _eventChannel = EventChannel(
    'com.missionout.responder/native_alert_events',
  );

  Stream<NativeAlertEvent>? _events;
  bool? _supported;
  NativeAlertCapabilities _capabilities =
      const NativeAlertCapabilities.unsupported();

  bool get isSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android;
  }

  NativeAlertCapabilities get capabilities => _capabilities;

  Future<NativeAlertCapabilities> initialize() async {
    if (!isSupported) {
      _supported = false;
      _capabilities = const NativeAlertCapabilities.unsupported();
      return _capabilities;
    }

    try {
      final response = await _methodChannel.invokeMethod<Object?>('initialize');
      _supported = true;
      _capabilities = _parseCapabilities(response);
    } on MissingPluginException {
      _supported = false;
      _capabilities = const NativeAlertCapabilities.unsupported();
    } on PlatformException {
      _supported = false;
      _capabilities = const NativeAlertCapabilities.unsupported();
    }
    return _capabilities;
  }

  Future<NativeAlertCapabilities> refreshCapabilities() async {
    if (!isSupported || _supported == false) {
      return _capabilities;
    }

    try {
      final response = await _methodChannel.invokeMethod<Object?>(
        'refreshCapabilities',
      );
      _supported = true;
      _capabilities = _parseCapabilities(response);
    } on MissingPluginException {
      _supported = false;
      _capabilities = const NativeAlertCapabilities.unsupported();
    } on PlatformException {
      _supported = false;
      _capabilities = const NativeAlertCapabilities.unsupported();
    }
    return _capabilities;
  }

  Future<NativeAlertCapabilities> requestNotificationPermission() async {
    if (!isSupported || _supported == false) {
      return _capabilities;
    }

    try {
      final response = await _methodChannel.invokeMethod<Object?>(
        'requestNotificationPermission',
      );
      _supported = true;
      _capabilities = _parseCapabilities(response);
    } on MissingPluginException {
      _supported = false;
      _capabilities = const NativeAlertCapabilities.unsupported();
    } on PlatformException {
      _supported = false;
      _capabilities = const NativeAlertCapabilities.unsupported();
    }
    return _capabilities;
  }

  Future<void> openNotificationPolicySettings() async {
    if (!isSupported || _supported == false) {
      return;
    }

    try {
      await _methodChannel.invokeMethod<void>('openNotificationPolicySettings');
    } on MissingPluginException {
      _supported = false;
    } on PlatformException {
      _supported = false;
    }
  }

  Future<void> openFullScreenIntentSettings() async {
    if (!isSupported || _supported == false) {
      return;
    }

    try {
      await _methodChannel.invokeMethod<void>('openFullScreenIntentSettings');
    } on MissingPluginException {
      _supported = false;
    } on PlatformException {
      _supported = false;
    }
  }

  Future<void> showNativeAlert({
    required String incidentPublicId,
    required String title,
    required String body,
  }) async {
    if (!isSupported || _supported == false) {
      return;
    }

    try {
      await _methodChannel.invokeMethod<void>('showNativeAlert', {
        'incidentPublicId': incidentPublicId,
        'title': title,
        'body': body,
      });
    } on MissingPluginException {
      _supported = false;
    } on PlatformException {
      _supported = false;
    }
  }

  Future<void> dismissActiveAlert() async {
    if (!isSupported || _supported == false) {
      return;
    }

    try {
      await _methodChannel.invokeMethod<void>('dismissActiveAlert');
    } on MissingPluginException {
      _supported = false;
    } on PlatformException {
      _supported = false;
    }
  }

  Stream<NativeAlertEvent> get events {
    if (!isSupported) {
      return const Stream<NativeAlertEvent>.empty();
    }

    return _events ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) {
          if (event is Map<dynamic, dynamic>) {
            return NativeAlertEvent.fromMap(event);
          }
          throw const FormatException('Unexpected native alert event payload.');
        })
        .handleError((Object _, StackTrace __) {})
        .asBroadcastStream();
  }

  NativeAlertCapabilities _parseCapabilities(Object? response) {
    final map = response;
    if (map is Map<dynamic, dynamic>) {
      return NativeAlertCapabilities.fromMap(map);
    }
    return const NativeAlertCapabilities.unsupported();
  }
}

final nativeAlertBridge = NativeAlertBridge();
