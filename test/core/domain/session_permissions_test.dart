import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const departmentId = 'dept-1';

  test('leader can edit and manage department', () {
    final permissions = _permissionsFor(IntegrationType.leader);

    expect(permissions.canEditDept(departmentId), isTrue);
    expect(permissions.canManageDept(departmentId), isTrue);
  });

  test('unit admin can edit and manage department', () {
    const permissions = SessionPermissions(
      isAuthenticated: true,
      affiliation: Affiliation.unitAdmin,
      activeUnitId: 'unit-1',
      hasMembership: true,
      integrations: [],
      isUnitAdmin: true,
    );

    expect(permissions.canEditDept(departmentId), isTrue);
    expect(permissions.canManageDept(departmentId), isTrue);
  });

  test('assistant can manage but cannot edit department', () {
    final permissions = _permissionsFor(IntegrationType.assistant);

    expect(permissions.canEditDept(departmentId), isFalse);
    expect(permissions.canManageDept(departmentId), isTrue);
  });

  test('non-management roles cannot edit or manage department', () {
    for (final role in [
      IntegrationType.integrant,
      IntegrationType.consultant,
      IntegrationType.observer,
    ]) {
      final permissions = _permissionsFor(role);

      expect(
        permissions.canEditDept(departmentId),
        isFalse,
        reason: '$role should not edit department',
      );
      expect(
        permissions.canManageDept(departmentId),
        isFalse,
        reason: '$role should not manage department',
      );
    }
  });
}

SessionPermissions _permissionsFor(IntegrationType role) {
  return SessionPermissions(
    isAuthenticated: true,
    affiliation: Affiliation.member,
    activeUnitId: 'unit-1',
    hasMembership: true,
    integrations: [
      IntegrationEntity(
        id: 'integration-1',
        membershipId: 'membership-1',
        departmentId: 'dept-1',
        departmentType: 'MINISTRY',
        integrationType: role,
      ),
    ],
    isUnitAdmin: false,
  );
}
