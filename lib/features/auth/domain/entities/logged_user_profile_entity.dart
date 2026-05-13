import 'package:client/core/address/address_value.dart';
import 'package:equatable/equatable.dart';

class LoggedUserProfileEntity extends Equatable {
  const LoggedUserProfileEntity({
    required this.id,
    required this.fullName,
    this.nickname,
    required this.gender,
    this.birthDate,
    this.phone,
    this.email,
    this.address = const AddressValue.empty(),
    this.profileImageId,
  });

  final String id;
  final String fullName;
  final String? nickname;
  final String gender;
  final DateTime? birthDate;
  final String? phone;
  final String? email;
  final AddressValue address;
  final String? profileImageId;

  @override
  List<Object?> get props => [
    id,
    fullName,
    nickname,
    gender,
    birthDate,
    phone,
    email,
    address,
    profileImageId,
  ];
}
