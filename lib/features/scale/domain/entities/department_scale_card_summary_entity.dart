import 'package:client/features/scale/domain/entities/department_scale_with_lineup_entity.dart';
import 'package:client/features/scale/domain/entities/scale_role_assignments_entity.dart';
import 'package:equatable/equatable.dart';

class DepartmentScaleCardSummaryEntity extends Equatable {
  const DepartmentScaleCardSummaryEntity({
    required this.base,
    required this.roleSummaries,
    this.peopleLoadFailed = false,
  });

  final DepartmentScaleWithLineupEntity base;
  final List<ScaleRoleAssignmentsEntity> roleSummaries;
  final bool peopleLoadFailed;

  @override
  List<Object?> get props => [base, roleSummaries, peopleLoadFailed];
}
