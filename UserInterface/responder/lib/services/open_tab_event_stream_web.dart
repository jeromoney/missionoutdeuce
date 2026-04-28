import 'dart:async';
import 'dart:js_interop' as js;

import '../models/open_tab_event.dart';
import 'open_tab_event_stream_base.dart';

@js.JS('missionOutEventStream')
external _MissionOutEventStreamBridge? get _bridge;

@js.JS()
extension type _MissionOutEventStreamBridge._(js.JSObject _)
    implements js.JSObject {
  external js.JSObject connect(
    String url,
    String accessToken,
    js.JSFunction onEvent,
    js.JSFunction onError,
  );

  external void close(js.JSObject handle);
}

class _WebOpenTabEventStream implements OpenTabEventStream {
  _WebOpenTabEventStream({required this.streamUrl});

  final String streamUrl;
  final StreamController<OpenTabEvent> _eventsController =
      StreamController<OpenTabEvent>.broadcast();

  Timer? _reconnectTimer;
  js.JSObject? _connectionHandle;
  bool _disposed = false;
  String _accessToken = '';

  @override
  Stream<OpenTabEvent> get events => _eventsController.stream;

  @override
  Future<void> connect({required String accessToken}) async {
    if (_disposed || _connectionHandle != null || accessToken.trim().isEmpty) {
      return;
    }

    _accessToken = accessToken.trim();
    final bridge = _bridge;
    if (bridge == null) {
      return;
    }

    _connectionHandle = bridge.connect(
      streamUrl,
      _accessToken,
      ((String type, String data) {
        _emitEvent(type: type, data: data);
      }).toJS,
      ((String message) {
        _scheduleReconnect(message);
      }).toJS,
    );
  }

  void _emitEvent({required String type, required String data}) {
    try {
      _eventsController.add(OpenTabEvent.fromPayload(type: type, data: data));
    } on FormatException {
      // Ignore malformed transport messages and wait for the next event.
    }
  }

  void _scheduleReconnect(String message) {
    _closeConnection();
    if (_disposed || _reconnectTimer != null || message == '401') {
      return;
    }

    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      _reconnectTimer = null;
      connect(accessToken: _accessToken);
    });
  }

  void _closeConnection() {
    final bridge = _bridge;
    final handle = _connectionHandle;
    if (bridge == null || handle == null) {
      _connectionHandle = null;
      return;
    }

    bridge.close(handle);
    _connectionHandle = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _closeConnection();
    _eventsController.close();
  }
}

OpenTabEventStream createOpenTabEventStreamImpl({required String streamUrl}) {
  return _WebOpenTabEventStream(streamUrl: streamUrl);
}
