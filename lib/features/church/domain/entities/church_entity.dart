import 'package:equatable/equatable.dart';

class ChurchEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? acronym;
  final String? phone;
  final String email;

  const ChurchEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.acronym,
    this.phone,
    required this.email,
  });

  @override
  List<Object?> get props => [id, name, slug, acronym, phone, email];
}