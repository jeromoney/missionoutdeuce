import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('AvailabilityStatus', () {
    test('exposes the canonical labels', () {
      expect(AvailabilityStatus.available.label, 'Available');
      expect(AvailabilityStatus.unavailable.label, 'Unavailable');
    });

    test('enumerates all statuses in declaration order', () {
      expect(AvailabilityStatus.values, [
        AvailabilityStatus.available,
        AvailabilityStatus.unavailable,
      ]);
    });
  });
}
