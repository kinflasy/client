import 'package:client/core/errors/failure.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/features/membership/data/datasources/unit_member_api.dart';
import 'package:client/features/membership/data/models/register_member_request_model.dart';
import 'package:client/features/membership/data/repositories/unit_member_repository_impl.dart';
import 'package:client/features/membership/domain/repositories/unit_member_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'register_member_providers.g.dart';

final unitMemberApiProvider = Provider<UnitMemberApi>(
  (ref) => UnitMemberApi(ref.watch(dioClientProvider)),
);

final unitMemberRepositoryProvider = Provider<UnitMemberRepository>(
  (ref) => UnitMemberRepositoryImpl(
    ref.watch(unitMemberApiProvider),
    ref.watch(dioClientProvider),
  ),
);

@riverpod
class RegisterMemberNotifier extends _$RegisterMemberNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<Failure, void>> register(
    String unitId,
    RegisterMemberRequestModel request,
  ) async {
    state = const AsyncLoading();
    final result = await ref
        .read(unitMemberRepositoryProvider)
        .registerMember(unitId, request);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result;
  }
}
