import 'package:flutter_test/flutter_test.dart';
import 'package:student_cabinet_flutter_app/shared/auth_role.dart';

void main() {
  group('appUserRoleFromClaims', () {
    test('reads student role from app metadata claims', () {
      expect(
        appUserRoleFromClaims(<String, dynamic>{'role': 'student'}),
        AppUserRole.student,
      );
    });

    test('normalizes case and whitespace', () {
      expect(
        appUserRoleFromClaims(<String, dynamic>{'role': ' Teacher '}),
        AppUserRole.teacher,
      );
    });

    test('returns null for unknown role', () {
      expect(
        appUserRoleFromClaims(<String, dynamic>{'role': 'manager'}),
        isNull,
      );
    });
  });
}
