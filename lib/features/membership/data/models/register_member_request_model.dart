class InactivePersonRequestModel {
  const InactivePersonRequestModel({
    required this.fullName,
    this.nickname,
    required this.gender,
    required this.birthDate,
    this.phone,
    this.email,
    this.churchId,
  });

  final String fullName;
  final String? nickname;
  final String gender;
  final String birthDate;
  final String? phone;
  final String? email;
  final String? churchId;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      if (nickname != null) 'nickname': nickname,
      'gender': gender,
      'birthDate': birthDate,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (churchId != null) 'churchId': churchId,
    };
  }
}

class RegisterMemberRequestModel {
  const RegisterMemberRequestModel({
    required this.person,
    required this.affiliation,
    this.entryMode,
    this.entryDate,
  });

  final InactivePersonRequestModel person;
  final String affiliation;
  final String? entryMode;
  final String? entryDate;

  Map<String, dynamic> toJson() {
    return {
      'person': person.toJson(),
      'affiliation': affiliation,
      if (entryMode != null) 'entryMode': entryMode,
      if (entryDate != null) 'entryDate': entryDate,
    };
  }
}
