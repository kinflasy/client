import 'package:client/core/domain/enums/integration_type.dart';
import 'package:equatable/equatable.dart';

class IntegrationEntity extends Equatable {
  const IntegrationEntity({
    required this.id,
    required this.membershipId,
    required this.departmentId,
    required this.departmentType,
    required this.integrationType,
  });

  final String id;
  final String membershipId;
  final String departmentId;
  final String departmentType;
  final IntegrationType integrationType;

  @override
  List<Object?> get props => [
    id,
    membershipId,
    departmentId,
    departmentType,
    integrationType,
  ];
}
