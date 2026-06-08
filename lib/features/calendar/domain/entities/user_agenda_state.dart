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
  });

  final DateTime today;
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final DateTime visibleWeekStart;
  final DateTime visibleWeekEnd;
  final DateTime? focusTargetDate;
  final List<UserAgendaDayGroupEntity> weeklyGroups;
  final Map<DateTime, UserAgendaDateMarkersEntity> markersByDate;

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
