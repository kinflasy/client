import 'package:equatable/equatable.dart';

class DepartmentEntity extends Equatable {
  const DepartmentEntity({
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
