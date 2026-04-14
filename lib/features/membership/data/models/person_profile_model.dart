import 'package:client/features/membership/domain/enums/person_type.dart';

class PersonProfileModel {
  const PersonProfileModel({
    required this.type,
    required this.id,
    required this.fullName,
    this.nickname,
    required this.gender,
    this.birthDate,
    this.phone,
    this.addressId,
    this.age,
    this.email,
  });

  factory PersonProfileModel.fromJson(Map<String, dynamic> json) {
    final typeValue = json['type']?.toString();
    if (typeValue == null || typeValue.isEmpty) {
      throw const FormatException('Campo obrigatorio ausente: type');
    }

    final id = json['id']?.toString();
    final fullName = json['fullName']?.toString();
    final gender = json['gender']?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('Campo obrigatorio ausente: id');
    }
    if (fullName == null || fullName.isEmpty) {
      throw const FormatException('Campo obrigatorio ausente: fullName');
    }
    if (gender == null || gender.isEmpty) {
      throw const FormatException('Campo obrigatorio ausente: gender');
    }

    final birthDateRaw = json['birthDate']?.toString();
    final parsedBirthDate = birthDateRaw == null || birthDateRaw.isEmpty
        ? null
        : DateTime.tryParse(birthDateRaw);

    final ageRaw = json['age'];
    final parsedAge = switch (ageRaw) {
      int value => value,
      String value => int.tryParse(value),
      _ => null,
    };

    return PersonProfileModel(
      type: PersonType.fromApi(typeValue),
      id: id,
      fullName: fullName,
      nickname: json['nickname']?.toString(),
      gender: gender,
      birthDate: parsedBirthDate,
      phone: json['phone']?.toString(),
      addressId: json['addressId']?.toString(),
      age: parsedAge,
      email: json['email']?.toString(),
    );
  }

  final PersonType type;
  final String id;
  final String fullName;
  final String? nickname;
  final String gender;
  final DateTime? birthDate;
  final String? phone;
  final String? addressId;
  final int? age;
  final String? email;
}
