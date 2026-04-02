import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';

class SessionPermissions {
  const SessionPermissions({
    required this.isAuthenticated,
    required this.affiliation,
    required this.activeUnitId,
    required this.hasMembership,
    required this.integrations,
    required this.isUnitAdmin,
  });

  const SessionPermissions.empty()
    : isAuthenticated = false,
      affiliation = null,
      activeUnitId = null,
      hasMembership = false,
      integrations = const [],
      isUnitAdmin = false;

  final bool isAuthenticated;
  final Affiliation? affiliation;
  final String? activeUnitId;
  final bool hasMembership;
  final List<IntegrationEntity> integrations;
  final bool isUnitAdmin;

  bool get isVisitor => affiliation == Affiliation.visitor;

  bool get isCongregatedOrAbove =>
      affiliation == Affiliation.congregated || isMember;

  bool get isMember =>
      affiliation == Affiliation.member ||
      affiliation == Affiliation.somaLeader ||
      affiliation == Affiliation.unitAdmin ||
      isUnitAdmin;

  bool canSeeAdminArea() => isMember || isUnitAdmin;

  bool canManageUnit() => isUnitAdmin;

  IntegrationType? roleInDept(String departmentId) {
    for (final integration in integrations) {
      if (integration.departmentId == departmentId) {
        return integration.integrationType;
      }
    }
    return null;
  }

  bool canObserveDept(String departmentId) =>
      isUnitAdmin || roleInDept(departmentId) != null;

  bool canManageDept(String departmentId) {
    if (isUnitAdmin) return true;
    final role = roleInDept(departmentId);
    return role == IntegrationType.leader || role == IntegrationType.assistant;
  }

  bool canApproveDeptRequests(String departmentId) =>
      canManageDept(departmentId);
}
