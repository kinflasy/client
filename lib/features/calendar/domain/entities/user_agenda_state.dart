import 'package:client/features/calendar/domain/entities/user_agenda_item_entity.dart';
import 'package:equatable/equatable.dart';

class UserAgendaState extends Equatable {
  const UserAgendaState({
    required this.today,
    required this.focusedMonth,
    required this.selectedDate,
    required this.visibleWeekStart,
    required this.visibleWeekEnd,
    required this.weeklyGroups,
    required this.markersByDate,
    this.focusTargetDate,
    this.isLoading = false,
    this.errorMessage,
    this.isUsingRealEvents = false,
  });

  final DateTime today;
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final DateTime visibleWeekStart;
  final DateTime visibleWeekEnd;
  final DateTime? focusTargetDate;
  final List<UserAgendaDayGroupEntity> weeklyGroups;
  final Map<DateTime, UserAgendaDateMarkersEntity> markersByDate;
  final bool isLoading;
  final String? errorMessage;
  final bool isUsingRealEvents;

  UserAgendaState copyWith({
    DateTime? today,
    DateTime? focusedMonth,
    DateTime? selectedDate,
    DateTime? visibleWeekStart,
    DateTime? visibleWeekEnd,
    DateTime? focusTargetDate,
    bool clearFocusTargetDate = false,
    List<UserAgendaDayGroupEntity>? weeklyGroups,
    Map<DateTime, UserAgendaDateMarkersEntity>? markersByDate,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isUsingRealEvents,
  }) {
    return UserAgendaState(
      today: today ?? this.today,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedDate: selectedDate ?? this.selectedDate,
      visibleWeekStart: visibleWeekStart ?? this.visibleWeekStart,
      visibleWeekEnd: visibleWeekEnd ?? this.visibleWeekEnd,
      focusTargetDate: clearFocusTargetDate
          ? null
          : focusTargetDate ?? this.focusTargetDate,
      weeklyGroups: weeklyGroups ?? this.weeklyGroups,
      markersByDate: markersByDate ?? this.markersByDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      isUsingRealEvents: isUsingRealEvents ?? this.isUsingRealEvents,
    );
  }

  @override
  List<Object?> get props => [
    today,
    focusedMonth,
    selectedDate,
    visibleWeekStart,
    visibleWeekEnd,
    focusTargetDate,
    weeklyGroups,
    markersByDate,
    isLoading,
    errorMessage,
    isUsingRealEvents,
  ];
}

class UserAgendaDayGroupEntity extends Equatable {
  const UserAgendaDayGroupEntity({required this.date, this.items = const []});

  final DateTime date;
  final List<UserAgendaItemEntity> items;

  bool get hasItems => items.isNotEmpty;

  @override
  List<Object?> get props => [date, items];
}

class UserAgendaDateMarkersEntity extends Equatable {
  const UserAgendaDateMarkersEntity({
    this.hasEvent = false,
    this.hasUserScale = false,
    this.hasBirthday = false,
  });

  final bool hasEvent;
  final bool hasUserScale;
  final bool hasBirthday;

  @override
  List<Object?> get props => [hasEvent, hasUserScale, hasBirthday];
}
