import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/church/domain/entities/church_department_entity.dart';
import 'package:client/features/church/domain/entities/church_event_entity.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChurchProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  const ChurchProfileTabBarDelegate({this.isVisitorMode = false});

  final bool isVisitorMode;

  @override
  double get minExtent => kTextTabBarHeight;

  @override
  double get maxExtent => kTextTabBarHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final tabs = isVisitorMode
        ? const [Tab(text: 'Eventos')]
        : const [
            Tab(text: 'Eventos'),
            Tab(text: 'Ministérios'),
            Tab(text: 'Avisos'),
          ];

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      child: TabBar(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: tabs,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant ChurchProfileTabBarDelegate oldDelegate) {
    return oldDelegate.isVisitorMode != isVisitorMode;
  }
}

class ChurchProfileMemberTabView extends StatelessWidget {
  const ChurchProfileMemberTabView({super.key, required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: TabBarView(
        children: [
          ChurchEventsTab(unitId: unitId),
          ChurchDepartmentsTab(unitId: unitId),
          const ChurchAnnouncementsTab(),
        ],
      ),
    );
  }
}

class ChurchProfileVisitorTabView extends StatelessWidget {
  const ChurchProfileVisitorTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(child: ChurchVisitorEventsPlaceholderTab());
  }
}

class ChurchVisitorEventsPlaceholderTab extends StatelessWidget {
  const ChurchVisitorEventsPlaceholderTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InlineStatus(
      icon: Icons.event_note_outlined,
      title: 'Eventos públicos em breve.',
      subtitle:
          'Esta área ficará disponível quando trabalharmos o contrato de eventos públicos.',
    );
  }
}

class ChurchEventsTab extends ConsumerWidget {
  const ChurchEventsTab({super.key, required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(churchEventsProvider(unitId));
    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const _InlineStatus(
        icon: Icons.event_busy_outlined,
        title: 'Não foi possível carregar os eventos.',
      ),
      data: (events) {
        if (events.isEmpty) {
          return const _InlineStatus(
            icon: Icons.event_note_outlined,
            title: 'Nenhum evento encontrado.',
            subtitle: 'Os próximos eventos da sua igreja aparecerão aqui.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: events.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _EventCard(event: events[index]),
        );
      },
    );
  }
}

class ChurchDepartmentsTab extends ConsumerWidget {
  const ChurchDepartmentsTab({super.key, required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentsAsync = ref.watch(churchDepartmentsProvider(unitId));
    return departmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const _InlineStatus(
        icon: Icons.groups_2_outlined,
        title: 'Não foi possível carregar os ministérios.',
      ),
      data: (departments) {
        if (departments.isEmpty) {
          return const _InlineStatus(
            icon: Icons.groups_outlined,
            title: 'Nenhum ministério encontrado.',
            subtitle:
                'Quando houver departamentos ativos, eles aparecerão aqui.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: departments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _DepartmentCard(department: departments[index]),
        );
      },
    );
  }
}

class ChurchAnnouncementsTab extends StatelessWidget {
  const ChurchAnnouncementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InlineStatus(
      icon: Icons.campaign_outlined,
      title: 'Avisos em breve.',
      subtitle: 'Esta área ficará disponível quando o backend expuser esse feed.',
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final ChurchEventEntity event;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDateRange(event.startDateTime, event.endDateTime),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if ((event.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              event.description!,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ],
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({required this.department});

  final ChurchDepartmentEntity department;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8F0FE),
          child: Icon(
            department.type == 'ADMINISTRATIVE'
                ? Icons.admin_panel_settings_outlined
                : Icons.groups_3_outlined,
            color: AppColors.primary,
          ),
        ),
        title: Text(department.name),
        subtitle: Text(
          department.slug != null && department.slug!.isNotEmpty
              ? '@${department.slug}'
              : department.type ?? 'Ministério',
        ),
      ),
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatDateRange(DateTime start, DateTime end) {
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
  final startLabel =
      '${start.day} ${months[start.month - 1]} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
  final endLabel =
      '${end.day} ${months[end.month - 1]} ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  return '$startLabel - $endLabel';
}
