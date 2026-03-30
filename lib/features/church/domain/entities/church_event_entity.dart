import 'package:equatable/equatable.dart';

class ChurchEventEntity extends Equatable {
  const ChurchEventEntity({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.description,
  });

  final String id;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? description;

  @override
  List<Object?> get props => [
        id,
        title,
        startDateTime,
        endDateTime,
        description,
      ];
}
