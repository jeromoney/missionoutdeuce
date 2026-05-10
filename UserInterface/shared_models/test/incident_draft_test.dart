import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('IncidentDraft', () {
    test('preserves required fields on construction', () {
      const draft = IncidentDraft(
        title: 'Field mission',
        location: 'North ridge',
        notes: 'Steep terrain.',
      );

      expect(draft.title, 'Field mission');
      expect(draft.location, 'North ridge');
      expect(draft.notes, 'Steep terrain.');
    });
  });

  group('IncidentUpdate', () {
    test('preserves required fields on construction', () {
      const update = IncidentUpdate(
        title: 'Field mission',
        location: 'North ridge',
        notes: 'Steep terrain.',
        active: false,
      );

      expect(update.title, 'Field mission');
      expect(update.location, 'North ridge');
      expect(update.notes, 'Steep terrain.');
      expect(update.active, isFalse);
    });

    test('accepts active true', () {
      const update = IncidentUpdate(
        title: '',
        location: '',
        notes: '',
        active: true,
      );

      expect(update.active, isTrue);
    });
  });
}
