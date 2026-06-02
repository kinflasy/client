import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/scale/domain/entities/scale_assignment_person_entity.dart';
import 'package:equatable/equatable.dart';

class ScaleRoleAssignmentsEntity extends Equatable {
  const ScaleRoleAssignmentsEntity({required this.item, required this.people});

  final LineupItemEntity item;
  final List<ScaleAssignmentPersonEntity> people;

  bool get hasOpenVacancy => people.isEmpty;

  @override
  List<Object?> get props => [item, people];
}
