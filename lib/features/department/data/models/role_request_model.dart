class RoleRequestModel {
  const RoleRequestModel({required this.name});

  final String name;

  Map<String, dynamic> toJson() => {'name': name};
}
