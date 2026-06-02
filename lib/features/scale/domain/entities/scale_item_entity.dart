import 'package:equatable/equatable.dart';

class ScaleItemEntity extends Equatable {
  const ScaleItemEntity({
    required this.id,
    required this.scaleId,
    required this.roleId,
    required this.personId,
  });

  final String id;
  final String scaleId;
  final String roleId;
  final String personId;

  @override
  List<Object?> get props => [id, scaleId, roleId, personId];
}
