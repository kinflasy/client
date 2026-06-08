import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/calendar/presentation/widgets/user_agenda_day_list.dart';
import 'package:client/features/calendar/presentation/widgets/user_agenda_demo_data.dart';
import 'package:client/features/calendar/presentation/widgets/user_agenda_header.dart';
import 'package:client/features/calendar/presentation/widgets/user_agenda_month_card.dart';
import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime? _today;
  UserAgendaDemoData? _agendaData;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _ensureCalendarState();
  }

  @override
  Widget build(BuildContext context) {
    _ensureCalendarState();

    final today = _today!;
    final selectedDate = _selectedDate!;
    final agendaData = _agendaData!;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.secondaryLight, AppColors.surface],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UserAgendaHeader(onFilterPressed: () {}),
              const SizedBox(height: 22),
              UserAgendaMonthCard(
                focusedDate: today,
                selectedDate: selectedDate,
                today: today,
                markersByDate: agendaData.markersByDate,
                onDaySelected: (date) {
                  setState(() {
                    _selectedDate = DateUtils.dateOnly(date);
                  });
                },
              ),
              const SizedBox(height: 22),
              UserAgendaDayList(
                selectedDate: selectedDate,
                today: today,
                agendaDay: agendaData.dayFor(selectedDate),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _ensureCalendarState() {
    if (_today != null && _selectedDate != null && _agendaData != null) {
      return;
    }

    final today = DateUtils.dateOnly(DateTime.now());
    _today = today;
    _selectedDate = today;
    _agendaData = UserAgendaDemoData.relativeTo(today);
  }
}
