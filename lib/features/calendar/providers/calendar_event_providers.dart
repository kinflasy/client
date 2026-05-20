import 'package:client/core/domain/enums/affiliation.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/features/calendar/data/datasources/calendar_events_api.dart';
import 'package:client/features/calendar/data/repositories/calendar_event_repository_impl.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/entities/visibility_rule_entity.dart';
import 'package:client/features/calendar/domain/repositories/calendar_event_repository.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
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

final visibleUnitCalendarEventsProvider =
    FutureProvider.family<List<CalendarEventEntity>, UnitCalendarEventsRequest>(
      (ref, request) async {
        final permissions = await ref.watch(sessionPermissionsProvider.future);
        final unitEvents = await ref.watch(
          unitCalendarEventsProvider(request).future,
        );
        final departments = await ref.watch(
          departmentsProvider(request.unitId).future,
        );

        final departmentEvents = await Future.wait(
          departments.map(
            (department) => _loadVisibleDepartmentEvents(
              ref,
              department,
              request,
              permissions,
            ),
          ),
        );

        return _mergeAndSortEvents([
          ...unitEvents.where(
            (event) => _isEventVisibleToSession(
              event,
              permissions,
              fallbackUnitId: request.unitId,
            ),
          ),
          for (final events in departmentEvents) ...events,
        ]);
      },
    );

final calendarEventDetailProvider =
    FutureProvider.family<CalendarEventEntity, String>((ref, eventId) async {
      final result = await ref
          .read(calendarEventRepositoryProvider)
          .getEventById(eventId);

      return result.fold((failure) => throw failure, (event) => event);
    });

Future<List<CalendarEventEntity>> _loadVisibleDepartmentEvents(
  Ref ref,
  DepartmentEntity department,
  UnitCalendarEventsRequest request,
  SessionPermissions permissions,
) async {
  try {
    final events = await ref.watch(
      departmentCalendarEventsProvider(
        DepartmentCalendarEventsRequest(
          departmentId: department.id,
          start: request.start,
          end: request.end,
        ),
      ).future,
    );

    return events
        .where(
          (event) => _isEventVisibleToSession(
            event,
            permissions,
            fallbackUnitId: request.unitId,
          ),
        )
        .toList();
  } catch (_) {
    return const [];
  }
}

List<CalendarEventEntity> _mergeAndSortEvents(
  Iterable<CalendarEventEntity> events,
) {
  final byId = <String, CalendarEventEntity>{};
  for (final event in events) {
    byId[event.id] = event;
  }

  return byId.values.toList()..sort((a, b) {
    final startComparison = a.startDateTime.compareTo(b.startDateTime);
    if (startComparison != 0) return startComparison;
    return a.title.compareTo(b.title);
  });
}

bool _isEventVisibleToSession(
  CalendarEventEntity event,
  SessionPermissions permissions, {
  required String fallbackUnitId,
}) {
  if (event.visibilityRules.isEmpty) return true;

  return event.visibilityRules.any(
    (rule) => _isRuleVisibleToSession(
      rule,
      permissions,
      eventUnitId: event.unitId ?? fallbackUnitId,
    ),
  );
}

bool _isRuleVisibleToSession(
  VisibilityRuleEntity rule,
  SessionPermissions permissions, {
  required String eventUnitId,
}) {
  return switch (rule.type) {
    VisibilityRuleType.user => rule.userId == '*',
    VisibilityRuleType.unit =>
      (rule.unitId == null || rule.unitId == eventUnitId) &&
          _meetsAffiliation(permissions.affiliation, rule.affiliation),
    VisibilityRuleType.church => _meetsAffiliation(
      permissions.affiliation,
      rule.affiliation,
    ),
    VisibilityRuleType.department => _meetsIntegration(
      permissions.roleInDept(rule.departmentId ?? ''),
      rule.integrationType,
    ),
  };
}

bool _meetsAffiliation(Affiliation? actual, Affiliation? required) {
  if (required == null) return true;
  return _affiliationRank(actual) >= _affiliationRank(required);
}

int _affiliationRank(Affiliation? affiliation) {
  return switch (affiliation) {
    null => 0,
    Affiliation.visitor => 1,
    Affiliation.congregated => 2,
    Affiliation.member => 3,
    Affiliation.leader => 4,
    Affiliation.somaLeader => 5,
    Affiliation.unitAdmin => 6,
  };
}

bool _meetsIntegration(IntegrationType? actual, IntegrationType? required) {
  if (required == null) return true;
  if (actual == null) return false;
  return actual.index >= required.index;
}
