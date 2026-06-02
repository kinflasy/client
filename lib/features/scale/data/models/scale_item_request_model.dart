class ScaleItemRequestModel {
  const ScaleItemRequestModel({required this.roleId, required this.personId});

  final String roleId;
  final String personId;

  Map<String, dynamic> toJson() => {'roleId': roleId, 'personId': personId};
}
