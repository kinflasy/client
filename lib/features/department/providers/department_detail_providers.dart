import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final departmentDetailProvider =
    FutureProvider.family<DepartmentDetailEntity, String>((ref, departmentId) async {
  final result = await ref
      .read(departmentRepositoryProvider)
      .getDepartmentById(departmentId);

  return result.fold(
    (failure) => throw failure,
    (department) => department,
  );
});

final departmentParticipantsProvider =
    FutureProvider.family<List<DepartmentParticipantEntity>, String>((
  ref,
  departmentId,
) async {
  final result = await ref
      .read(departmentRepositoryProvider)
      .getParticipants(departmentId);

  return result.fold(
    (failure) => throw failure,
    (participants) => participants,
  );
});