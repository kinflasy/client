import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/calendar/presentation/widgets/user_agenda_day_cards.dart';
import 'package:client/features/calendar/presentation/widgets/user_agenda_demo_data.dart';
import 'package:flutter/material.dart';

class UserAgendaDayList extends StatelessWidget {
  const UserAgendaDayList({
    super.key,
    required this.selectedDate,
    required this.today,
    required this.agendaDay,
  });

  final DateTime selectedDate;
  final DateTime today;
  final UserAgendaDay agendaDay;

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(selectedDate, today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isToday ? 'hoje' : _formatDayTitle(selectedDate),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (agendaDay.birthdays.isNotEmpty) ...[
          _BirthdayRow(birthdays: agendaDay.birthdays),
          const SizedBox(height: 12),
        ],
        if (agendaDay.events.isNotEmpty)
          for (var index = 0; index < agendaDay.events.length; index++) ...[
            UserAgendaEventSummaryCard(event: agendaDay.events[index]),
            if (index < agendaDay.events.length - 1) const SizedBox(height: 10),
          ]
        else if (agendaDay.birthdays.isEmpty)
          _EmptyAgendaMessage(isToday: isToday),
      ],
    );
  }
}

class _BirthdayRow extends StatelessWidget {
  const _BirthdayRow({required this.birthdays});

  final List<UserAgendaBirthday> birthdays;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          const Icon(
            Icons.celebration_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: birthdays.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return UserAgendaBirthdayCard(birthday: birthdays[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAgendaMessage extends StatelessWidget {
  const _EmptyAgendaMessage({required this.isToday});

  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            const Icon(
              Icons.event_available_rounded,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isToday ? 'Nada na agenda hoje.' : 'Nada na agenda deste dia.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDayTitle(DateTime date) {
  const weekdays = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];
  const months = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}
