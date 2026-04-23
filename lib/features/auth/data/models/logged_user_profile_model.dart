import 'package:client/core/address/address_value.dart';
import 'package:client/features/auth/domain/entities/logged_user_profile_entity.dart';

class LoggedUserProfileModel {
  const LoggedUserProfileModel({
    required this.id,
    required this.fullName,
    this.nickname,
    required this.gender,
    this.birthDate,
    this.phone,
    this.email,
    this.addressId,
  });

  factory LoggedUserProfileModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final fullName = json['fullName']?.toString();
    final gender = json['gender']?.toString();

    if (id == null || id.isEmpty) {
      throw const FormatException('Campo obrigatório ausente: id');
    }
    if (fullName == null || fullName.isEmpty) {
      throw const FormatException('Campo obrigatório ausente: fullName');
    }
    if (gender == null || gender.isEmpty) {
      throw const FormatException('Campo obrigatório ausente: gender');
    }

    final birthDateRaw = json['birthDate']?.toString();

    return LoggedUserProfileModel(
      id: id,
      fullName: fullName,
      nickname: json['nickname']?.toString(),
      gender: gender,
      birthDate: birthDateRaw == null || birthDateRaw.isEmpty
          ? null
          : DateTime.tryParse(birthDateRaw),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      addressId: json['addressId']?.toString(),
    );
  }

  final String id;
  final String fullName;
  final String? nickname;
  final String gender;
  final DateTime? birthDate;
  final String? phone;
  final String? email;
  final String? addressId;

  LoggedUserProfileEntity toEntity({AddressValue? address}) {
    return LoggedUserProfileEntity(
      id: id,
      fullName: fullName,
      nickname: nickname,
      gender: gender,
      birthDate: birthDate,
      phone: phone,
      email: email,
      address: address ?? const AddressValue.empty(),
    );
  }
}
