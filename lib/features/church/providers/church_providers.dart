import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/features/church/data/datasources/church_api.dart';
import 'package:client/features/church/data/datasources/church_departments_api.dart';
import 'package:client/features/church/data/datasources/church_events_api.dart';
import 'package:client/features/church/data/datasources/church_unit_api.dart';
import 'package:client/features/church/data/models/church_read_models.dart';
import 'package:client/features/church/data/models/church_request_model.dart';
import 'package:client/features/church/data/repositories/church_repository_impl.dart';
import 'package:client/features/church/data/repositories/church_unit_repository_impl.dart';
import 'package:client/features/church/domain/entities/church_department_entity.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_event_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/current_church_profile_entity.dart';
import 'package:client/features/church/domain/entities/public_church_unit_profile_entity.dart';
import 'package:client/features/church/domain/repositories/church_repository.dart';
import 'package:client/features/church/domain/repositories/church_unit_repository.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/providers/membership_providers.dart';

part 'church_providers.g.dart';

final churchApiProvider = Provider<ChurchApi>(
  (ref) => ChurchApi(ref.watch(dioClientProvider)),
);

final churchRepositoryProvider = Provider<ChurchRepository>(
  (ref) => ChurchRepositoryImpl(ref.watch(churchApiProvider)),
);

final churchUnitApiProvider = Provider<ChurchUnitApi>(
  (ref) => ChurchUnitApi(ref.watch(dioClientProvider)),
);

final churchUnitRepositoryProvider = Provider<ChurchUnitRepository>(
  (ref) => ChurchUnitRepositoryImpl(ref.watch(churchUnitApiProvider)),
);

final churchEventsApiProvider = Provider<ChurchEventsApi>(
  (ref) => ChurchEventsApi(ref.watch(dioClientProvider)),
);

final churchDepartmentsApiProvider = Provider<ChurchDepartmentsApi>(
  (ref) => ChurchDepartmentsApi(ref.watch(dioClientProvider)),
);

final activeMembershipProvider = FutureProvider<MembershipEntity?>((ref) async {
  final memberships = await ref.watch(membershipProvider.future);
  return memberships.isEmpty ? null : memberships.first;
});

final currentChurchProfileProvider = FutureProvider<CurrentChurchProfileEntity>(
  (ref) async {
    final activeMembership = await ref.watch(activeMembershipProvider.future);
    return resolveCurrentChurchProfile(
      activeMembership: activeMembership,
      unitRepository: ref.read(churchUnitRepositoryProvider),
      churchRepository: ref.read(churchRepositoryProvider),
    );
  },
);

Future<CurrentChurchProfileEntity> resolveCurrentChurchProfile({
  required MembershipEntity? activeMembership,
  required ChurchUnitRepository unitRepository,
  required ChurchRepository churchRepository,
}) async {
  if (activeMembership == null) {
    throw const NotFoundFailure('Nenhuma igreja vinculada a este usuário.');
  }

  final unitResult = await unitRepository.getUnitById(activeMembership.unitId);
  final unit = unitResult.fold((failure) => throw failure, (value) => value);

  final churchResult = await churchRepository.getChurchById(unit.churchId);
  final church = churchResult.fold(
    (failure) => throw failure,
    (value) => value,
  );

  return CurrentChurchProfileEntity(
    membership: activeMembership,
    unit: unit,
    church: church,
  );
}

final churchEventsProvider =
    FutureProvider.family<List<ChurchEventEntity>, String>((ref, unitId) async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 2, 0, 23, 59, 59);

      try {
        final jsonList = await ref
            .read(churchEventsApiProvider)
            .getEventsByUnitId(unitId: unitId, start: start, end: end);
        return jsonList
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .map(ChurchEventReadModel.fromJson)
            .map(
              (model) => ChurchEventEntity(
                id: model.id,
                title: model.title,
                startDateTime: model.startDateTime,
                endDateTime: model.endDateTime,
                description: model.description,
              ),
            )
            .toList();
      } catch (_) {
        throw const NetworkFailure('Erro ao carregar eventos da igreja.');
      }
    });

