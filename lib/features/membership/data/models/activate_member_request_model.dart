class ActivateMemberRequestModel {
  const ActivateMemberRequestModel({
    required this.inactivePersonId,
    required this.username,
  });

  final String inactivePersonId;
  final String username;

  Map<String, dynamic> toJson() {
    return {'inactivePersonId': inactivePersonId, 'username': username};
  }
}
