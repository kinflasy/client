import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/data/models/calendar_event_request_model.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final calendarEventActionsProvider =
    NotifierProvider<CalendarEventActionsNotifier, AsyncValue<void>>(
      CalendarEventActionsNotifier.new,
    );

class CalendarEventActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<Failure, CalendarEventEntity>> updateEvent(
    String eventId,
    CalendarEventRequestModel request,
  ) async {
    state = const AsyncLoading();

    final result = await ref
        .read(calendarEventRepositoryProvider)
        .updateEvent(eventId, request);

    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return Left(failure);
      },
      (event) {
        state = const AsyncData(null);
        _invalidateEventViews(eventId);
        return Right(event);
      },
    );
  }

  Future<Either<Failure, CalendarEventEntity>> updateCardImage(
    String eventId,
    String filePath,
  ) async {
    state = const AsyncLoading();

    final result = await ref
        .read(calendarEventRepositoryProvider)
        .updateCardImage(eventId, filePath);

    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return Left(failure);
      },
      (event) {
        state = const AsyncData(null);
        _invalidateEventViews(eventId);
        return Right(event);
      },
    );
  }

  Future<Either<Failure, void>> deleteCardImage(String eventId) async {
    state = const AsyncLoading();

    final result = await ref
        .read(calendarEventRepositoryProvider)
        .deleteCardImage(eventId);

    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return Left(failure);
      },
      (_) {
        state = const AsyncData(null);
        _invalidateEventViews(eventId);
        return const Right(null);
      },
    );
  }

  Future<Either<Failure, void>> deleteEvent(String eventId) async {
    state = const AsyncLoading();

    final result = await ref
        .read(calendarEventRepositoryProvider)
        .deleteEvent(eventId);

    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return Left(failure);
      },
      (_) {
        state = const AsyncData(null);
        _invalidateEventViews(eventId);
        return const Right(null);
      },
    );
  }

  void _invalidateEventViews(String eventId) {
    ref.invalidate(calendarEventDetailProvider(eventId));
    ref.invalidate(unitCalendarEventsProvider);
    ref.invalidate(departmentCalendarEventsProvider);
    ref.invalidate(visibleUnitCalendarEventsProvider);
  }
}
