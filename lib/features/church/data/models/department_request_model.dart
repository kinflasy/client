class DepartmentRequestModel {
  const DepartmentRequestModel({
    required this.name,
    this.slug,
    required this.type,
  });

  final String name;
  final String? slug;
  final String type;

  Map<String, dynamic> toJson() {
    return {'name': name, 'slug': slug, 'type': type};
  }
}
