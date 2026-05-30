import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/data/models/calendar_event_scale_request_model.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
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
