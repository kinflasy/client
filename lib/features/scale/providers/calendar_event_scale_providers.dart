import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/providers/department_lineup_providers.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/data/models/person_profile_model.dart';
import 'package:client/features/membership/providers/member_profile_providers.dart';
import 'package:client/features/scale/data/models/calendar_event_scale_request_model.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/scale/domain/entities/department_scale_detail_entity.dart';
import 'package:client/features/scale/domain/entities/department_scale_with_lineup_entity.dart';
import 'package:client/features/scale/domain/entities/editable_scale_assignment_entity.dart';
import 'package:client/features/scale/domain/entities/scale_assignment_person_entity.dart';
import 'package:client/features/scale/domain/entities/scale_role_assignments_entity.dart';
import 'package:client/features/scale/domain/services/scale_assignment_diff.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

class EligibleDepartmentScaleEventsRequest extends Equatable {
  const EligibleDepartmentScaleEventsRequest({
    required this.departmentId,
    required this.start,
    required this.end,
  });

  final String departmentId;
  final DateTime start;
  final DateTime end;

  @override
  List<Object?> get props => [departmentId, start, end];
}

class DepartmentScalesRequest extends Equatable {
  const DepartmentScalesRequest({
    required this.departmentId,
    required this.start,
    required this.end,
  });

  final String departmentId;
  final DateTime start;
  final DateTime end;

  @override
  List<Object?> get props => [departmentId, start, end];
}

class DepartmentScaleDetailRequest extends Equatable {
  const DepartmentScaleDetailRequest({
    required this.departmentId,
    required this.scaleId,
    this.initialScale,
  });

  final String departmentId;
  final String scaleId;
  final DepartmentScaleWithLineupEntity? initialScale;

  @override
  List<Object?> get props => [departmentId, scaleId, initialScale];
}

EligibleDepartmentScaleEventsRequest buildEligibleDepartmentScaleEventsRequest(
  String departmentId, {
  DateTime? now,
}) {
  final start = now ?? DateTime.now();
  return EligibleDepartmentScaleEventsRequest(
    departmentId: departmentId,
    start: start,
    end: DateTime(start.year, start.month + 6, start.day, 23, 59, 59),
  );
}

DepartmentScalesRequest buildDepartmentScalesRequest(
  String departmentId, {
  DateTime? now,
}) {
  final start = now ?? DateTime.now();
  return DepartmentScalesRequest(
    departmentId: departmentId,
    start: start,
    end: DateTime(start.year, start.month + 6, start.day, 23, 59, 59),
  );
}

final eventScalesProvider =
    FutureProvider.family<List<CalendarEventScaleEntity>, String>((
      ref,
      eventId,
    ) async {
      final result = await ref
          .read(calendarEventRepositoryProvider)
          .getEventScales(eventId);

      return result.fold((failure) => throw failure, (scales) => scales);
    });

final departmentScalesProvider =
    FutureProvider.family<
      List<DepartmentCalendarEventScaleEntity>,
      DepartmentScalesRequest
    >((ref, request) async {
      final result = await ref
          .read(calendarEventRepositoryProvider)
          .getDepartmentScales(
            request.departmentId,
            request.start,
            request.end,
          );

      return result.fold((failure) => throw failure, (scales) {
        return [...scales]..sort(_compareDepartmentScales);
      });
    });

final departmentScalesWithLineupsProvider =
    FutureProvider.family<
      List<DepartmentScaleWithLineupEntity>,
      DepartmentScalesRequest
    >((ref, request) async {
      ref.watch(lineupMutationVersionProvider);
      final scalesResult = await ref
          .read(calendarEventRepositoryProvider)
          .getDepartmentScales(
            request.departmentId,
            request.start,
            request.end,
          );
      final scales = scalesResult.fold((failure) => throw failure, (scales) {
        return [...scales]..sort(_compareDepartmentScales);
      });
      if (scales.isEmpty) return const [];

      final lineupIds = scales.map((item) => item.scale.lineupId).toSet();
      final lineupsById = <String, LineupEntity>{};
      final failedLineupIds = <String>{};

      await Future.wait(
        lineupIds.map((lineupId) async {
          final result = await ref
              .read(departmentRepositoryProvider)
              .getLineupWithItems(lineupId);

          result.fold(
            (_) => failedLineupIds.add(lineupId),
            (lineup) => lineupsById[lineupId] = lineup,
          );
        }),
      );

      return scales.map((scale) {
        final lineupId = scale.scale.lineupId;
        final lineup = lineupsById[lineupId];
        final lineupState = failedLineupIds.contains(lineupId)
            ? DepartmentScaleLineupLoadState.failed
            : DepartmentScaleLineupLoadState.loaded;

        return DepartmentScaleWithLineupEntity(
          scale: scale,
          lineupState: lineupState,
          lineup: lineup,
        );
      }).toList();
    });

