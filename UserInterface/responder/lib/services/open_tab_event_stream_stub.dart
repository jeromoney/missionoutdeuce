import 'dart:async';

import '../models/open_tab_event.dart';
import 'open_tab_event_stream_base.dart';

class _StubOpenTabEventStream implements OpenTabEventStream {
  final StreamController<OpenTabEvent> _eventsController =
      StreamController<OpenTabEvent>.broadcast();

  @override
  Stream<OpenTabEvent> get events => _eventsController.stream;

  @override
  Future<void> connect({required String userEmail}) async {}

  @override
  void dispose() {
    _eventsController.close();
  }
}

OpenTabEventStream createOpenTabEventStreamImpl({required String streamUrl}) {
  return _StubOpenTabEventStream();
}
