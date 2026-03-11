class LoginRequestModel {
  final String username;
  final String password;

  const LoginRequestModel({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
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