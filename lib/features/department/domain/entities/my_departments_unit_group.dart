import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:equatable/equatable.dart';

class MyDepartmentsUnitGroup extends Equatable {
  const MyDepartmentsUnitGroup({
    required this.unitId,
    required this.unitName,
    required this.departments,
  });

  final String unitId;
  final String unitName;
  final List<DepartmentEntity> departments;

  @override
  List<Object?> get props => [unitId, unitName, departments];
}
