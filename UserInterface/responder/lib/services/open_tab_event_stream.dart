import 'open_tab_event_stream_base.dart';
import 'open_tab_event_stream_stub.dart'
    if (dart.library.html) 'open_tab_event_stream_web.dart';

OpenTabEventStream createOpenTabEventStream({required String streamUrl}) {
  return createOpenTabEventStreamImpl(streamUrl: streamUrl);
}
