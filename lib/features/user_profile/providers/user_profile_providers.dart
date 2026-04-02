import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_profile_providers.g.dart';

@riverpod
Future<SessionPermissions> sessionPermissions(Ref ref) async {
  final currentUser = await ref.watch(authProvider.future);
  if (currentUser == null) return const SessionPermissions.empty();

  final memberships = await ref.watch(membershipProvider.future);
  if (memberships.isEmpty) {
    return const SessionPermissions(
      isAuthenticated: true,
      affiliation: null,
      activeUnitId: null,
      hasMembership: false,
      integrations: [],
      isUnitAdmin: false,
    );
  }

  final firstMembership = memberships.first;
  final membershipResult = await ref
      .read(membershipRepositoryProvider)
      .getMembershipByUnitAndPerson(firstMembership.unitId, currentUser.id);

  final activeMembership = membershipResult.fold(
    (_) => firstMembership,
    (membership) => membership,
  );

  final affiliation = _mapAffiliation(activeMembership.affiliation);

  List<IntegrationEntity> integrations = const [];
  if (affiliation == Affiliation.congregated ||
      affiliation == Affiliation.member) {
    final integrationsResult = await ref
        .read(membershipRepositoryProvider)
        .getIntegrationsByMembershipId(activeMembership.id);
    integrations = integrationsResult.fold((_) => const [], (value) => value);
  }

  var isUnitAdmin = false;
  final departmentsApi = ref.read(churchDepartmentsApiProvider);
  final adminLeaderIntegrations = integrations.where(
    (integration) =>
        integration.departmentType == 'ADMINISTRATIVE' &&
        integration.integrationType == IntegrationType.leader,
  );

  for (final integration in adminLeaderIntegrations) {
    try {
      await departmentsApi.getDepartmentExtension(
        integration.departmentId,
        'SOMA',
      );
      isUnitAdmin = true;
      break;
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) rethrow;
    }
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

@riverpod
Affiliation? currentUserProfile(Ref ref) {
  final permissionsAsync = ref.watch(sessionPermissionsProvider);
  return permissionsAsync.whenOrNull(data: (permissions) => permissions.affiliation);
}

Affiliation? _mapAffiliation(String value) {
  return switch (value.toUpperCase()) {
    'VISITOR' => Affiliation.visitor,
    'CONGREGATED' => Affiliation.congregated,
    'MEMBER' => Affiliation.member,
    _ => null,
  };
}