final churchDepartmentsProvider =
    FutureProvider.family<List<ChurchDepartmentEntity>, String>((
      ref,
      unitId,
    ) async {
      try {
        final jsonList = await ref
            .read(churchDepartmentsApiProvider)
            .getDepartmentsByUnitId(unitId);
        return jsonList
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .map(ChurchDepartmentReadModel.fromJson)
            .where((model) => model.id.isNotEmpty)
            .map(
              (model) => ChurchDepartmentEntity(
                id: model.id,
                name: model.name,
                slug: model.slug,
                type: model.type,
              ),
            )
            .toList();
      } catch (_) {
        throw const NetworkFailure('Erro ao carregar ministérios da igreja.');
      }
    });

/// Provider parametrizado por churchId para o perfil público.
/// Reutiliza o repositório e endpoint já existentes.
final publicChurchProfileProvider = FutureProvider.family<ChurchEntity, String>(
  (ref, churchId) async {
    final result = await ref
        .read(churchRepositoryProvider)
        .getChurchById(churchId);
    return result.fold((failure) => throw failure, (church) => church);
  },
);

final churchSearchProvider = FutureProvider.family<List<ChurchEntity>, String>((
  ref,
  term,
) async {
  if (term.trim().length < 2) return [];
  final result = await ref
      .read(churchRepositoryProvider)
      .searchChurches(term.trim());
  return result.fold((failure) => throw failure, (churches) => churches);
});

final publicChurchUnitProfileProvider =
    FutureProvider.family<PublicChurchUnitProfileEntity, String>((
      ref,
      unitId,
    ) async {
      return resolvePublicChurchUnitProfile(
        unitId: unitId,
        unitRepository: ref.read(churchUnitRepositoryProvider),
        churchRepository: ref.read(churchRepositoryProvider),
      );
    });

final headquarterUnitByChurchProvider =
    FutureProvider.family<ChurchUnitEntity, String>((ref, churchId) async {
      return resolveHeadquarterUnitByChurch(
        churchId: churchId,
        unitRepository: ref.read(churchUnitRepositoryProvider),
      );
    });

Future<PublicChurchUnitProfileEntity> resolvePublicChurchUnitProfile({
  required String unitId,
  required ChurchUnitRepository unitRepository,
  required ChurchRepository churchRepository,
}) async {
  final unitResult = await unitRepository.getUnitById(unitId);
  final unit = unitResult.fold((failure) => throw failure, (value) => value);

  final churchResult = await churchRepository.getChurchById(unit.churchId);
  final church = churchResult.fold(
    (failure) => throw failure,
    (value) => value,
  );

  final relatedUnitsResult = await unitRepository.getUnitsByChurchId(
    unit.churchId,
  );
  final relatedUnits = relatedUnitsResult.fold(
    (failure) => throw failure,
    (value) => value,
  );

  return PublicChurchUnitProfileEntity(
    unit: unit,
    church: church,
    relatedUnits: relatedUnits,
  );
}

Future<ChurchUnitEntity> resolveHeadquarterUnitByChurch({
  required String churchId,
  required ChurchUnitRepository unitRepository,
}) async {
  final unitsResult = await unitRepository.getUnitsByChurchId(churchId);
  final units = unitsResult.fold((failure) => throw failure, (value) => value);

  for (final unit in units) {
    if (unit.type == 'MAIN') return unit;
  }

  throw const ValidationFailure(
    'NÃ£o foi possÃ­vel identificar a unidade sede desta igreja.',
  );
}

@riverpod
class CreateChurchNotifier extends _$CreateChurchNotifier {
  @override
  AsyncValue<ChurchEntity?> build() => const AsyncValue.data(null);

  Future<Either<Failure, ChurchEntity>> create(
    ChurchStarterRequestModel request,
  ) async {
    state = const AsyncLoading();
    final result = await ref
        .read(churchRepositoryProvider)
        .createChurch(request);
    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (church) => state = AsyncData(church),
    );
    return result;
  }
}
