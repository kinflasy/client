import 'package:client/core/address/address_request_model.dart';

class UpdateInactivePersonRequestModel {
  const UpdateInactivePersonRequestModel({
    required this.fullName,
    this.nickname,
    required this.gender,
    required this.birthDate,
    this.phone,
    this.email,
    this.address,
  });

  final String fullName;
  final String? nickname;
  final String gender;
  final String birthDate;
  final String? phone;
  final String? email;
  final AddressRequestModel? address;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      if (nickname != null) 'nickname': nickname,
      'gender': gender,
      'birthDate': birthDate,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address!.toJson(),
    };
  }
}
