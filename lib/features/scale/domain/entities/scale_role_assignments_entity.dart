import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/scale/domain/entities/scale_assignment_person_entity.dart';
import 'package:equatable/equatable.dart';

class ScaleRoleAssignmentsEntity extends Equatable {
  const ScaleRoleAssignmentsEntity({
    required this.item,
    required this.people,
    this.capacity = 1,
  });

  final LineupItemEntity item;
  final List<ScaleAssignmentPersonEntity> people;
  final int capacity;

  int get openVacancyCount {
    final count = capacity - people.length;
    return count < 0 ? 0 : count;
  }

  bool get hasOpenVacancy => openVacancyCount > 0;

  @override
  List<Object?> get props => [item, people, capacity];
}
