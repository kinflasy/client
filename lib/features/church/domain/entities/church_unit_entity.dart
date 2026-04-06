import 'package:equatable/equatable.dart';

class ChurchUnitEntity extends Equatable {
  const ChurchUnitEntity({
    required this.id,
    required this.churchId,
    this.name,
    this.slug,
    this.type,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.coverUrl,
  });

  final String id;
  final String churchId;
  final String? name;
  final String? slug;
  final String? type;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final String? coverUrl;

  @override
  List<Object?> get props => [
    id,
    churchId,
    name,
    slug,
    type,
    address,
    phone,
    email,
    logoUrl,
    coverUrl,
  ];
}
