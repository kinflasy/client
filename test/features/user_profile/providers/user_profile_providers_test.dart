import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'returns no-membership permissions when memberships list is empty',
    () async {
      final permissions = await resolveSessionPermissions(
        memberships: const [],
        loadIntegrations: () async => const [],
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
      loadIntegrations: () async => const [
        IntegrationEntity(
          id: 'integration-1',
          membershipId: 'membership-1',
          departmentId: 'dept-1',
          departmentType: 'MINISTRY',
          integrationType: IntegrationType.integrant,
        ),
      ],
      checkUnitAdmin: (_) async => true,
    );

    expect(permissions.hasMembership, isTrue);
    expect(permissions.activeUnitId, 'unit-1');
    expect(permissions.isUnitAdmin, isTrue);
    expect(permissions.affiliation, Affiliation.unitAdmin);
    expect(permissions.integrations, hasLength(1));
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
      loadIntegrations: () async => const [],
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
      loadIntegrations: () async => const [],
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
      loadIntegrations: () async => const [],
      checkUnitAdmin: (_) async => throw Exception('offline'),
    );

    expect(permissions.isUnitAdmin, isFalse);
    expect(permissions.affiliation, Affiliation.member);
  });

  test(
    'falls back to empty integrations when loading integrations fails',
    () async {
      final permissions = await resolveSessionPermissions(
        memberships: const [
          MembershipEntity(
            id: 'membership-1',
            unitId: 'unit-1',
            affiliation: 'MEMBER',
          ),
        ],
        loadIntegrations: () async => throw Exception('offline'),
        checkUnitAdmin: (_) async => false,
      );

      expect(permissions.integrations, isEmpty);
    },
  );
}
