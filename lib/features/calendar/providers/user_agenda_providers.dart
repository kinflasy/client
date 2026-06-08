import 'package:client/features/calendar/domain/entities/user_agenda_item_entity.dart';
import 'package:client/features/calendar/domain/utils/user_agenda_date_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userAgendaTodayProvider = Provider<DateTime>((ref) {
  return normalizeDate(DateTime.now());
});

final userAgendaLocalItemsProvider = Provider<List<UserAgendaItemEntity>>((
  ref,
) {
  final today = ref.watch(userAgendaTodayProvider);
  return buildLocalUserAgendaItems(today);
});

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
