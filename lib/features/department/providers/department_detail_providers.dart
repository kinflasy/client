import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/department/data/models/integration_request_model.dart';
import 'package:client/features/department/domain/entities/add_department_participants_result.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/providers/member_profile_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final departmentDetailProvider =
    FutureProvider.family<DepartmentDetailEntity, String>((
      ref,
      departmentId,
    ) async {
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

final addDepartmentParticipantsProvider =
    NotifierProvider<AddDepartmentParticipantsNotifier, AsyncValue<void>>(
      AddDepartmentParticipantsNotifier.new,
    );

class AddDepartmentParticipantsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<AddDepartmentParticipantsResult> addParticipants({
    required String departmentId,
    required List<String> membershipIds,
  }) async {
    state = const AsyncLoading();

    var successCount = 0;
    var failureCount = 0;
    final uniqueMembershipIds = membershipIds.toSet();

    for (final membershipId in uniqueMembershipIds) {
      final result = await ref
          .read(departmentRepositoryProvider)
          .addParticipant(
            departmentId,
            IntegrationRequestModel(membershipId: membershipId),
          );
      result.match((_) => failureCount++, (_) => successCount++);
    }

    if (successCount > 0) {
      ref.invalidate(departmentParticipantsProvider(departmentId));
    }

    final activeMembership = await ref.read(activeMembershipProvider.future);
    if (activeMembership != null &&
        uniqueMembershipIds.contains(activeMembership.id) &&
        successCount > 0) {
      ref.invalidate(myDepartmentIntegrationsProvider);
      ref.invalidate(sessionPermissionsProvider);
    }

    state = const AsyncData(null);
    return AddDepartmentParticipantsResult(
      successCount: successCount,
      failureCount: failureCount,
    );
  }
}
