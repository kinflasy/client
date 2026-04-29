import 'package:equatable/equatable.dart';

class DepartmentDetailEntity extends Equatable {
  const DepartmentDetailEntity({
    required this.id,
    required this.name,
    this.slug,
    this.type,
  });

  final String id;
  final String name;
  final String? slug;
  final String? type;

  @override
  List<Object?> get props => [id, name, slug, type];
}