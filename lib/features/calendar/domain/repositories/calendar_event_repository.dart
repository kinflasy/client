import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/data/models/calendar_event_request_model.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class CalendarEventRepository {
  Future<Either<Failure, List<CalendarEventEntity>>> getUnitEvents(
    String unitId,
    DateTime start,
    DateTime end,
  );

  Future<Either<Failure, List<CalendarEventEntity>>> getDepartmentEvents(
    String departmentId,
    DateTime start,
    DateTime end,
  );

  Future<Either<Failure, CalendarEventEntity>> createUnitEvent(
    String unitId,
    CalendarEventRequestModel request,
  );

  Future<Either<Failure, CalendarEventEntity>> createDepartmentEvent(
    String departmentId,
    CalendarEventRequestModel request,
  );

  Future<Either<Failure, CalendarEventEntity>> getEventById(String eventId);

  Future<Either<Failure, CalendarEventEntity>> updateEvent(
    String eventId,
    CalendarEventRequestModel request,
  );

  Future<Either<Failure, CalendarEventEntity>> updateCardImage(
    String eventId,
    String filePath,
  );

  Future<Either<Failure, void>> deleteCardImage(String eventId);

  Future<Either<Failure, void>> deleteEvent(String eventId);
}
