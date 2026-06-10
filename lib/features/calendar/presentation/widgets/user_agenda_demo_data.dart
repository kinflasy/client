import 'package:client/features/calendar/presentation/widgets/user_agenda_day_cell.dart';
import 'package:flutter/material.dart';

class UserAgendaDemoData {
  const UserAgendaDemoData(this.daysByDate);

  final Map<DateTime, UserAgendaDay> daysByDate;

  factory UserAgendaDemoData.relativeTo(DateTime today) {
    final normalizedToday = DateUtils.dateOnly(today);
    final pastEventDate = normalizedToday.subtract(const Duration(days: 3));
    final scaleDate = normalizedToday.add(const Duration(days: 2));
    final birthdayDate = normalizedToday.add(const Duration(days: 4));
    final mixedDate = normalizedToday.add(const Duration(days: 6));

    return UserAgendaDemoData({
      normalizedToday: UserAgendaDay(
        date: normalizedToday,
        events: [
          UserAgendaEvent(
            startsAt: normalizedToday.add(const Duration(hours: 19)),
            title: 'Culto de celebração',
            origin: 'Igreja Central',
          ),
        ],
      ),
      pastEventDate: UserAgendaDay(
        date: pastEventDate,
        events: [
          UserAgendaEvent(
            startsAt: pastEventDate.add(const Duration(hours: 20)),
            title: 'Reunião de liderança',
            origin: 'Ministério de Ensino',
          ),
        ],
      ),
      scaleDate: UserAgendaDay(
        date: scaleDate,
        events: [
          UserAgendaEvent(
            startsAt: scaleDate.add(const Duration(hours: 18, minutes: 30)),
            title: 'Ensaio geral',
            origin: 'Louvor',
            personalScales: const [
              UserAgendaPersonalScale(
                department: 'Louvor',
                roles: ['Vocal', 'Violão'],
              ),
            ],
          ),
        ],
      ),
      birthdayDate: UserAgendaDay(
        date: birthdayDate,
        birthdays: [
          UserAgendaBirthday(day: birthdayDate.day, name: 'Cecília'),
          UserAgendaBirthday(day: birthdayDate.day, name: 'Marcos'),
        ],
      ),
      mixedDate: UserAgendaDay(
        date: mixedDate,
        birthdays: [UserAgendaBirthday(day: mixedDate.day, name: 'Ana')],
        events: [
          UserAgendaEvent(
            startsAt: mixedDate.add(const Duration(hours: 16)),
            title: 'Ação social',
            origin: 'Diaconia',
          ),
        ],
      ),
    });
  }

  Map<DateTime, UserAgendaDayMarkers> get markersByDate {
    return daysByDate.map((date, day) {
      return MapEntry(
        date,
        UserAgendaDayMarkers(
          hasEvent: day.events.isNotEmpty,
          hasUserScale: day.events.any(
            (event) => event.personalScales.isNotEmpty,
          ),
          hasBirthday: day.birthdays.isNotEmpty,
        ),
      );
    });
  }

  UserAgendaDay dayFor(DateTime date) {
    final normalizedDate = DateUtils.dateOnly(date);
    return daysByDate[normalizedDate] ?? UserAgendaDay(date: normalizedDate);
  }
}

class UserAgendaDay {
  const UserAgendaDay({
    required this.date,
    this.birthdays = const [],
    this.events = const [],
  });

  final DateTime date;
  final List<UserAgendaBirthday> birthdays;
  final List<UserAgendaEvent> events;

  bool get isEmpty => birthdays.isEmpty && events.isEmpty;
}

class UserAgendaBirthday {
  const UserAgendaBirthday({required this.day, required this.name});

  final int day;
  final String name;
}

class UserAgendaEvent {
  const UserAgendaEvent({
    required this.startsAt,
    required this.title,
    required this.origin,
    this.personalScales = const [],
  });

  final DateTime startsAt;
  final String title;
  final String origin;
  final List<UserAgendaPersonalScale> personalScales;
}

class UserAgendaPersonalScale {
  const UserAgendaPersonalScale({
    required this.department,
    required this.roles,
  });

  final String department;
  final List<String> roles;
}
