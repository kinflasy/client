class ChurchReadModel {
  const ChurchReadModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.email,
    this.acronym,
    this.phone,
    this.coverUrl,
    this.logoUrl,
  });

  factory ChurchReadModel.fromJson(Map<String, dynamic> json) {
    return ChurchReadModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      email: json['email'] as String? ?? '',
      acronym: json['acronym'] as String?,
      phone: json['phone'] as String?,
      coverUrl: _readNullableString(json, const [
        'coverUrl',
        'cover_url',
        'coverImageUrl',
        'coverImage',
      ]),
      logoUrl: _readNullableString(json, const [
        'logoUrl',
        'logo_url',
        'logoImageUrl',
        'logoImage',
      ]),
    );
  }

  final String id;
  final String name;
  final String slug;
  final String email;
  final String? acronym;
  final String? phone;
  final String? coverUrl;
  final String? logoUrl;
}

class ChurchUnitReadModel {
  const ChurchUnitReadModel({
    required this.id,
    required this.churchId,
    this.name,
    this.slug,
  });

  factory ChurchUnitReadModel.fromJson(Map<String, dynamic> json) {
    return ChurchUnitReadModel(
      id: json['id'] as String,
      churchId: json['churchId'] as String,
      name: json['name'] as String?,
      slug: json['slug'] as String?,
    );
  }

  final String id;
  final String churchId;
  final String? name;
  final String? slug;
}

class ChurchEventReadModel {
  const ChurchEventReadModel({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.description,
  });

  factory ChurchEventReadModel.fromJson(Map<String, dynamic> json) {
    return ChurchEventReadModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Evento',
      description: json['description'] as String?,
      startDateTime: DateTime.parse(json['startDateTime'] as String),
      endDateTime: DateTime.parse(json['endDateTime'] as String),
    );
  }

  final String id;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? description;
}

class ChurchDepartmentReadModel {
  const ChurchDepartmentReadModel({
    required this.id,
    required this.name,
    this.slug,
    this.type,
  });

  factory ChurchDepartmentReadModel.fromJson(Map<String, dynamic> json) {
    return ChurchDepartmentReadModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Ministério').toString(),
      slug: json['slug']?.toString(),
      type: json['type']?.toString(),
    );
  }

  final String id;
  final String name;
  final String? slug;
  final String? type;
}

String? _readNullableString(
  Map<String, dynamic> json,
  List<String> candidateKeys,
) {
  for (final key in candidateKeys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}
