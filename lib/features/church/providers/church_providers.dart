import 'package:client/core/errors/failure.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/utils/string_utils.dart';
import 'package:client/features/church/data/datasources/church_api.dart';
import 'package:client/features/church/data/datasources/church_events_api.dart';
import 'package:client/features/church/data/datasources/church_unit_api.dart';
import 'package:client/features/church/data/models/church_read_models.dart';
import 'package:client/features/church/data/models/church_request_model.dart';
import 'package:client/features/church/data/repositories/church_repository_impl.dart';
import 'package:client/features/church/data/repositories/church_unit_repository_impl.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_event_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/current_church_profile_entity.dart';
import 'package:client/features/church/domain/entities/public_church_unit_profile_entity.dart';
import 'package:client/features/church/domain/repositories/church_repository.dart';
import 'package:client/features/church/domain/repositories/church_unit_repository.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  final result = await ref.read(churchRepositoryProvider).getAllChurches();
  final churches = result.fold((failure) => throw failure, (value) => value);
  final normalizedTerm = normalizeSearchTerm(term);

  if (normalizedTerm.isEmpty) {
    return churches;
  }

  return churches.where((church) {
    final haystacks = [
      church.name,
      church.slug,
      church.acronym ?? '',
    ].map(normalizeSearchTerm);

    return haystacks.any((value) => value.contains(normalizedTerm));
  }).toList();
});

// ignore: unused_element
String _normalizeChurchSearchTerm(String value) {
  const accentMap = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };

  final lower = value.trim().toLowerCase();
  final buffer = StringBuffer();

  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(accentMap[char] ?? char);
  }

  return buffer.toString();
}

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
    'Não foi possível identificar a unidade sede desta igreja.',
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

@riverpod
class JoinChurchUnitNotifier extends _$JoinChurchUnitNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<Failure, void>> join(String unitId, String affiliation) async {
    state = const AsyncLoading();
    final result = await ref
        .read(churchUnitRepositoryProvider)
        .joinUnit(unitId, affiliation);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );

    if (result.isRight()) {
      ref.invalidate(myPendingMembershipsProvider);
      ref.invalidate(publicChurchUnitProfileProvider(unitId));
    }

    return result;
  }
}
