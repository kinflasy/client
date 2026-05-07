import 'package:client/core/network/dio_client.dart';
import 'package:client/features/calendar/data/datasources/calendar_events_api.dart';
import 'package:client/features/calendar/data/repositories/calendar_event_repository_impl.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/repositories/calendar_event_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnitCalendarEventsRequest extends Equatable {
  const UnitCalendarEventsRequest({
    required this.unitId,
    required this.start,
    required this.end,
  });

  final String unitId;
  final DateTime start;
  final DateTime end;

  @override
  List<Object?> get props => [unitId, start, end];
}

class DepartmentCalendarEventsRequest extends Equatable {
  const DepartmentCalendarEventsRequest({
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

final calendarEventsApiProvider = Provider<CalendarEventsApi>(
  (ref) => CalendarEventsApi(ref.watch(dioClientProvider)),
);

final calendarEventRepositoryProvider = Provider<CalendarEventRepository>(
  (ref) => CalendarEventRepositoryImpl(ref.watch(calendarEventsApiProvider)),
);

final unitCalendarEventsProvider =
    FutureProvider.family<List<CalendarEventEntity>, UnitCalendarEventsRequest>(
      (ref, request) async {
        final result = await ref
            .read(calendarEventRepositoryProvider)
            .getUnitEvents(request.unitId, request.start, request.end);

        return result.fold((failure) => throw failure, (events) => events);
      },
    );

final departmentCalendarEventsProvider =
    FutureProvider.family<
      List<CalendarEventEntity>,
      DepartmentCalendarEventsRequest
    >((ref, request) async {
      final result = await ref
          .read(calendarEventRepositoryProvider)
          .getDepartmentEvents(
            request.departmentId,
            request.start,
            request.end,
          );

      return result.fold((failure) => throw failure, (events) => events);
    });

final calendarEventDetailProvider =
    FutureProvider.family<CalendarEventEntity, String>((ref, eventId) async {
      final result = await ref
          .read(calendarEventRepositoryProvider)
          .getEventById(eventId);

      return result.fold((failure) => throw failure, (event) => event);
    });
