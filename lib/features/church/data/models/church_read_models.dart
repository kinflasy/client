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
    this.address,
    this.website,
    this.instagramUrl,
    this.youtubeUrl,
    this.spotifyUrl,
    this.whatsappNumber,
    this.isHeadquarters,
    this.parentChurchId,
    this.parentChurchAcronym,
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
      address: _readAddress(json),
      website: json['website'] as String?,
      instagramUrl: _readNullableString(json, const [
        'instagramUrl',
        'instagram_url',
        'instagram',
      ]),
      youtubeUrl: _readNullableString(json, const [
        'youtubeUrl',
        'youtube_url',
        'youtube',
      ]),
      spotifyUrl: _readNullableString(json, const [
        'spotifyUrl',
        'spotify_url',
        'spotify',
      ]),
      whatsappNumber: _readNullableString(json, const [
        'whatsappNumber',
        'whatsapp_number',
        'whatsapp',
      ]),
      isHeadquarters: json['isHeadquarters'] as bool?,
      parentChurchId: json['parentChurchId'] as String?,
      parentChurchAcronym: json['parentChurchAcronym'] as String?,
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
  final String? address;
  final String? website;
  final String? instagramUrl;
  final String? youtubeUrl;
  final String? spotifyUrl;
  final String? whatsappNumber;
  final bool? isHeadquarters;
  final String? parentChurchId;
  final String? parentChurchAcronym;
}

class ChurchUnitReadModel {
  const ChurchUnitReadModel({
    required this.id,
    required this.churchId,
    this.name,
    this.slug,
    this.type,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.coverUrl,
  });

  factory ChurchUnitReadModel.fromJson(Map<String, dynamic> json) {
    return ChurchUnitReadModel(
      id: json['id'] as String,
      churchId: json['churchId'] as String,
      name: _readNullableString(json, const ['name']),
      slug: _readNullableString(json, const ['slug']),
      type: _readNullableString(json, const ['type']),
      address: _readAddress(json),
      phone: _readNullableString(json, const ['phone']),
      email: _readNullableString(json, const ['email']),
      logoUrl: _readNullableString(json, const [
        'logoUrl',
        'logo_url',
        'logoImageUrl',
        'logoImage',
      ]),
      coverUrl: _readNullableString(json, const [
        'coverUrl',
        'cover_url',
        'coverImageUrl',
        'coverImage',
      ]),
    );
  }

  final String id;
  final String churchId;
  final String? name;
  final String? slug;
  final String? type;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final String? coverUrl;
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
      name: (json['name'] ?? 'Departamento').toString(),
      slug: json['slug']?.toString(),
      type: json['type']?.toString(),
    );
  }

  final String id;
  final String name;
  final String? slug;
  final String? type;
}

/// Lê o endereço, que pode vir como objeto {street, city, ...} ou String direta.
String? _readAddress(Map<String, dynamic> json) {
  final raw = json['address'];
  if (raw == null) return null;
  if (raw is String && raw.trim().isNotEmpty) return raw.trim();
  if (raw is Map<String, dynamic>) {
    // Monta string legível: "Rua X, 123 - Bairro, Cidade - UF"
    final parts = <String>[
      if ((raw['street'] as String?)?.isNotEmpty == true)
        raw['street'] as String,
      if ((raw['number'] as String?)?.isNotEmpty == true)
        raw['number'] as String,
      if ((raw['neighborhood'] as String?)?.isNotEmpty == true)
        raw['neighborhood'] as String,
      if ((raw['city'] as String?)?.isNotEmpty == true) raw['city'] as String,
      if ((raw['state'] as String?)?.isNotEmpty == true) raw['state'] as String,
    ];
    final joined = parts.join(', ');
    return joined.isNotEmpty ? joined : null;
  }
  return null;
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
