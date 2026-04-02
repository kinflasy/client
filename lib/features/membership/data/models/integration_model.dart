import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';

class IntegrationModel {
  const IntegrationModel({
    required this.id,
    required this.membershipId,
    required this.departmentId,
    required this.departmentType,
    required this.integrationType,
  });

  factory IntegrationModel.fromJson(Map<String, dynamic> json) {
    return IntegrationModel(
      id: (json['id'] ?? '').toString(),
      membershipId: (json['membershipId'] ?? '').toString(),
      departmentId: (json['departmentId'] ?? '').toString(),
      departmentType: (json['departmentType'] ?? 'MINISTRY').toString(),
      integrationType: IntegrationType.fromString(
        (json['type'] ?? 'OBSERVER').toString(),
      ),
    );
  }

  final String id;
  final String membershipId;
  final String departmentId;
  final String departmentType;
  final IntegrationType integrationType;

  IntegrationEntity toEntity() {
    return IntegrationEntity(
      id: id,
      membershipId: membershipId,
      departmentId: departmentId,
      departmentType: departmentType,
      integrationType: integrationType,
    );
  }
}
