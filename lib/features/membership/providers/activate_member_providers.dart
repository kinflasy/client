import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/data/models/activate_member_request_model.dart';
import 'package:client/features/membership/domain/entities/activation_user_entity.dart';
import 'package:client/features/membership/providers/member_profile_providers.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:client/features/membership/providers/register_member_providers.dart';
import 'package:client/features/membership/providers/unit_member_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'activate_member_providers.g.dart';

@riverpod
class UserByUsernameLookup extends _$UserByUsernameLookup {
  @override
  AsyncValue<ActivationUserEntity?> build() => const AsyncData(null);

  Future<Either<Failure, ActivationUserEntity>> search(String username) async {
    final normalized = username.trim().replaceFirst(RegExp(r'^@+'), '');
    if (normalized.isEmpty) {
      const failure = ValidationFailure('Informe o usuario.');
      state = AsyncError(failure, StackTrace.current);
      return const Left(failure);
    }

    state = const AsyncLoading();
    final result = await ref
        .read(unitMemberRepositoryProvider)
        .identifyUserByUsername(normalized);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (user) => AsyncData(user),
    );
    return result;
  }

  void clear() {
    state = const AsyncData(null);
  }
}

@riverpod
class ActivateMember extends _$ActivateMember {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<Failure, void>> activate({
    required String inactivePersonId,
    required String username,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(unitMemberRepositoryProvider)
        .activateMember(
          ActivateMemberRequestModel(
            inactivePersonId: inactivePersonId,
            username: username.trim().replaceFirst(RegExp(r'^@+'), ''),
          ),
        );

    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );

    if (result.isRight()) {
      await _invalidateActivationDependencies(ref, inactivePersonId);
    }

    return result;
  }
}

Future<void> _invalidateActivationDependencies(Ref ref, String personId) async {
  final membership = await ref.read(activeMembershipProvider.future);
  final unitId = membership?.unitId;

  ref.invalidate(memberProfileProvider(personId));
  ref.invalidate(membershipProvider);
  ref.invalidate(activeMembershipProvider);
  ref.invalidate(currentChurchProfileProvider);
  if (unitId != null && unitId.isNotEmpty) {
    ref.invalidate(rawUnitMembersProvider(unitId));
  }
}
