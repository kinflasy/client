class UpdatePendingMembershipRequestModel {
  const UpdatePendingMembershipRequestModel({
    required this.personId,
    required this.affiliation,
    this.entryMode,
    this.entryDate,
  });

  final String personId;
  final String affiliation;
  final String? entryMode;
  final String? entryDate;

  Map<String, dynamic> toJson() {
    return {
      'personId': personId,
      'affiliation': affiliation,
      if (entryMode != null) 'entryMode': entryMode,
      if (entryDate != null) 'entryDate': entryDate,
    };
  }
}
