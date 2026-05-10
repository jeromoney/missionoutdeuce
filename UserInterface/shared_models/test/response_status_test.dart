import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('ResponseStatus.fromLabel', () {
    test('decodes the canonical labels', () {
      expect(ResponseStatus.fromLabel('Responding'), ResponseStatus.responding);
      expect(ResponseStatus.fromLabel('Pending'), ResponseStatus.pending);
      expect(
        ResponseStatus.fromLabel('Not Available'),
        ResponseStatus.notAvailable,
      );
    });

    test('returns null for null, empty, or unknown labels', () {
      expect(ResponseStatus.fromLabel(null), isNull);
      expect(ResponseStatus.fromLabel(''), isNull);
      expect(ResponseStatus.fromLabel('Unknown'), isNull);
      expect(ResponseStatus.fromLabel('responding'), isNull);
    });
  });
}
