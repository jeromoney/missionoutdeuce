import '../models/open_tab_event.dart';

abstract class OpenTabEventStream {
  Stream<OpenTabEvent> get events;

  Future<void> connect({required String userEmail});

  void dispose();
}
