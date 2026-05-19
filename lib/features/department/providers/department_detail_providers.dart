import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/department/data/models/integration_request_model.dart';
import 'package:client/features/department/domain/entities/add_department_participants_result.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/providers/member_profile_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

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

final updateDepartmentParticipantRoleProvider =
    NotifierProvider<UpdateDepartmentParticipantRoleNotifier, AsyncValue<void>>(
      UpdateDepartmentParticipantRoleNotifier.new,
    );

final removeDepartmentParticipantProvider =
    NotifierProvider<RemoveDepartmentParticipantNotifier, AsyncValue<void>>(
      RemoveDepartmentParticipantNotifier.new,
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

class UpdateDepartmentParticipantRoleNotifier
    extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<Failure, Unit>> updateRole({
    required String departmentId,
    required String membershipId,
    required IntegrationType role,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(departmentRepositoryProvider)
        .updateParticipantRole(
          departmentId,
          IntegrationRequestModel(membershipId: membershipId, type: role),
        );
    await _invalidateAfterParticipantMutation(
      ref,
      departmentId: departmentId,
      membershipId: membershipId,
      shouldInvalidate: result.isRight(),
    );
    state = const AsyncData(null);
    return result;
  }
}

class RemoveDepartmentParticipantNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<Failure, Unit>> remove({
    required String departmentId,
    required String membershipId,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(departmentRepositoryProvider)
        .removeParticipant(
          departmentId,
          IntegrationRequestModel(membershipId: membershipId),
        );
    await _invalidateAfterParticipantMutation(
      ref,
      departmentId: departmentId,
      membershipId: membershipId,
      shouldInvalidate: result.isRight(),
    );
    state = const AsyncData(null);
    return result;
  }
}

Future<void> _invalidateAfterParticipantMutation(
  Ref ref, {
  required String departmentId,
  required String membershipId,
  required bool shouldInvalidate,
}) async {
  if (!shouldInvalidate) return;

  ref.invalidate(departmentParticipantsProvider(departmentId));

  final activeMembership = await ref.read(activeMembershipProvider.future);
  if (activeMembership?.id == membershipId) {
    ref.invalidate(myDepartmentIntegrationsProvider);
    ref.invalidate(sessionPermissionsProvider);
  }
}
