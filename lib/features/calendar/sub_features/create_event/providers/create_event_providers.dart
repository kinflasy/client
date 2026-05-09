import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/data/models/calendar_event_request_model.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final createCalendarEventProvider =
    NotifierProvider<
      CreateCalendarEventNotifier,
      AsyncValue<CalendarEventEntity?>
    >(CreateCalendarEventNotifier.new);

class CreateCalendarEventNotifier
    extends Notifier<AsyncValue<CalendarEventEntity?>> {
  @override
  AsyncValue<CalendarEventEntity?> build() => const AsyncData(null);

  Future<Either<Failure, CalendarEventEntity>> createUnitEvent(
    String unitId,
    CalendarEventRequestModel request, {
    String? cardImagePath,
  }) {
    return _create(
      create: () => ref
          .read(calendarEventRepositoryProvider)
          .createUnitEvent(unitId, request),
      uploadImage: (event) => _uploadImage(event, cardImagePath),
      invalidateListings: () => ref.invalidate(unitCalendarEventsProvider),
    );
  }

  Future<Either<Failure, CalendarEventEntity>> createDepartmentEvent(
    String departmentId,
    CalendarEventRequestModel request, {
    String? cardImagePath,
  }) {
    return _create(
      create: () => ref
          .read(calendarEventRepositoryProvider)
          .createDepartmentEvent(departmentId, request),
      uploadImage: (event) => _uploadImage(event, cardImagePath),
      invalidateListings: () =>
          ref.invalidate(departmentCalendarEventsProvider),
    );
  }

  Future<Either<Failure, CalendarEventEntity>> _create({
    required Future<Either<Failure, CalendarEventEntity>> Function() create,
    required Future<Either<Failure, CalendarEventEntity>> Function(
      CalendarEventEntity event,
    )
    uploadImage,
    required void Function() invalidateListings,
  }) async {
    state = const AsyncLoading();

    final createdResult = await create();
    if (createdResult.isLeft()) {
      final failure = createdResult.getLeft().toNullable()!;
      state = AsyncError(failure, StackTrace.current);
      return Left(failure);
    }

    final createdEvent = createdResult.getRight().toNullable()!;
    final uploadedResult = await uploadImage(createdEvent);

    return uploadedResult.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return Left(failure);
      },
      (event) {
        state = AsyncData(event);
        invalidateListings();
        ref.invalidate(calendarEventDetailProvider(event.id));
        return Right(event);
      },
    );
  }

  Future<Either<Failure, CalendarEventEntity>> _uploadImage(
    CalendarEventEntity event,
    String? cardImagePath,
  ) {
    final path = cardImagePath?.trim();
    if (path == null || path.isEmpty) {
      return Future.value(Right(event));
    }

    return ref
        .read(calendarEventRepositoryProvider)
        .updateCardImage(event.id, path);
  }
}
