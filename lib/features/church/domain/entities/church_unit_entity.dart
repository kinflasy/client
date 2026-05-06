import 'package:equatable/equatable.dart';

import '../../../../core/address/address_value.dart';

class ChurchUnitEntity extends Equatable {
  const ChurchUnitEntity({
    required this.id,
    required this.churchId,
    this.name,
    this.slug,
    this.type,
    this.address,
    this.addressValue,
    this.phone,
    this.email,
    this.logoUrl,
    this.coverUrl,
    this.profileImageId,
    this.coverImageId,
  });

  final String id;
  final String churchId;
  final String? name;
  final String? slug;
  final String? type;
  final String? address;
  final AddressValue? addressValue;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final String? coverUrl;
  final String? profileImageId;
  final String? coverImageId;

  @override
  List<Object?> get props => [
    id,
    churchId,
    name,
    slug,
    type,
    address,
    addressValue,
    phone,
    email,
    logoUrl,
    coverUrl,
    profileImageId,
    coverImageId,
  ];
}
