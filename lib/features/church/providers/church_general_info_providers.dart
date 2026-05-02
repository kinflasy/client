import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncValue, FutureProvider, Provider, Ref;
import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/address/address_request_model.dart';
import '../../../core/errors/failure.dart';
import '../data/models/church_request_model.dart';
import '../domain/entities/church_link_entity.dart';
import '../domain/entities/church_unit_entity.dart';
import 'church_providers.dart';

final editChurchUnitGeneralInfoSubmitProvider =
    StateProvider.autoDispose<AsyncValue<void>>(
      (ref) => const AsyncValue.data(null),
    );

final unitLinksProvider = FutureProvider.family<List<ChurchLinkEntity>, String>(
  (ref, unitId) async {
    final result = await ref
        .read(churchUnitRepositoryProvider)
        .getUnitLinks(unitId);
    return result.fold((failure) => throw failure, (links) => links);
  },
);

final churchGeneralInfoActionsProvider = Provider<ChurchGeneralInfoActions>(
  ChurchGeneralInfoActions.new,
);

class ChurchGeneralInfoActions {
  const ChurchGeneralInfoActions(this._ref);

  final Ref _ref;

  Future<Either<Failure, ChurchUnitEntity>> updateUnitGeneralInfo({
    required ChurchUnitEntity currentUnit,
    required String name,
    required String slug,
    required String phone,
    required String email,
    required AddressRequestModel address,
  }) async {
    _ref.read(editChurchUnitGeneralInfoSubmitProvider.notifier).state =
        const AsyncValue.loading();

    final request = buildUpdateUnitRequest(
      currentUnit: currentUnit,
      name: name,
      slug: slug,
      phone: phone,
      email: email,
      address: address,
    );
    final result = await _ref
        .read(churchUnitRepositoryProvider)
        .updateUnit(currentUnit.id, request);

    result.fold(
      (failure) {
        _ref.read(editChurchUnitGeneralInfoSubmitProvider.notifier).state =
            AsyncValue.error(failure, StackTrace.current);
      },
      (_) {
        _ref.read(editChurchUnitGeneralInfoSubmitProvider.notifier).state =
            const AsyncValue.data(null);
        _ref.invalidate(currentChurchProfileProvider);
        _ref.invalidate(publicChurchUnitProfileProvider(currentUnit.id));
        _ref.invalidate(headquarterUnitByChurchProvider(currentUnit.churchId));
      },
    );

    return result;
  }
}

UnitRequestModel buildUpdateUnitRequest({
  required ChurchUnitEntity currentUnit,
  required String name,
  required String slug,
  required String phone,
  required String email,
  required AddressRequestModel address,
}) {
  return UnitRequestModel(
    name: name,
    slug: slug,
    phone: phone,
    email: email,
    type: currentUnit.type ?? 'MAIN',
    address: address,
  );
}
