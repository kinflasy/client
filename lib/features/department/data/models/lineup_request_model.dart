class LineupRequestModel {
  const LineupRequestModel({required this.name});

  final String name;

  Map<String, dynamic> toJson() => {'name': name};
}
