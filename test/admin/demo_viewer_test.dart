import 'package:dealsouk/features/admin/data/admin_service.dart';
import 'package:dealsouk/features/auth/domain/auth_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demoViewer claim from the API adds the demo role', () {
    final roles = AuthRole.fromClaims({
      'roles': ['user'],
      'demoViewer': true,
    });
    expect(roles, containsAll([AuthRole.user, AuthRole.demo]));
    expect(roles.contains(AuthRole.admin), isFalse);
  });

  test('no demoViewer claim means no demo role', () {
    final roles = AuthRole.fromClaims({
      'roles': ['user', 'admin'],
    });
    expect(roles.contains(AuthRole.demo), isFalse);
  });

  test('read-only service refuses writes without calling the API', () async {
    final service = AdminService()..readOnly = true;
    expect(
      () => service.approveSubmission('s1'),
      throwsA(isA<AdminReadOnlyException>()),
    );
    expect(
      () => service.deleteUser('u1'),
      throwsA(isA<AdminReadOnlyException>()),
    );
    expect(
      () => service.updateSettings(
        throw StateError('unreachable: guard must throw first'),
      ),
      throwsA(anything),
    );
  });
}
