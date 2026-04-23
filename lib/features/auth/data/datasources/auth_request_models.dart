import 'package:client/core/address/address_request_model.dart';

class LoginRequestModel {
  final String username;
  final String password;

  const LoginRequestModel({required this.username, required this.password});

  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class LoginResponseModel {
  final String token;

  const LoginResponseModel({required this.token});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(token: json['token'] as String);

  Map<String, dynamic> toJson() => {'token': token};
}

class RegisterRequestModel {
  final String fullName;
  final String username;
  final String email;
  final String password;
  final String gender;
  final String birthDate;
  final String? nickname;
  final String? phone;

  const RegisterRequestModel({
    required this.fullName,
    required this.username,
    required this.email,
    required this.password,
    required this.gender,
    required this.birthDate,
    this.nickname,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'username': username,
    'email': email,
    'password': password,
    'gender': gender,
    'birthDate': birthDate,
    if (nickname != null) 'nickname': nickname,
    if (phone != null) 'phone': phone,
  };
}

class UpdateLoggedUserRequestModel {
  const UpdateLoggedUserRequestModel({
    required this.fullName,
    required this.gender,
    required this.birthDate,
    this.nickname,
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

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    if (nickname != null) 'nickname': nickname,
    'gender': gender,
    'birthDate': birthDate,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (address != null) 'address': address!.toJson(),
  };
}
