import 'package:client/features/calendar/domain/entities/user_agenda_item_entity.dart';

class UserAgendaItemOccurrence<T extends UserAgendaItemEntity> {
  const UserAgendaItemOccurrence({required this.dateTime, required this.item});

  final DateTime dateTime;
  final T item;

  DateTime get date => normalizeDate(dateTime);
}

DateTime normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime firstDayOfMonth(DateTime date) {
  return DateTime(date.year, date.month);
}

DateTime weekStart(DateTime date) {
  final normalizedDate = normalizeDate(date);
  final daysSinceSunday = normalizedDate.weekday % DateTime.daysPerWeek;
  return normalizedDate.subtract(Duration(days: daysSinceSunday));
}

DateTime weekEnd(DateTime date) {
  return weekStart(date).add(const Duration(days: DateTime.daysPerWeek - 1));
}

DateTime firstVisibleDayOfMonth(DateTime focusedMonth) {
  return weekStart(firstDayOfMonth(focusedMonth));
}

DateTime lastVisibleDayOfMonth(DateTime focusedMonth) {
  final lastOfMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
  final daysUntilSaturday =
      (DateTime.saturday - lastOfMonth.weekday) % DateTime.daysPerWeek;
  return normalizeDate(lastOfMonth.add(Duration(days: daysUntilSaturday)));
}

List<DateTime> visibleDatesForMonth(DateTime focusedMonth) {
  final firstVisibleDate = firstVisibleDayOfMonth(focusedMonth);
  final lastVisibleDate = lastVisibleDayOfMonth(focusedMonth);
  final visibleDayCount =
      lastVisibleDate.difference(firstVisibleDate).inDays + 1;

  return List.generate(
    visibleDayCount,
    (index) => normalizeDate(firstVisibleDate.add(Duration(days: index))),
  );
}

List<UserAgendaItemOccurrence<T>>
expandItemOccurrences<T extends UserAgendaItemEntity>(T item) {
  final startDate = normalizeDate(item.startDateTime);
  final endDate = normalizeDate(item.endDateTime);

  if (endDate.isBefore(startDate)) {
    return [
      UserAgendaItemOccurrence<T>(dateTime: item.startDateTime, item: item),
    ];
  }

  final dayCount = endDate.difference(startDate).inDays + 1;

  return List.generate(dayCount, (index) {
    final occurrenceDate = startDate.add(Duration(days: index));
    final occurrenceDateTime = DateTime(
      occurrenceDate.year,
      occurrenceDate.month,
      occurrenceDate.day,
      item.startDateTime.hour,
      item.startDateTime.minute,
      item.startDateTime.second,
      item.startDateTime.millisecond,
      item.startDateTime.microsecond,
    );

    return UserAgendaItemOccurrence<T>(
      dateTime: occurrenceDateTime,
      item: item,
    );
  });
}
