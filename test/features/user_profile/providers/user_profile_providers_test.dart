import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'returns no-membership permissions when memberships list is empty',
    () async {
      final permissions = await resolveSessionPermissions(
        memberships: const [],
        checkUnitAdmin: (_) async => true,
      );

      expect(permissions.hasMembership, isFalse);
      expect(permissions.activeUnitId, isNull);
      expect(permissions.isUnitAdmin, isFalse);
    },
  );

  test('promotes affiliation to unit admin when FGA allows access', () async {
    final permissions = await resolveSessionPermissions(
      memberships: const [
        MembershipEntity(
          id: 'membership-1',
          unitId: 'unit-1',
          affiliation: 'MEMBER',
        ),
      ],
      checkUnitAdmin: (_) async => true,
    );

    expect(permissions.hasMembership, isTrue);
    expect(permissions.activeUnitId, 'unit-1');
    expect(permissions.isUnitAdmin, isTrue);
    expect(permissions.affiliation, Affiliation.unitAdmin);
  });

  test('keeps base affiliation when FGA denies access', () async {
    final permissions = await resolveSessionPermissions(
      memberships: const [
        MembershipEntity(
          id: 'membership-1',
          unitId: 'unit-1',
          affiliation: 'CONGREGATED',
        ),
      ],
      checkUnitAdmin: (_) async => false,
    );

    expect(permissions.isUnitAdmin, isFalse);
    expect(permissions.affiliation, Affiliation.congregated);
  });

  test('maps unit admin affiliation from membership data', () async {
    final permissions = await resolveSessionPermissions(
      memberships: const [
        MembershipEntity(
          id: 'membership-1',
          unitId: 'unit-1',
          affiliation: 'UNIT_ADMIN',
        ),
      ],
      checkUnitAdmin: (_) async => false,
    );

    expect(permissions.isUnitAdmin, isFalse);
    expect(permissions.affiliation, Affiliation.unitAdmin);
  });

  test('fails closed when FGA check throws', () async {
    final permissions = await resolveSessionPermissions(
      memberships: const [
        MembershipEntity(
          id: 'membership-1',
          unitId: 'unit-1',
          affiliation: 'MEMBER',
        ),
      ],
      checkUnitAdmin: (_) async => throw Exception('offline'),
    );

    expect(permissions.isUnitAdmin, isFalse);
    expect(permissions.affiliation, Affiliation.member);
  });
}
