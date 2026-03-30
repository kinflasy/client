import 'package:equatable/equatable.dart';

class ChurchUnitEntity extends Equatable {
  const ChurchUnitEntity({
    required this.id,
    required this.churchId,
    this.name,
    this.slug,
  });

  final String id;
  final String churchId;
  final String? name;
  final String? slug;

  @override
  List<Object?> get props => [id, churchId, name, slug];
}
