import 'package:client/core/network/dio_client.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/church/domain/repositories/church_unit_repository.dart';
import 'package:client/features/membership/data/datasources/membership_api.dart';
import 'package:client/features/membership/data/repositories/membership_repository_impl.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/domain/entities/pending_membership_entity.dart';
import 'package:client/features/membership/domain/entities/pending_unit_membership_entity.dart';
import 'package:client/features/membership/domain/repositories/membership_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'membership_providers.g.dart';

final membershipApiProvider = Provider<MembershipApi>(
  (ref) => MembershipApi(ref.watch(dioClientProvider)),
);

final membershipRepositoryProvider = Provider<MembershipRepository>(
  (ref) => MembershipRepositoryImpl(ref.watch(membershipApiProvider)),
);

@riverpod
class MembershipNotifier extends _$MembershipNotifier {
  @override
  Future<List<MembershipEntity>> build() async {
    final repo = ref.watch(membershipRepositoryProvider);
    final result = await repo.getMyMemberships();
    return result.fold(
      (failure) => throw failure,
      (memberships) => memberships,
    );
  }
}

@riverpod
class MyPendingMembershipsNotifier extends _$MyPendingMembershipsNotifier {
  @override
  Future<List<PendingMembershipEntity>> build() async {
    final repo = ref.watch(membershipRepositoryProvider);
    final result = await repo.getMyPendingMemberships();
    return result.fold(
      (failure) => throw failure,
      (memberships) => memberships,
    );
  }
}

@riverpod
PendingMembershipEntity? pendingMembershipForUnit(Ref ref, String unitId) {
  final state = ref.watch(myPendingMembershipsProvider);
  return state.whenOrNull(
    data: (items) {
      for (final item in items) {
        if (item.matchesUnit(unitId)) {
          return item;
        }
      }
      return null;
    },
  );
}

@riverpod
bool hasMembership(Ref ref) {
  final state = ref.watch(membershipProvider);
  return state.whenOrNull(data: (list) => list.isNotEmpty) ?? false;
}

final pendingUnitMembershipsProvider =
    FutureProvider.family<List<PendingUnitMembershipEntity>, String>((
      ref,
      unitId,
    ) async {
      final repository = ref.watch(churchUnitRepositoryProvider);
      final result = await repository.getPendingMembers(unitId);
      return result.fold(
        (failure) => throw failure,
        (memberships) => memberships,
      );
    });

final pendingUnitMembershipActionProvider =
    AsyncNotifierProvider<PendingUnitMembershipActionNotifier, void>(
      PendingUnitMembershipActionNotifier.new,
    );

class PendingUnitMembershipActionNotifier extends AsyncNotifier<void> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<Failure, void>> confirm(String unitId, String personId) {
    return _runAction(
      unitId: unitId,
      action: (repository) => repository.confirmPendingMember(unitId, personId),
    );
  }

  Future<Either<Failure, void>> reject(String unitId, String personId) {
    return _runAction(
      unitId: unitId,
      action: (repository) => repository.rejectPendingMember(unitId, personId),
    );
  }

  Future<Either<Failure, void>> _runAction({
    required String unitId,
    required Future<Either<Failure, void>> Function(
      ChurchUnitRepository repository,
    )
    action,
  }) async {
    state = const AsyncLoading();
    final repository = ref.read(churchUnitRepositoryProvider);
    final result = await action(repository);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );

    if (result.isRight()) {
      ref.invalidate(pendingUnitMembershipsProvider(unitId));
    }

    return result;
  }
}
