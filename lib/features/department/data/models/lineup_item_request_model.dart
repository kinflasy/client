class LineupItemRequestModel {
  const LineupItemRequestModel({
    required this.roleId,
    required this.description,
  });

  final String roleId;
  final String description;

  Map<String, dynamic> toJson() => {
    'roleId': roleId,
    'description': description,
  };
}

class LineupItemUpdateRequestModel {
  const LineupItemUpdateRequestModel({required this.description});

  final String description;

  Map<String, dynamic> toJson() => {'description': description};
}
