import 'dart:async';

import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/entities/person_birthday_entity.dart';
import 'package:client/features/calendar/domain/entities/user_agenda_item_entity.dart';
import 'package:client/features/calendar/domain/utils/month_day_utils.dart';
import 'package:client/features/calendar/domain/utils/user_agenda_date_utils.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/auth/providers/edit_logged_user_providers.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/scale/domain/entities/scale_item_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserAgendaItemsRequest extends Equatable {
  factory UserAgendaItemsRequest({
    required DateTime start,
    required DateTime end,
  }) {
    return UserAgendaItemsRequest._(
      start: normalizeDate(start),
      end: normalizeDate(end),
    );
  }

  factory UserAgendaItemsRequest.forFocusedMonth(DateTime focusedMonth) {
    return UserAgendaItemsRequest(
      start: firstVisibleDayOfMonth(focusedMonth),
      end: lastVisibleDayOfMonth(focusedMonth),
    );
  }

  const UserAgendaItemsRequest._({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  List<Object?> get props => [start, end];
}

final userAgendaTodayProvider = Provider<DateTime>((ref) {
  return normalizeDate(DateTime.now());
});

final userAgendaItemsProvider =
    FutureProvider.family<List<UserAgendaItemEntity>, UserAgendaItemsRequest>((
      ref,
      request,
    ) async {
      final events = await _loadVisibleEvents(ref, request);
      final today = ref.watch(userAgendaTodayProvider);
      final birthdays = await _loadBirthdaysOrEmpty(ref, request);
      final personalScales = await _loadPersonalScalesOrEmpty(
        ref,
        request,
        visibleEventIds: events.map((event) => event.id).toSet(),
      );

      final attachedScalesByEventId =
          <String, List<UserAgendaPersonalScaleSummaryEntity>>{};
      for (final scale in personalScales.attachedScales) {
        final summaries = attachedScalesByEventId.putIfAbsent(
          scale.eventId,
          () => [],
        );
        summaries.add(
          UserAgendaPersonalScaleSummaryEntity(
            scaleId: scale.scaleId,
            departmentId: scale.departmentId,
            department: scale.department,
            roles: scale.roles,
          ),
        );
      }

      final mergedEvents = events.map((event) {
        return UserAgendaEventItemEntity(
          id: event.id,
          title: event.title,
          startDateTime: event.startDateTime,
          endDateTime: event.endDateTime,
          origin: switch (event.type) {
            CalendarEventType.unit => 'Igreja',
            CalendarEventType.department => 'Departamento',
          },
          personalScales: attachedScalesByEventId[event.id] ?? const [],
        );
      }).toList();

      return [
            ...mergedEvents,
            ...birthdays.map(
              (birthday) =>
                  mapPersonBirthdayToUserAgendaItem(birthday, request: request),
            ),
            ...personalScales.standaloneItems,
            ...buildLocalUserAgendaSupplementalItems(today),
          ]
          .whereType<UserAgendaItemEntity>()
          .where((item) => _isItemInRange(item, request.start, request.end))
          .toList();
    });

final userAgendaLocalItemsProvider = Provider<List<UserAgendaItemEntity>>((
  ref,
) {
  final today = ref.watch(userAgendaTodayProvider);
  return buildLocalUserAgendaItems(today);
});

final userAgendaPersonalScalesProvider =
    FutureProvider.family<
      UserAgendaPersonalScalesEntity,
      UserAgendaItemsRequest
    >((ref, request) async {
      final visibleEvents = await _loadVisibleEvents(ref, request);
      return _loadPersonalScalesOrEmpty(
        ref,
        request,
        visibleEventIds: visibleEvents.map((event) => event.id).toSet(),
      );
    });

UserAgendaEventItemEntity mapCalendarEventToUserAgendaItem(
  CalendarEventEntity event,
) {
  return UserAgendaEventItemEntity(
    id: event.id,
    title: event.title,
    startDateTime: event.startDateTime,
    endDateTime: event.endDateTime,
    origin: switch (event.type) {
      CalendarEventType.unit => 'Igreja',
      CalendarEventType.department => 'Departamento',
    },
  );
}

UserAgendaBirthdayItemEntity? mapPersonBirthdayToUserAgendaItem(
  PersonBirthdayEntity birthday, {
  required UserAgendaItemsRequest request,
}) {
  final date = materializeMonthDayInRange(
    month: birthday.birthdayMonth,
    day: birthday.birthdayDay,
    start: request.start,
    end: request.end,
  );
  if (date == null) return null;

  final dateKey =
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  return UserAgendaBirthdayItemEntity(
    id: 'birthday-${birthday.id}-$dateKey',
    date: date,
    name: birthday.name,
    personId: birthday.id,
  );
}

List<UserAgendaItemEntity> buildLocalUserAgendaSupplementalItems(
  DateTime today,
) {
  return const [];
}

List<UserAgendaItemEntity> buildLocalUserAgendaItems(DateTime today) {
  final normalizedToday = normalizeDate(today);
  final pastEventDate = normalizedToday.subtract(const Duration(days: 3));
  final scaleDate = normalizedToday.add(const Duration(days: 2));
  final birthdayDate = normalizedToday.add(const Duration(days: 4));
  final mixedDate = normalizedToday.add(const Duration(days: 6));
  final multiDayStart = normalizedToday.add(const Duration(days: 1, hours: 19));

  return [
    UserAgendaEventItemEntity(
      id: 'demo-event-today',
      title: 'Culto de celebração',
      startDateTime: normalizedToday.add(const Duration(hours: 19)),
      endDateTime: normalizedToday.add(const Duration(hours: 21)),
      origin: 'Igreja Central',
    ),
    UserAgendaEventItemEntity(
      id: 'demo-event-past',
      title: 'Reunião de liderança',
      startDateTime: pastEventDate.add(const Duration(hours: 20)),
      endDateTime: pastEventDate.add(const Duration(hours: 21, minutes: 30)),
      origin: 'Ministério de Ensino',
    ),
    UserAgendaEventItemEntity(
      id: 'demo-event-multi-day',
      title: 'Conferência de verão',
      startDateTime: multiDayStart,
      endDateTime: multiDayStart.add(const Duration(days: 2, hours: 3)),
      origin: 'Igreja Central',
    ),
    UserAgendaEventItemEntity(
      id: 'demo-event-scale',
      title: 'Ensaio geral',
      startDateTime: scaleDate.add(const Duration(hours: 18, minutes: 30)),
      endDateTime: scaleDate.add(const Duration(hours: 20)),
      origin: 'Louvor',
      personalScales: const [
        UserAgendaPersonalScaleSummaryEntity(
          scaleId: 'demo-scale-louvor',
          departmentId: 'demo-department-louvor',
          department: 'Louvor',
          roles: ['Vocal', 'Violão'],
        ),
      ],
    ),
    UserAgendaBirthdayItemEntity(
      id: 'demo-birthday-cecilia',
      date: birthdayDate,
      name: 'Cecília',
      personId: 'demo-person-cecilia',
    ),
    UserAgendaBirthdayItemEntity(
      id: 'demo-birthday-marcos',
      date: birthdayDate,
      name: 'Marcos',
      personId: 'demo-person-marcos',
    ),
    UserAgendaBirthdayItemEntity(
      id: 'demo-birthday-ana',
      date: mixedDate,
      name: 'Ana',
      personId: 'demo-person-ana',
    ),
    UserAgendaEventItemEntity(
      id: 'demo-event-mixed',
      title: 'Ação social',
      startDateTime: mixedDate.add(const Duration(hours: 16)),
      endDateTime: mixedDate.add(const Duration(hours: 18)),
      origin: 'Diaconia',
    ),
  ];
}

bool _isItemInRange(UserAgendaItemEntity item, DateTime start, DateTime end) {
  return expandItemOccurrences(item).any((occurrence) {
    return !occurrence.date.isBefore(start) && !occurrence.date.isAfter(end);
  });
}

Future<List<PersonBirthdayEntity>> _loadBirthdaysOrEmpty(
  Ref ref,
  UserAgendaItemsRequest request,
) async {
  final completer = Completer<List<PersonBirthdayEntity>>();
  final subscription = ref.listen<AsyncValue<List<PersonBirthdayEntity>>>(
    unitBirthdaysProvider(
      UnitBirthdaysRequest(start: request.start, end: request.end),
    ),
    (_, next) {
      if (completer.isCompleted) return;
      if (next.hasValue) {
        completer.complete(next.requireValue);
      } else if (next.hasError) {
        completer.complete(const []);
      }
    },
    fireImmediately: true,
  );
  ref.onDispose(subscription.close);
  return completer.future;
}

Future<List<CalendarEventEntity>> _loadVisibleEvents(
  Ref ref,
  UserAgendaItemsRequest request,
) {
  final completer = Completer<List<CalendarEventEntity>>();
  final subscription = ref.listen<AsyncValue<List<CalendarEventEntity>>>(
    visibleCalendarEventsProvider(
      VisibleCalendarEventsRequest(start: request.start, end: request.end),
    ),
    (_, next) {
      if (completer.isCompleted) return;
      if (next.hasValue) {
        completer.complete(next.requireValue);
      } else if (next.hasError) {
        completer.completeError(next.error!, next.stackTrace);
      }
    },
    fireImmediately: true,
  );
  ref.onDispose(subscription.close);
  return completer.future;
}

Future<List<DepartmentCalendarEventScaleEntity>> _loadMyScalesOrEmpty(
  Ref ref,
  UserAgendaItemsRequest request,
) async {
  final completer = Completer<List<DepartmentCalendarEventScaleEntity>>();
  final subscription = ref
      .listen<AsyncValue<List<DepartmentCalendarEventScaleEntity>>>(
        myCalendarScalesProvider(
          MyCalendarScalesRequest(start: request.start, end: request.end),
        ),
        (_, next) {
          if (completer.isCompleted) return;
          if (next.hasValue) {
            completer.complete(next.requireValue);
          } else if (next.hasError) {
            completer.complete(const []);
          }
        },
        fireImmediately: true,
      );
  ref.onDispose(subscription.close);
  return completer.future;
}

Future<UserAgendaPersonalScalesEntity> _loadPersonalScalesOrEmpty(
  Ref ref,
  UserAgendaItemsRequest request, {
  required Set<String> visibleEventIds,
}) async {
  try {
    final loggedUserId = await _loadLoggedUserIdOrNull(ref);
    if (loggedUserId == null) {
      return const UserAgendaPersonalScalesEntity(
        attachedScales: [],
        standaloneItems: [],
      );
    }

    final scales = await _loadMyScalesOrEmpty(ref, request);
    if (scales.isEmpty) {
      return const UserAgendaPersonalScalesEntity(
        attachedScales: [],
        standaloneItems: [],
      );
    }

    final repository = ref.read(calendarEventRepositoryProvider);
    final departmentRepository = ref.read(departmentRepositoryProvider);
    final departmentNamesById = <String, String>{};
    final lineupsById = <String, List<LineupItemEntity>>{};
    final groupsByKey = <String, _MutablePersonalScaleGroup>{};

    for (final scale in scales) {
      final eventId = scale.calendarEvent.id.trim();
      if (eventId.isEmpty) continue;

      final departmentId = scale.calendarEvent.departmentId?.trim();
      final scaleItemsResult = await repository.getScaleItems(scale.scale.id);
      final scaleItems = scaleItemsResult.fold<List<ScaleItemEntity>?>(
        (_) => null,
        (items) => items,
      );

      final userScaleItems = scaleItems
          ?.where((item) => item.personId == loggedUserId)
          .toList();

      final hasUserScaleItem = userScaleItems?.isNotEmpty ?? true;
      if (!hasUserScaleItem) continue;

      final groupKey = _personalScaleGroupKey(
        eventId: eventId,
        departmentId: departmentId,
        scaleId: scale.scale.id,
      );
      final group = groupsByKey.putIfAbsent(
        groupKey,
        () => _MutablePersonalScaleGroup(
          eventId: eventId,
          scaleId: scale.scale.id,
          departmentId: departmentId,
          department: 'Departamento',
          roles: <String>{},
          attachedToVisibleEvent: visibleEventIds.contains(eventId),
        ),
      );

      group.department = await _resolveDepartmentName(
        departmentRepository: departmentRepository,
        departmentNamesById: departmentNamesById,
        departmentId: departmentId,
      );

      final lineupItems = await _loadLineupItemsOrEmpty(
        repository: departmentRepository,
        lineupsById: lineupsById,
        lineupId: scale.scale.lineupId.trim(),
      );
      final roleLabels = _resolveRoleLabels(
        lineupItems: lineupItems,
        scaleItems: userScaleItems,
      );
      group.roles.addAll(roleLabels);
    }

    final attachedScales = <UserAgendaPersonalScaleGroupEntity>[];
    final standaloneItems = <UserAgendaPersonalScaleItemEntity>[];

    for (final group in groupsByKey.values) {
      if (group.attachedToVisibleEvent) {
        attachedScales.add(
          UserAgendaPersonalScaleGroupEntity(
            eventId: group.eventId,
            scaleId: group.scaleId,
            departmentId: group.departmentId,
            department: group.department,
            roles: group.roles.toList(),
          ),
        );
        continue;
      }

      final sourceEvent = scales
          .map((entry) => entry.calendarEvent)
          .firstWhere((event) => event.id == group.eventId);
      standaloneItems.add(
        UserAgendaPersonalScaleItemEntity(
          id: 'personal-scale-${group.scaleId}',
          title: sourceEvent.title,
          startDateTime: sourceEvent.startDateTime,
          endDateTime: sourceEvent.endDateTime,
          eventId: group.eventId,
          scaleId: group.scaleId,
          departmentId: group.departmentId,
          department: group.department,
          roles: group.roles.toList(),
        ),
      );
    }

    return UserAgendaPersonalScalesEntity(
      attachedScales: attachedScales,
      standaloneItems: standaloneItems,
    );
  } catch (_) {
    return const UserAgendaPersonalScalesEntity(
      attachedScales: [],
      standaloneItems: [],
    );
  }
}

Future<String?> _loadLoggedUserIdOrNull(Ref ref) async {
  try {
    final profile = await ref.watch(editLoggedUserInitialDataProvider.future);
    final id = profile.id.trim();
    return id.isEmpty ? null : id;
  } catch (_) {
    return null;
  }
}

Future<String> _resolveDepartmentName({
  required DepartmentRepository departmentRepository,
  required Map<String, String> departmentNamesById,
  required String? departmentId,
}) async {
  final normalizedDepartmentId = departmentId?.trim() ?? '';
  if (normalizedDepartmentId.isEmpty) {
    return 'Departamento';
  }

  final cached = departmentNamesById[normalizedDepartmentId];
  if (cached != null && cached.isNotEmpty) {
    return cached;
  }

  final result = await departmentRepository.getDepartmentById(
    normalizedDepartmentId,
  );
  return result.fold((_) => 'Departamento', (department) {
    final name = department.name.trim();
    final resolvedName = name.isEmpty ? 'Departamento' : name;
    departmentNamesById[normalizedDepartmentId] = resolvedName;
    return resolvedName;
  });
}

Future<List<LineupItemEntity>> _loadLineupItemsOrEmpty({
  required DepartmentRepository repository,
  required Map<String, List<LineupItemEntity>> lineupsById,
  required String lineupId,
}) async {
  if (lineupId.isEmpty) return const [];

  final cached = lineupsById[lineupId];
  if (cached != null) return cached;

  final result = await repository.getLineupWithItems(lineupId);
  return result.fold((_) => const [], (lineup) {
    final items = lineup.items ?? const [];
    lineupsById[lineupId] = items;
    return items;
  });
}

List<String> _resolveRoleLabels({
  required List<LineupItemEntity> lineupItems,
  required List<ScaleItemEntity>? scaleItems,
}) {
  if (scaleItems == null) {
    return const [];
  }

  final lineupItemsByRoleId = <String, LineupItemEntity>{
    for (final item in lineupItems) item.roleId: item,
  };

  final roleLabels = <String>{};
  for (final scaleItem in scaleItems) {
    final lineupItem = lineupItemsByRoleId[scaleItem.roleId];
    final label = _lineupItemLabel(lineupItem);
    if (label.isEmpty) {
      continue;
    }
    roleLabels.add(label);
  }

  return roleLabels.toList();
}

String _lineupItemLabel(LineupItemEntity? item) {
  if (item == null) return '';
  final roleName = item.role?.name.trim() ?? '';
  if (roleName.isNotEmpty) return roleName;
  return item.description.trim();
}

String _personalScaleGroupKey({
  required String eventId,
  required String? departmentId,
  required String scaleId,
}) {
  final normalizedDepartmentId = departmentId?.trim() ?? '';
  if (normalizedDepartmentId.isNotEmpty) {
    return '$eventId::$normalizedDepartmentId';
  }
  return '$eventId::$scaleId';
}

class _MutablePersonalScaleGroup {
  _MutablePersonalScaleGroup({
    required this.eventId,
    required this.scaleId,
    required this.departmentId,
    required this.department,
    required this.roles,
    required this.attachedToVisibleEvent,
  });

  final String eventId;
  final String scaleId;
  final String? departmentId;
  String department;
  final Set<String> roles;
  final bool attachedToVisibleEvent;
}
