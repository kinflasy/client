import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/fga/fga_relations.dart';
import 'package:client/core/fga/fga_service.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/providers/member_profile_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_profile_providers.g.dart';

@riverpod
Future<SessionPermissions> sessionPermissions(Ref ref) async {
  final currentUser = await ref.watch(authProvider.future);
  if (currentUser == null) return const SessionPermissions.empty();

  final activeMembership = await ref.watch(activeMembershipProvider.future);
  if (activeMembership == null) {
    return const SessionPermissions(
      isAuthenticated: true,
      affiliation: null,
      activeUnitId: null,
      hasMembership: false,
      integrations: [],
      isUnitAdmin: false,
    );
  }

  return resolveSessionPermissions(
    activeMembership: activeMembership,
    loadIntegrations: () async {
      try {
        return await ref.read(myDepartmentIntegrationsProvider.future);
      } catch (_) {
        return const <IntegrationEntity>[];
      }
    },
    checkUnitAdmin: (unitId) => ref
        .read(fgaServiceProvider)
        .check(object: FgaObject.unit(unitId), relation: FgaRelation.admin),
  );
}

@riverpod
Affiliation? currentUserProfile(Ref ref) {
  final permissionsAsync = ref.watch(sessionPermissionsProvider);
  return permissionsAsync.whenOrNull(
    data: (permissions) => permissions.affiliation,
  );
}

Affiliation? _mapAffiliation(String value) {
  return switch (value.toUpperCase()) {
    'VISITOR' => Affiliation.visitor,
    'CONGREGATED' => Affiliation.congregated,
    'MEMBER' => Affiliation.member,
    'LEADER' => Affiliation.leader,
    'SOMA_LEADER' => Affiliation.somaLeader,
    'UNIT_ADMIN' => Affiliation.unitAdmin,
    _ => null,
  };
}

Future<SessionPermissions> resolveSessionPermissions({
  required MembershipEntity? activeMembership,
  required Future<List<IntegrationEntity>> Function() loadIntegrations,
  required Future<bool> Function(String unitId) checkUnitAdmin,
}) async {
  if (activeMembership == null) {
    return const SessionPermissions(
      isAuthenticated: true,
      affiliation: null,
      activeUnitId: null,
      hasMembership: false,
      integrations: [],
      isUnitAdmin: false,
    );
  }

  final affiliation = _mapAffiliation(activeMembership.affiliation);

  var isUnitAdmin = false;
  try {
    isUnitAdmin = await checkUnitAdmin(activeMembership.unitId);
  } catch (_) {
    isUnitAdmin = false;
  }

  List<IntegrationEntity> integrations;
  try {
    integrations = await loadIntegrations();
  } catch (_) {
    integrations = const [];
  }

  return SessionPermissions(
    isAuthenticated: true,
    affiliation: isUnitAdmin ? Affiliation.unitAdmin : affiliation,
    activeUnitId: activeMembership.unitId,
    hasMembership: true,
    integrations: integrations,
    isUnitAdmin: isUnitAdmin,
  );
}
