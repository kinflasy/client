import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/providers/department_lineup_providers.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/scale/data/models/calendar_event_scale_request_model.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/scale/domain/entities/department_scale_with_lineup_entity.dart';
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

final eligibleDepartmentScaleEventsProvider =
    FutureProvider.family<
      List<CalendarEventEntity>,
      EligibleDepartmentScaleEventsRequest
    >((ref, request) async {
      final events = await ref.watch(
        departmentCalendarEventsProvider(
          DepartmentCalendarEventsRequest(
            departmentId: request.departmentId,
            start: request.start,
            end: request.end,
          ),
        ).future,
      );

      final futureEvents = events
          .where((event) => !event.startDateTime.isBefore(request.start))
          .toList();

      final checks = await Future.wait(
        futureEvents.map((event) async {
          final result = await ref
              .read(calendarEventRepositoryProvider)
              .getEventScales(event.id);
          final scales = result.fold(
            (failure) => throw failure,
            (value) => value,
          );
          return (event: event, hasScale: scales.isNotEmpty);
        }),
      );

      final eligibleEvents =
          checks
              .where((check) => !check.hasScale)
              .map((check) => check.event)
              .toList()
            ..sort(_compareEventsForScaleCreation);

      return eligibleEvents;
    });

final createEventScaleProvider =
    NotifierProvider<CreateEventScaleNotifier, AsyncValue<void>>(
      CreateEventScaleNotifier.new,
    );

class CreateEventScaleNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<Failure, CalendarEventScaleEntity>> create({
    required String eventId,
    required CalendarEventScaleRequestModel request,
  }) async {
    state = const AsyncLoading();

    final result = await ref
        .read(calendarEventRepositoryProvider)
        .createEventScale(eventId, request);

    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return Left(failure);
      },
      (scale) {
        state = const AsyncData(null);
        ref.invalidate(eventScalesProvider(eventId));
        ref.invalidate(eligibleDepartmentScaleEventsProvider);
        ref.invalidate(departmentScalesProvider);
        ref.invalidate(departmentScalesWithLineupsProvider);
        return Right(scale);
      },
    );
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