final departmentScaleDetailProvider =
    StreamProvider.family<
      DepartmentScaleWithLineupEntity,
      DepartmentScaleDetailRequest
    >(_loadDepartmentScaleDetail);

Stream<DepartmentScaleWithLineupEntity> _loadDepartmentScaleDetail(
  Ref ref,
  DepartmentScaleDetailRequest request,
) async* {
  ref.watch(lineupMutationVersionProvider);

  final initialScale = request.initialScale;
  if (initialScale != null && initialScale.scale.scale.id == request.scaleId) {
    yield initialScale;
  }

  final calendarRepository = ref.read(calendarEventRepositoryProvider);
  final scaleResult = await calendarRepository.getScaleById(request.scaleId);
  final scale = scaleResult.fold((failure) => throw failure, (scale) {
    return scale;
  });

  if (scale.type != CalendarEventScaleType.owner ||
      scale.calendarEventId == null ||
      scale.calendarEventId!.trim().isEmpty) {
    throw const ValidationFailure(
      'Não foi possível resolver o evento desta escala.',
    );
  }

  final eventResult = await calendarRepository.getEventById(
    scale.calendarEventId!,
  );
  final event = eventResult.fold((failure) => throw failure, (event) {
    return event;
  });

  final lineupDetail = await _loadLineupDetail(ref, scale.lineupId);

  yield DepartmentScaleWithLineupEntity(
    scale: DepartmentCalendarEventScaleEntity(
      scale: scale,
      calendarEvent: event,
    ),
    lineupState: lineupDetail.state,
    lineup: lineupDetail.lineup,
  );
}

final departmentScaleAssignmentDetailProvider =
    StreamProvider.family<
      DepartmentScaleDetailEntity,
      DepartmentScaleDetailRequest
    >((ref, request) async* {
      await for (final detail in _loadDepartmentScaleDetail(ref, request)) {
        yield await _composeAssignmentDetail(ref, request, detail);
      }
    });

final eligibleDepartmentScaleEventsProvider =
    FutureProvider.family<
      List<CalendarEventEntity>,
      EligibleDepartmentScaleEventsRequest
    >((ref, request) async {
      final result = await ref
          .read(calendarEventRepositoryProvider)
          .getDepartmentEventsWithCollabs(
            request.departmentId,
            request.start,
            request.end,
          );

      final events = result.fold(
        (failure) => throw failure,
        (events) => events,
      );

      return events
          .where((event) => !event.startDateTime.isBefore(request.start))
          .toList()
        ..sort(_compareEventsForScaleCreation);
    });

final createEventScaleProvider =
    NotifierProvider<CreateEventScaleNotifier, AsyncValue<void>>(
      CreateEventScaleNotifier.new,
    );

final saveScaleAssignmentsProvider =
    NotifierProvider<SaveScaleAssignmentsNotifier, AsyncValue<void>>(
      SaveScaleAssignmentsNotifier.new,
    );

class CreateEventScaleNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<Failure, CalendarEventScaleEntity>> create({
    required String departmentId,
    required CalendarEventEntity event,
    required CalendarEventScaleRequestModel request,
  }) async {
    state = const AsyncLoading();

    final repository = ref.read(calendarEventRepositoryProvider);
    final isOwnerEvent =
        event.type == CalendarEventType.department &&
        event.departmentId == departmentId;

    final result = isOwnerEvent
        ? await repository.createEventScale(event.id, request)
        : await repository.createCollaboratorEventScale(
            event.id,
            departmentId,
            request,
          );

    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return Left(failure);
      },
      (scale) {
        state = const AsyncData(null);
        ref.invalidate(eventScalesProvider(event.id));
        ref.invalidate(eligibleDepartmentScaleEventsProvider);
        ref.invalidate(departmentScalesProvider);
        ref.invalidate(departmentScalesWithLineupsProvider);
        ref.invalidate(departmentScaleDetailProvider);
        ref.invalidate(departmentScaleAssignmentDetailProvider);
        return Right(scale);
      },
    );
  }
}

class SaveScaleAssignmentsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<Failure, void>> save({
    required String departmentId,
    required String scaleId,
    required List<EditableScaleAssignmentEntity> originalAssignments,
    required List<EditableScaleAssignmentEntity> currentAssignments,
  }) async {
    final diff = calculateScaleAssignmentDiff(
      original: originalAssignments,
      current: currentAssignments,
    );

    if (diff.isEmpty) {
      state = const AsyncData(null);
      return const Right(null);
    }

    state = const AsyncLoading();
    final repository = ref.read(calendarEventRepositoryProvider);

    for (final request in diff.toDelete) {
      final result = await repository.removeScaleItem(
        scaleId: scaleId,
        request: request,
      );
      final failure = result.getLeft().toNullable();
      if (failure != null) {
        state = AsyncError(failure, StackTrace.current);
        return Left(failure);
      }
    }

    for (final request in diff.toCreate) {
      final result = await repository.addScaleItem(
        scaleId: scaleId,
        request: request,
      );
      final failure = result.getLeft().toNullable();
      if (failure != null) {
        state = AsyncError(failure, StackTrace.current);
        return Left(failure);
      }
    }

    state = const AsyncData(null);
    ref.invalidate(departmentScaleDetailProvider);
    ref.invalidate(departmentScaleAssignmentDetailProvider);
    ref.invalidate(departmentScalesWithLineupsProvider);
    ref.invalidate(departmentScalesProvider);
    return const Right(null);
  }
}

int _compareEventsForScaleCreation(
  CalendarEventEntity a,
  CalendarEventEntity b,
) {
  final startComparison = a.startDateTime.compareTo(b.startDateTime);
  if (startComparison != 0) return startComparison;
  return a.title.toLowerCase().compareTo(b.title.toLowerCase());
}

int _compareDepartmentScales(
  DepartmentCalendarEventScaleEntity a,
  DepartmentCalendarEventScaleEntity b,
) {
  final startComparison = a.calendarEvent.startDateTime.compareTo(
    b.calendarEvent.startDateTime,
  );
  if (startComparison != 0) return startComparison;

  final titleComparison = a.calendarEvent.title.toLowerCase().compareTo(
    b.calendarEvent.title.toLowerCase(),
  );
  if (titleComparison != 0) return titleComparison;

  return a.scale.id.compareTo(b.scale.id);
}

Future<({DepartmentScaleLineupLoadState state, LineupEntity? lineup})>
_loadLineupDetail(Ref ref, String lineupId) async {
  final result = await ref
      .read(departmentRepositoryProvider)
      .getLineupWithItems(lineupId);

  return result.fold(
    (_) => (state: DepartmentScaleLineupLoadState.failed, lineup: null),
    (lineup) => (state: DepartmentScaleLineupLoadState.loaded, lineup: lineup),
  );
}

