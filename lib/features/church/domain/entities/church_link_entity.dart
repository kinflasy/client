import 'package:equatable/equatable.dart';

class ChurchLinkEntity extends Equatable {
  const ChurchLinkEntity({
    required this.id,
    required this.label,
    required this.url,
  });

  final String id;
  final String label;
  final String url;

  @override
  List<Object?> get props => [id, label, url];
}
