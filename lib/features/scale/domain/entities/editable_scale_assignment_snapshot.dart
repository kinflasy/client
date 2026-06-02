import 'package:client/features/scale/domain/entities/editable_scale_assignment_entity.dart';
import 'package:client/features/scale/domain/entities/scale_role_assignments_entity.dart';
import 'package:equatable/equatable.dart';

class EditableScaleAssignmentSnapshot extends Equatable {
  const EditableScaleAssignmentSnapshot({
    required this.original,
    required this.current,
  });

  factory EditableScaleAssignmentSnapshot.fromRoleAssignments(
    List<ScaleRoleAssignmentsEntity> roleAssignments,
  ) {
    var fallbackIndex = 0;
    final assignments = <EditableScaleAssignmentEntity>[];

    for (final roleAssignment in roleAssignments) {
      for (final person in roleAssignment.people) {
        final scaleItemId = person.scaleItemId;
        final localId = scaleItemId == null || scaleItemId.trim().isEmpty
            ? 'persisted:${roleAssignment.item.roleId}:${person.personId}:${fallbackIndex++}'
            : 'persisted:$scaleItemId';

        assignments.add(
          EditableScaleAssignmentEntity(
            localId: localId,
            scaleItemId: scaleItemId,
            roleId: roleAssignment.item.roleId,
            personId: person.personId,
            displayName: person.displayName,
            profileImageId: person.profileImageId,
            isPersisted: true,
          ),
        );
      }
    }

    return EditableScaleAssignmentSnapshot(
      original: List.unmodifiable(assignments),
      current: List.unmodifiable(assignments),
    );
  }

  static const empty = EditableScaleAssignmentSnapshot(
    original: [],
    current: [],
  );

  final List<EditableScaleAssignmentEntity> original;
  final List<EditableScaleAssignmentEntity> current;

  bool get hasPendingChanges => !_sameAssignments(original, current);

  EditableScaleAssignmentSnapshot addPerson({
    required String localId,
    required String roleId,
    required String personId,
    required String displayName,
    String? profileImageId,
  }) {
    return EditableScaleAssignmentSnapshot(
      original: original,
      current: List.unmodifiable([
        ...current,
        EditableScaleAssignmentEntity.local(
          localId: localId,
          roleId: roleId,
          personId: personId,
          displayName: displayName,
          profileImageId: profileImageId,
        ),
      ]),
    );
  }

  EditableScaleAssignmentSnapshot removeByLocalId(String localId) {
    return EditableScaleAssignmentSnapshot(
      original: original,
      current: List.unmodifiable(
        current.where((assignment) => assignment.localId != localId),
      ),
    );
  }

  List<EditableScaleAssignmentEntity> assignmentsForRole(String roleId) {
    return current
        .where((assignment) => assignment.roleId == roleId)
        .toList(growable: false);
  }

  @override
  List<Object?> get props => [original, current];
}

bool _sameAssignments(
  List<EditableScaleAssignmentEntity> left,
  List<EditableScaleAssignmentEntity> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
