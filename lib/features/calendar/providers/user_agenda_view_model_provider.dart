import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/domain/entities/user_agenda_item_entity.dart';
import 'package:client/features/calendar/domain/entities/user_agenda_state.dart';
import 'package:client/features/calendar/domain/utils/user_agenda_date_utils.dart';
import 'package:client/features/calendar/providers/user_agenda_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userAgendaViewModelProvider =
    AsyncNotifierProvider<UserAgendaViewModel, UserAgendaState>(
      UserAgendaViewModel.new,
    );

class UserAgendaViewModel extends AsyncNotifier<UserAgendaState> {
  List<UserAgendaItemEntity> _items = const [];

  @override
  Future<UserAgendaState> build() async {
    final today = ref.watch(userAgendaTodayProvider);
    final focusedMonth = firstDayOfMonth(today);

    try {
      return await _loadState(
        today: today,
        focusedMonth: focusedMonth,
        selectedDate: today,
        focusTargetDate: null,
      );
    } catch (error) {
      _items = const [];
      return _buildState(
        today: today,
        focusedMonth: focusedMonth,
        selectedDate: today,
        focusTargetDate: null,
        items: _items,
        errorMessage: _errorMessage(error),
        isUsingRealEvents: true,
      );
    }
  }

  Future<void> selectDate(DateTime date) async {
    final current = state.value;
    if (current == null) return;

    final selectedDate = normalizeDate(date);
    final focusedMonth = firstDayOfMonth(selectedDate);

    if (focusedMonth == current.focusedMonth) {
      state = AsyncData(
        _buildState(
          today: current.today,
          focusedMonth: current.focusedMonth,
          selectedDate: selectedDate,
          focusTargetDate: selectedDate,
          items: _items,
          isUsingRealEvents: true,
        ),
      );
      return;
    }

    await _loadSelectedMonth(
      current: current,
      focusedMonth: focusedMonth,
      selectedDate: selectedDate,
      focusTargetDate: selectedDate,
    );
  }

  Future<void> goToPreviousMonth() async {
    final current = state.value;
    if (current == null) return;

    final targetMonth = DateTime(
      current.focusedMonth.year,
      current.focusedMonth.month - 1,
    );
    await _selectMonthStart(current, targetMonth);
  }

  Future<void> goToNextMonth() async {
    final current = state.value;
    if (current == null) return;

    final targetMonth = DateTime(
      current.focusedMonth.year,
      current.focusedMonth.month + 1,
    );
    await _selectMonthStart(current, targetMonth);
  }

  Future<void> goToToday() async {
    final current = state.value;
    if (current == null) return;

    final focusedMonth = firstDayOfMonth(current.today);
    if (focusedMonth == current.focusedMonth) {
      state = AsyncData(
        _buildState(
          today: current.today,
          focusedMonth: focusedMonth,
          selectedDate: current.today,
          focusTargetDate: null,
          items: _items,
          isUsingRealEvents: true,
        ),
      );
      return;
    }

    await _loadSelectedMonth(
      current: current,
      focusedMonth: focusedMonth,
      selectedDate: current.today,
      focusTargetDate: null,
    );
  }

  Future<void> retry() async {
    final current = state.value;
    if (current == null) {
      ref.invalidateSelf();
      return;
    }

    await _loadSelectedMonth(
      current: current,
      focusedMonth: current.focusedMonth,
      selectedDate: current.selectedDate,
      focusTargetDate: null,
    );
  }

  Future<void> _selectMonthStart(
    UserAgendaState current,
    DateTime month,
  ) async {
    final selectedDate = firstDayOfMonth(month);
    await _loadSelectedMonth(
      current: current,
      focusedMonth: selectedDate,
      selectedDate: selectedDate,
      focusTargetDate: null,
    );
  }

  Future<void> _loadSelectedMonth({
    required UserAgendaState current,
    required DateTime focusedMonth,
    required DateTime selectedDate,
    required DateTime? focusTargetDate,
  }) async {
    state = AsyncData(
      _buildState(
        today: current.today,
        focusedMonth: focusedMonth,
        selectedDate: selectedDate,
        focusTargetDate: focusTargetDate,
        items: _items,
        isLoading: true,
        isUsingRealEvents: true,
      ),
    );

    try {
      state = AsyncData(
        await _loadState(
          today: current.today,
          focusedMonth: focusedMonth,
          selectedDate: selectedDate,
          focusTargetDate: focusTargetDate,
        ),
      );
    } catch (error) {
      state = AsyncData(
        _buildState(
          today: current.today,
          focusedMonth: focusedMonth,
          selectedDate: selectedDate,
          focusTargetDate: focusTargetDate,
          items: _items,
          errorMessage: _errorMessage(error),
          isUsingRealEvents: true,
        ),
      );
    }
  }

  Future<UserAgendaState> _loadState({
    required DateTime today,
    required DateTime focusedMonth,
    required DateTime selectedDate,
    required DateTime? focusTargetDate,
  }) async {
    final request = UserAgendaItemsRequest.forFocusedMonth(focusedMonth);
    _items = await ref.read(userAgendaItemsProvider(request).future);

    return _buildState(
      today: today,
      focusedMonth: focusedMonth,
      selectedDate: selectedDate,
      focusTargetDate: focusTargetDate,
      items: _items,
      isUsingRealEvents: true,
    );
  }
}

UserAgendaState _buildState({
  required DateTime today,
  required DateTime focusedMonth,
  required DateTime selectedDate,
  required DateTime? focusTargetDate,
  required List<UserAgendaItemEntity> items,
  bool isLoading = false,
  String? errorMessage,
  bool isUsingRealEvents = false,
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
    isLoading: isLoading,
    errorMessage: errorMessage,
    isUsingRealEvents: isUsingRealEvents,
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

String _errorMessage(Object error) {
  if (error is Failure) return error.message;
  final text = error.toString().trim();
  if (text.isNotEmpty) return text;
  return 'Erro ao carregar agenda.';
}
