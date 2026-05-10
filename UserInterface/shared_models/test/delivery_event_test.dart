import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('DeliveryEvent.fromJson', () {
    test('parses canonical delivery-event fields', () {
      final event = DeliveryEvent.fromJson({
        'title': 'Primary FCM burst completed',
        'detail': '12 Android devices received the first-wave push.',
        'time': '2020-01-01T12:00:00Z',
        'icon': 'task_alt',
        'color': '#4F6F95',
      });

      expect(event.title, 'Primary FCM burst completed');
      expect(
        event.detail,
        '12 Android devices received the first-wave push.',
      );
      expect(event.time, DateTime.utc(2020, 1, 1, 12));
      expect(event.iconKey, 'task_alt');
      expect(event.colorHex, '#4F6F95');
    });

    test('leaves icon and color null when absent', () {
      final event = DeliveryEvent.fromJson({
        'title': 'Plain event',
        'detail': '',
        'time': '',
      });

      expect(event.time, isNull);
      expect(event.iconKey, isNull);
      expect(event.colorHex, isNull);
    });
  });
}