Future<DepartmentScaleDetailEntity> _composeAssignmentDetail(
  Ref ref,
  DepartmentScaleDetailRequest request,
  DepartmentScaleWithLineupEntity detail,
) async {
  final calendarRepository = ref.read(calendarEventRepositoryProvider);
  final memberProfileRepository = ref.read(memberProfileRepositoryProvider);
  final itemsResult = await calendarRepository.getScaleItems(
    detail.scale.scale.id,
  );
  final scaleItems = itemsResult.fold((failure) => throw failure, (items) {
    return items;
  });

  final participantsDetail = await _loadParticipants(ref, request.departmentId);
  final participantsByPersonId = {
    for (final participant in participantsDetail.participants)
      participant.personId: participant,
  };

  final fallbackPeople = <String, ScaleAssignmentPersonEntity>{};
  final profileFailurePersonIds = <String>[];

  Future<ScaleAssignmentPersonEntity> resolvePerson(String personId) async {
    final participant = participantsByPersonId[personId];
    if (participant != null) {
      return _assignmentPersonFromParticipant(participant);
    }

    final cached = fallbackPeople[personId];
    if (cached != null) return cached;

    final result = await memberProfileRepository.getPersonProfile(personId);

    return result.fold(
      (_) {
        if (!profileFailurePersonIds.contains(personId)) {
          profileFailurePersonIds.add(personId);
        }
        final person = ScaleAssignmentPersonEntity(
          personId: personId,
          displayName: 'Pessoa não encontrada',
          source: ScaleAssignmentPersonSource.notFound,
        );
        fallbackPeople[personId] = person;
        return person;
      },
      (profile) {
        final person = _assignmentPersonFromProfile(profile);
        fallbackPeople[personId] = person;
        return person;
      },
    );
  }

  final peopleByRoleId = <String, List<ScaleAssignmentPersonEntity>>{};
  final seenPeopleByRoleId = <String, Set<String>>{};
  for (final item in scaleItems) {
    final seenPeople = seenPeopleByRoleId.putIfAbsent(item.roleId, () => {});
    if (!seenPeople.add(item.personId)) continue;

    final people = peopleByRoleId.putIfAbsent(item.roleId, () => []);
    final person = await resolvePerson(item.personId);
    people.add(person.copyWith(scaleItemId: item.id));
  }

  final roleAssignments = _groupRoleAssignments(
    detail.lineup?.items ?? const [],
    peopleByRoleId,
  );

  return DepartmentScaleDetailEntity(
    base: detail,
    roleAssignments: roleAssignments,
    peopleLoadFailureMessage: participantsDetail.failureMessage,
    profileFailurePersonIds: profileFailurePersonIds,
  );
}

List<ScaleRoleAssignmentsEntity> _groupRoleAssignments(
  List<LineupItemEntity> lineupItems,
  Map<String, List<ScaleAssignmentPersonEntity>> peopleByRoleId,
) {
  final itemsByRoleId = <String, LineupItemEntity>{};
  final capacityByRoleId = <String, int>{};

  for (final item in lineupItems) {
    itemsByRoleId.putIfAbsent(item.roleId, () => item);
    capacityByRoleId[item.roleId] = (capacityByRoleId[item.roleId] ?? 0) + 1;
  }

  return itemsByRoleId.entries
      .map(
        (entry) => ScaleRoleAssignmentsEntity(
          item: entry.value,
          people: peopleByRoleId[entry.key] ?? const [],
          capacity: capacityByRoleId[entry.key] ?? 1,
        ),
      )
      .toList();
}

Future<
  ({List<DepartmentParticipantEntity> participants, String? failureMessage})
>
_loadParticipants(Ref ref, String departmentId) async {
  final result = await ref
      .read(departmentRepositoryProvider)
      .getParticipants(departmentId);
  return result.fold(
    (_) => (
      participants: const <DepartmentParticipantEntity>[],
      failureMessage: 'Não foi possível carregar todos os dados das pessoas.',
    ),
    (participants) => (participants: participants, failureMessage: null),
  );
}

ScaleAssignmentPersonEntity _assignmentPersonFromParticipant(
  DepartmentParticipantEntity participant,
) {
  return ScaleAssignmentPersonEntity(
    personId: participant.personId,
    displayName: participant.displayName,
    profileImageId: participant.profileImageId,
    source: ScaleAssignmentPersonSource.participant,
  );
}

ScaleAssignmentPersonEntity _assignmentPersonFromProfile(
  PersonProfileModel profile,
) {
  final nickname = profile.nickname?.trim();
  final fullName = profile.fullName.trim();
  return ScaleAssignmentPersonEntity(
    personId: profile.id,
    displayName: nickname != null && nickname.isNotEmpty ? nickname : fullName,
    profileImageId: profile.profileImageId,
    source: ScaleAssignmentPersonSource.profileFallback,
  );
}
