import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/features/church/data/datasources/church_api.dart';
import 'package:client/features/church/data/models/church_request_model.dart';
import 'package:client/features/church/data/repositories/church_repository_impl.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/repositories/church_repository.dart';

part 'church_providers.g.dart';

final churchApiProvider = Provider<ChurchApi>(
  (ref) => ChurchApi(ref.watch(dioClientProvider)),
);

final churchRepositoryProvider = Provider<ChurchRepository>(
  (ref) => ChurchRepositoryImpl(ref.watch(churchApiProvider)),
);

@riverpod
class CreateChurchNotifier extends _$CreateChurchNotifier {
  @override
  AsyncValue<ChurchEntity?> build() => const AsyncValue.data(null);

  Future<Either<Failure, ChurchEntity>> create(
    ChurchStarterRequestModel request,
  ) async {
    state = const AsyncLoading();
    final result = await ref.read(churchRepositoryProvider).createChurch(request);
    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (church) => state = AsyncData(church),
    );
    return result;
  }
}