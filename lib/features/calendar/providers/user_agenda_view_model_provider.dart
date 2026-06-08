import 'package:client/features/calendar/domain/entities/user_agenda_item_entity.dart';
import 'package:client/features/calendar/domain/entities/user_agenda_state.dart';
import 'package:client/features/calendar/domain/utils/user_agenda_date_utils.dart';
import 'package:client/features/calendar/providers/user_agenda_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userAgendaViewModelProvider =
    NotifierProvider<UserAgendaViewModel, UserAgendaState>(
      UserAgendaViewModel.new,
    );

class UserAgendaViewModel extends Notifier<UserAgendaState> {
  @override
  UserAgendaState build() {
    final today = ref.watch(userAgendaTodayProvider);
    final items = ref.watch(userAgendaLocalItemsProvider);
    return _buildState(
      today: today,
      focusedMonth: firstDayOfMonth(today),
      selectedDate: today,
      focusTargetDate: null,
      items: items,
    );
  }

  void selectDate(DateTime date) {
    final selectedDate = normalizeDate(date);
    state = _buildState(
      today: state.today,
      focusedMonth: firstDayOfMonth(selectedDate),
      selectedDate: selectedDate,
      focusTargetDate: selectedDate,
      items: ref.read(userAgendaLocalItemsProvider),
    );
  }

  void goToPreviousMonth() {
    final targetMonth = DateTime(
      state.focusedMonth.year,
      state.focusedMonth.month - 1,
    );
    _selectMonthStart(targetMonth);
  }

  void goToNextMonth() {
    final targetMonth = DateTime(
      state.focusedMonth.year,
      state.focusedMonth.month + 1,
    );
    _selectMonthStart(targetMonth);
  }

  void goToToday() {
    state = _buildState(
      today: state.today,
      focusedMonth: firstDayOfMonth(state.today),
      selectedDate: state.today,
      focusTargetDate: null,
      items: ref.read(userAgendaLocalItemsProvider),
    );
  }

  void _selectMonthStart(DateTime month) {
    final selectedDate = firstDayOfMonth(month);
    state = _buildState(
      today: state.today,
      focusedMonth: selectedDate,
      selectedDate: selectedDate,
      focusTargetDate: null,
      items: ref.read(userAgendaLocalItemsProvider),
    );
  }
}

UserAgendaState _buildState({
  required DateTime today,
  required DateTime focusedMonth,
  required DateTime selectedDate,
  required DateTime? focusTargetDate,
  required List<UserAgendaItemEntity> items,
}) {
  final normalizedToday = normalizeDate(today);
  final normalizedSelectedDate = normalizeDate(selectedDate);
  final visibleWeekStart = weekStart(normalizedSelectedDate);
  final visibleWeekEnd = weekEnd(normalizedSelectedDate);
  final itemsByDate = _groupItemsByDate(items);

  return UserAgendaState(
    today: normalizedToday,
    focusedMonth: firstDayOfMonth(focusedMonth),
    selectedDate: normalizedSelectedDate,
    visibleWeekStart: visibleWeekStart,
    visibleWeekEnd: visibleWeekEnd,
    focusTargetDate: focusTargetDate == null
        ? null
        : normalizeDate(focusTargetDate),
    weeklyGroups: List.generate(DateTime.daysPerWeek, (index) {
      final date = visibleWeekStart.add(Duration(days: index));
      return UserAgendaDayGroupEntity(
        date: date,
        items: itemsByDate[date] ?? const [],
      );
    }),
    markersByDate: _buildMarkersByDate(itemsByDate),
  );
}

Map<DateTime, List<UserAgendaItemEntity>> _groupItemsByDate(
  List<UserAgendaItemEntity> items,
) {
  final entries = <DateTime, List<UserAgendaItemEntity>>{};

  for (final item in items) {
    for (final occurrence in expandItemOccurrences(item)) {
      final itemsForDate = entries.putIfAbsent(occurrence.date, () => []);
      itemsForDate.add(item);
    }
  }

  for (final itemsForDate in entries.values) {
    itemsForDate.sort(_compareAgendaItems);
  }

  return entries;
}

Map<DateTime, UserAgendaDateMarkersEntity> _buildMarkersByDate(
  Map<DateTime, List<UserAgendaItemEntity>> itemsByDate,
) {
  return itemsByDate.map((date, items) {
    return MapEntry(
      date,
      UserAgendaDateMarkersEntity(
        hasEvent: items.any((item) => item.type == UserAgendaItemType.event),
        hasUserScale: items.any((item) => item.isUserEvent),
        hasBirthday: items.any(
          (item) => item.type == UserAgendaItemType.birthday,
        ),
      ),
    );
  });
}

int _compareAgendaItems(UserAgendaItemEntity a, UserAgendaItemEntity b) {
  final startComparison = a.startDateTime.compareTo(b.startDateTime);
  if (startComparison != 0) return startComparison;

  final typeComparison = a.type.index.compareTo(b.type.index);
  if (typeComparison != 0) return typeComparison;

  return a.title.toLowerCase().compareTo(b.title.toLowerCase());
}
