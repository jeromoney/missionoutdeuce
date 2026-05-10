import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('AuthRole', () {
    test('exposes the canonical labels', () {
      expect(AuthRole.dispatcher.label, 'Dispatcher');
      expect(AuthRole.responder.label, 'Responder');
      expect(AuthRole.teamAdmin.label, 'Team Admin');
      expect(AuthRole.superAdmin.label, 'Super Admin');
    });

    test('enumerates all roles in declaration order', () {
      expect(AuthRole.values, [
        AuthRole.dispatcher,
        AuthRole.responder,
        AuthRole.teamAdmin,
        AuthRole.superAdmin,
      ]);
    });
  });
}
