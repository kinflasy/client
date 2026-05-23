import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:equatable/equatable.dart';

class LineupEntity extends Equatable {
  const LineupEntity({required this.id, required this.name, this.items});

  final String id;
  final String name;
  final List<LineupItemEntity>? items;

  @override
  List<Object?> get props => [id, name, items];
}
