import 'package:equatable/equatable.dart';

class RoleEntity extends Equatable {
  const RoleEntity({required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;

  @override
  List<Object?> get props => [id, name, slug];
}
