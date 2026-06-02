import 'package:client/features/scale/data/models/scale_item_request_model.dart';
import 'package:client/features/scale/domain/entities/editable_scale_assignment_entity.dart';
import 'package:equatable/equatable.dart';

class ScaleAssignmentDiff extends Equatable {
  const ScaleAssignmentDiff({required this.toCreate, required this.toDelete});

  final List<ScaleItemRequestModel> toCreate;
  final List<ScaleItemRequestModel> toDelete;

  bool get isEmpty => toCreate.isEmpty && toDelete.isEmpty;

  @override
  List<Object?> get props => [toCreate, toDelete];
}

ScaleAssignmentDiff calculateScaleAssignmentDiff({
  required List<EditableScaleAssignmentEntity> original,
  required List<EditableScaleAssignmentEntity> current,
}) {
  final originalCounts = _countAssignments(original);
  final currentCounts = _countAssignments(current);

  final createQuota = <_AssignmentKey, int>{};
  for (final entry in currentCounts.entries) {
    final originalCount = originalCounts[entry.key] ?? 0;
    final difference = entry.value - originalCount;
    if (difference > 0) createQuota[entry.key] = difference;
  }

  final deleteQuota = <_AssignmentKey, int>{};
  for (final entry in originalCounts.entries) {
    final currentCount = currentCounts[entry.key] ?? 0;
    final difference = entry.value - currentCount;
    if (difference > 0) deleteQuota[entry.key] = difference;
  }

  return ScaleAssignmentDiff(
    toCreate: _requestsFromQuota(current, createQuota),
    toDelete: _requestsFromQuota(original, deleteQuota),
  );
}

Map<_AssignmentKey, int> _countAssignments(
  List<EditableScaleAssignmentEntity> assignments,
) {
  final counts = <_AssignmentKey, int>{};
  for (final assignment in assignments) {
    final key = _AssignmentKey(
      roleId: assignment.roleId,
      personId: assignment.personId,
    );
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
}

List<ScaleItemRequestModel> _requestsFromQuota(
  List<EditableScaleAssignmentEntity> assignments,
  Map<_AssignmentKey, int> quota,
) {
  final requests = <ScaleItemRequestModel>[];
  final remaining = Map<_AssignmentKey, int>.from(quota);

  for (final assignment in assignments) {
    final key = _AssignmentKey(
      roleId: assignment.roleId,
      personId: assignment.personId,
    );
    final count = remaining[key] ?? 0;
    if (count <= 0) continue;

    requests.add(
      ScaleItemRequestModel(
        roleId: assignment.roleId,
        personId: assignment.personId,
      ),
    );
    if (count == 1) {
      remaining.remove(key);
    } else {
      remaining[key] = count - 1;
    }
  }

  return requests;
}

class _AssignmentKey extends Equatable {
  const _AssignmentKey({required this.roleId, required this.personId});

  final String roleId;
  final String personId;

  @override
  List<Object?> get props => [roleId, personId];
}
