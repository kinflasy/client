import 'package:equatable/equatable.dart';

enum ScaleAssignmentPersonSource { participant, profileFallback, notFound }

class ScaleAssignmentPersonEntity extends Equatable {
  const ScaleAssignmentPersonEntity({
    required this.personId,
    required this.displayName,
    this.profileImageId,
    this.scaleItemId,
    required this.source,
  });

  final String personId;
  final String displayName;
  final String? profileImageId;
  final String? scaleItemId;
  final ScaleAssignmentPersonSource source;

  bool get isNotFound => source == ScaleAssignmentPersonSource.notFound;

  ScaleAssignmentPersonEntity copyWith({String? scaleItemId}) {
    return ScaleAssignmentPersonEntity(
      personId: personId,
      displayName: displayName,
      profileImageId: profileImageId,
      scaleItemId: scaleItemId ?? this.scaleItemId,
      source: source,
    );
  }

  @override
  List<Object?> get props => [
    personId,
    displayName,
    profileImageId,
    scaleItemId,
    source,
  ];
}
