import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/calendar/domain/entities/user_agenda_item_entity.dart';
import 'package:client/features/calendar/domain/entities/user_agenda_state.dart';
import 'package:flutter/material.dart';

class UserAgendaWeekList extends StatefulWidget {
  const UserAgendaWeekList({
    super.key,
    required this.groups,
    required this.selectedDate,
    required this.today,
    this.focusTargetDate,
    this.onEventTap,
  });

  final List<UserAgendaDayGroupEntity> groups;
  final DateTime selectedDate;
  final DateTime today;
  final DateTime? focusTargetDate;
  final ValueChanged<String>? onEventTap;

  @override
  State<UserAgendaWeekList> createState() => _UserAgendaWeekListState();
}

class _UserAgendaWeekListState extends State<UserAgendaWeekList> {
  final Map<DateTime, GlobalKey> _dayKeys = {};
  DateTime? _lastFocusedDate;

  @override
  void didUpdateWidget(UserAgendaWeekList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleFocusIfNeeded();
  }

  @override
  void initState() {
    super.initState();
    _scheduleFocusIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final birthdays = widget.groups
        .expand((group) => group.items)
        .whereType<UserAgendaBirthdayItemEntity>()
        .toList();
    final groupsWithScheduleItems = widget.groups.where((group) {
      return group.items.any((item) => item is! UserAgendaBirthdayItemEntity);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Essa semana',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (birthdays.isNotEmpty) ...[
          _BirthdayRow(birthdays: birthdays),
          const SizedBox(height: 16),
        ],
        if (groupsWithScheduleItems.isEmpty && birthdays.isEmpty)
          const _EmptyWeekMessage()
        else
          for (
            var index = 0;
            index < groupsWithScheduleItems.length;
            index++
          ) ...[
            _WeekDayGroup(
              key: _keyForDate(groupsWithScheduleItems[index].date),
              group: groupsWithScheduleItems[index],
              today: widget.today,
              isSelected: DateUtils.isSameDay(
                groupsWithScheduleItems[index].date,
                widget.selectedDate,
              ),
              onEventTap: widget.onEventTap,
            ),
            if (index < groupsWithScheduleItems.length - 1)
              const SizedBox(height: 16),
          ],
      ],
    );
  }

  GlobalKey _keyForDate(DateTime date) {
    final normalizedDate = DateUtils.dateOnly(date);
    return _dayKeys.putIfAbsent(normalizedDate, GlobalKey.new);
  }

  void _scheduleFocusIfNeeded() {
    final focusTargetDate = widget.focusTargetDate;
    if (focusTargetDate == null) return;

    final normalizedTargetDate = DateUtils.dateOnly(focusTargetDate);
    if (_lastFocusedDate == normalizedTargetDate) return;

    final hasScheduleItems = widget.groups.any((group) {
      final isTargetDate = DateUtils.isSameDay(
        group.date,
        normalizedTargetDate,
      );
      final hasNonBirthdayItem = group.items.any(
        (item) => item is! UserAgendaBirthdayItemEntity,
      );
      return isTargetDate && hasNonBirthdayItem;
    });
    if (!hasScheduleItems) return;

    _lastFocusedDate = normalizedTargetDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _dayKeys[normalizedTargetDate]?.currentContext;
      if (context == null || !mounted) return;

      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }
}

class _WeekDayGroup extends StatelessWidget {
  const _WeekDayGroup({
    super.key,
    required this.group,
    required this.today,
    required this.isSelected,
    this.onEventTap,
  });

  final UserAgendaDayGroupEntity group;
  final DateTime today;
  final bool isSelected;
  final ValueChanged<String>? onEventTap;

  @override
  Widget build(BuildContext context) {
    final scheduleItems = group.items
        .where((item) => item is! UserAgendaBirthdayItemEntity)
        .toList();

    return Column(
      key: ValueKey('user-agenda-week-day-${_dateKey(group.date)}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DayTitle(date: group.date, today: today, isSelected: isSelected),
        const SizedBox(height: 8),
        for (var index = 0; index < scheduleItems.length; index++) ...[
          _AgendaItemCard(item: scheduleItems[index], onEventTap: onEventTap),
          if (index < scheduleItems.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _DayTitle extends StatelessWidget {
  const _DayTitle({
    required this.date,
    required this.today,
    required this.isSelected,
  });

  final DateTime date;
  final DateTime today;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(date, today);

    return Row(
      children: [
        Expanded(
          child: Text(
            isToday ? 'Hoje' : _formatDayTitle(date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (isSelected)
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Text(
                'Selecionado',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BirthdayRow extends StatelessWidget {
  const _BirthdayRow({required this.birthdays});

  final List<UserAgendaBirthdayItemEntity> birthdays;

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
                final birthday = birthdays[index];
                return _BirthdayCard(birthday: birthday);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthdayCard extends StatelessWidget {
  const _BirthdayCard({required this.birthday});

  final UserAgendaBirthdayItemEntity birthday;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3D77A).withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          '${birthday.startDateTime.day} | ${birthday.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AgendaItemCard extends StatelessWidget {
  const _AgendaItemCard({required this.item, this.onEventTap});

  final UserAgendaItemEntity item;
  final ValueChanged<String>? onEventTap;

  @override
  Widget build(BuildContext context) {
    final item = this.item;
    if (item is UserAgendaEventItemEntity) {
      return _EventCard(event: item, onEventTap: onEventTap);
    }
    if (item is UserAgendaPersonalScaleItemEntity) {
      return _PersonalScaleEventCard(scale: item);
    }
    return const SizedBox.shrink();
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, this.onEventTap});

  final UserAgendaEventItemEntity event;
  final ValueChanged<String>? onEventTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BaseEventSurface(
          startsAt: event.startDateTime,
          title: event.title,
          subtitle: event.origin,
          onTap: onEventTap == null ? null : () => onEventTap!(event.id),
        ),
        for (final scale in event.personalScales)
          _PersonalScaleCard(department: scale.department, roles: scale.roles),
      ],
    );
  }
}

class _PersonalScaleEventCard extends StatelessWidget {
  const _PersonalScaleEventCard({required this.scale});

  final UserAgendaPersonalScaleItemEntity scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BaseEventSurface(
          startsAt: scale.startDateTime,
          title: scale.title,
          subtitle: scale.department,
        ),
        _PersonalScaleCard(department: scale.department, roles: scale.roles),
      ],
    );
  }
}

class _BaseEventSurface extends StatelessWidget {
  const _BaseEventSurface({
    required this.startsAt,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final DateTime startsAt;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatTime(startsAt),
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Material(
      color: AppColors.surface.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class _PersonalScaleCard extends StatelessWidget {
  const _PersonalScaleCard({required this.department, required this.roles});

  final String department;
  final List<String> roles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.tertiary.withValues(alpha: 0.16),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            '$department - ${roles.join(', ')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyWeekMessage extends StatelessWidget {
  const _EmptyWeekMessage();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Icon(Icons.event_available_rounded, color: AppColors.textSecondary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nenhum item nesta semana.',
                style: TextStyle(color: AppColors.textSecondary),
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

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
