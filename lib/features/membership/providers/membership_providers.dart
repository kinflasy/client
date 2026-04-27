import 'package:client/core/network/dio_client.dart';
import 'package:client/features/membership/data/datasources/membership_api.dart';
import 'package:client/features/membership/data/repositories/membership_repository_impl.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/domain/entities/pending_membership_entity.dart';
import 'package:client/features/membership/domain/repositories/membership_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
