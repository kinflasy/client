import 'package:client/features/scale/domain/entities/department_scale_with_lineup_entity.dart';
import 'package:client/features/scale/domain/entities/scale_role_assignments_entity.dart';
import 'package:equatable/equatable.dart';

class DepartmentScaleDetailEntity extends Equatable {
  const DepartmentScaleDetailEntity({
    required this.base,
    required this.roleAssignments,
    this.peopleLoadFailureMessage,
    this.profileFailurePersonIds = const [],
  });

  final DepartmentScaleWithLineupEntity base;
  final List<ScaleRoleAssignmentsEntity> roleAssignments;
  final String? peopleLoadFailureMessage;
  final List<String> profileFailurePersonIds;

  bool get hasPeoplePartialFailure =>
      peopleLoadFailureMessage != null || profileFailurePersonIds.isNotEmpty;

  @override
  List<Object?> get props => [
    base,
    roleAssignments,
    peopleLoadFailureMessage,
    profileFailurePersonIds,
  ];
}
