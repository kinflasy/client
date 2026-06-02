import 'package:equatable/equatable.dart';

class EditableScaleAssignmentEntity extends Equatable {
  const EditableScaleAssignmentEntity({
    required this.localId,
    required this.roleId,
    required this.personId,
    required this.displayName,
    required this.isPersisted,
    this.scaleItemId,
    this.profileImageId,
  });

  factory EditableScaleAssignmentEntity.persisted({
    required String roleId,
    required String personId,
    required String displayName,
    required String scaleItemId,
    String? profileImageId,
  }) {
    return EditableScaleAssignmentEntity(
      localId: 'persisted:$scaleItemId',
      scaleItemId: scaleItemId,
      roleId: roleId,
      personId: personId,
      displayName: displayName,
      profileImageId: profileImageId,
      isPersisted: true,
    );
  }

  factory EditableScaleAssignmentEntity.local({
    required String localId,
    required String roleId,
    required String personId,
    required String displayName,
    String? profileImageId,
  }) {
    return EditableScaleAssignmentEntity(
      localId: localId,
      roleId: roleId,
      personId: personId,
      displayName: displayName,
      profileImageId: profileImageId,
      isPersisted: false,
    );
  }

  final String localId;
  final String? scaleItemId;
  final String roleId;
  final String personId;
  final String displayName;
  final String? profileImageId;
  final bool isPersisted;

  @override
  List<Object?> get props => [
    localId,
    scaleItemId,
    roleId,
    personId,
    displayName,
    profileImageId,
    isPersisted,
  ];
}
