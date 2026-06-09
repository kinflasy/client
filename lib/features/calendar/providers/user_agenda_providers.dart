import 'dart:async';

import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/domain/entities/person_birthday_entity.dart';
import 'package:client/features/calendar/domain/entities/user_agenda_item_entity.dart';
import 'package:client/features/calendar/domain/utils/month_day_utils.dart';
import 'package:client/features/calendar/domain/utils/user_agenda_date_utils.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
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

      return [
            ...events.map(mapCalendarEventToUserAgendaItem),
            ...birthdays.map(
              (birthday) =>
                  mapPersonBirthdayToUserAgendaItem(birthday, request: request),
            ),
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
  final normalizedToday = normalizeDate(today);
  final scaleDate = normalizedToday.add(const Duration(days: 2));

  return [
    UserAgendaPersonalScaleItemEntity(
      id: 'demo-personal-scale-louvor',
      title: 'Ensaio geral',
      startDateTime: scaleDate.add(const Duration(hours: 18, minutes: 30)),
      endDateTime: scaleDate.add(const Duration(hours: 20)),
      eventId: 'demo-event-scale',
      scaleId: 'demo-scale-louvor',
      department: 'Louvor',
      roles: const ['Vocal', 'Violão'],
    ),
  ];
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
