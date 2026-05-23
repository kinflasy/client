import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:equatable/equatable.dart';

class LineupItemEntity extends Equatable {
  const LineupItemEntity({
    required this.id,
    required this.lineupId,
    required this.roleId,
    required this.description,
    this.role,
  });

  final String id;
  final String lineupId;
  final String roleId;
  final String description;
  final RoleEntity? role;

  @override
  List<Object?> get props => [id, lineupId, roleId, description, role];
}
