import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/scale/domain/entities/department_scale_with_lineup_entity.dart';
import 'package:client/features/scale/providers/calendar_event_scale_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DepartmentScaleDetailScreen extends ConsumerWidget {
  const DepartmentScaleDetailScreen({
    super.key,
    required this.departmentId,
    required this.scaleId,
    this.initialScale,
  });

  final String departmentId;
  final String scaleId;
  final DepartmentScaleWithLineupEntity? initialScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(
      departmentScaleDetailProvider(
        DepartmentScaleDetailRequest(
          departmentId: departmentId,
          scaleId: scaleId,
          initialScale: initialScale,
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle(detailAsync)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
      ),
      backgroundColor: AppColors.surface,
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _DetailStatus(
          icon: Icons.assignment_late_outlined,
          title: 'Não foi possível carregar a escala.',
          subtitle: _errorMessage(error),
        ),
        data: (detail) => _ScaleDetailContent(detail: detail),
      ),
    );
  }
}

class _ScaleDetailContent extends StatelessWidget {
  const _ScaleDetailContent({required this.detail});

  final DepartmentScaleWithLineupEntity detail;

  @override
  Widget build(BuildContext context) {
    final event = detail.scale.calendarEvent;
    final lineup = detail.lineup;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatEventStart(event.startDateTime),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          _lineupName(lineup),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _LineupItemsSection(detail: detail),
      ],
    );
  }
}

class _LineupItemsSection extends StatelessWidget {
  const _LineupItemsSection({required this.detail});

  final DepartmentScaleWithLineupEntity detail;

  @override
  Widget build(BuildContext context) {
    if (detail.hasLineupFailure) {
      return const _InlineMessage(
        text: 'Não foi possível carregar as funções da formação.',
      );
    }

    final items = detail.lineup?.items ?? const <LineupItemEntity>[];
    if (items.isEmpty) {
      return const _InlineMessage(text: 'Nenhuma função definida');
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inactiveBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _LineupItemTile(item: items[index]),
            if (index < items.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _LineupItemTile extends StatelessWidget {
  const _LineupItemTile({required this.item});

  final LineupItemEntity item;

  @override
  Widget build(BuildContext context) {
    final title = _itemTitle(item);
    final description = item.description.trim();
    final showDescription =
        description.isNotEmpty &&
        description.toLowerCase() != title.toLowerCase();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (showDescription) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inactiveBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _DetailStatus extends StatelessWidget {
  const _DetailStatus({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

String _appBarTitle(AsyncValue<DepartmentScaleWithLineupEntity> detailAsync) {
  return detailAsync.when(
    loading: () => 'Carregando...',
    error: (_, _) => 'Escala',
    data: (detail) => detail.scale.calendarEvent.title,
  );
}

String _formatEventStart(DateTime value) {
  return '${_weekday(value)}, ${value.day} ${_month(value)} · ${_twoDigits(value.hour)}h${_twoDigits(value.minute)}';
}

String _weekday(DateTime value) {
  return const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][value.weekday -
      1];
}

String _month(DateTime value) {
  return const [
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
  ][value.month - 1];
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _lineupName(LineupEntity? lineup) {
  final name = lineup?.name.trim();
  if (name != null && name.isNotEmpty) return name;
  return 'Formação indisponível';
}

String _itemTitle(LineupItemEntity item) {
  final roleName = item.role?.name.trim();
  if (roleName != null && roleName.isNotEmpty) return roleName;
  final description = item.description.trim();
  return description.isEmpty ? 'Função sem nome' : description;
}

String _errorMessage(Object error) {
  if (error is Failure && error.message.trim().isNotEmpty) {
    return error.message;
  }
  return 'Tente novamente em instantes.';
}
