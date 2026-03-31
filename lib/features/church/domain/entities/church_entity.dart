import 'package:equatable/equatable.dart';

class ChurchEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? acronym;
  final String? phone;
  final String email;
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

  const ChurchEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.acronym,
    this.phone,
    required this.email,
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

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        acronym,
        phone,
        email,
        coverUrl,
        logoUrl,
        address,
        website,
        instagramUrl,
        youtubeUrl,
        spotifyUrl,
        whatsappNumber,
        isHeadquarters,
        parentChurchId,
        parentChurchAcronym,
      ];
}
