class JoinMembershipRequestModel {
  const JoinMembershipRequestModel({required this.affiliation});

  final String affiliation;

  Map<String, dynamic> toJson() {
    return {'affiliation': affiliation};
  }
}
