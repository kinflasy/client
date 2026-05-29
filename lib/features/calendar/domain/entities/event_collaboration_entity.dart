import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:equatable/equatable.dart';

class EventCollaborationEntity extends Equatable {
  const EventCollaborationEntity({
    required this.id,
    required this.calendarEventId,
    required this.departmentId,
    this.department,
  });

  final String id;
  final String calendarEventId;
  final String departmentId;
  final DepartmentEntity? department;

  @override
  List<Object?> get props => [id, calendarEventId, departmentId, department];
}
