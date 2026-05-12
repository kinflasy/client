import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/domain/session_permissions.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/calendar/presentation/widgets/event_card.dart';
import 'package:client/features/calendar/presentation/widgets/event_detail_bottom_sheet.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/presentation/widgets/department_card.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            Tab(text: 'Departamentos'),
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
  const ChurchProfileMemberTabView({
    super.key,
    required this.unitId,
    this.unitName,
  });

  final String unitId;
  final String? unitName;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: TabBarView(
        children: [
          ChurchEventsTab(unitId: unitId, unitName: unitName),
          DepartmentsTab(unitId: unitId),
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
  const ChurchEventsTab({super.key, required this.unitId, this.unitName});

  final String unitId;
  final String? unitName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(sessionPermissionsProvider);
    final eventsAsync = ref.watch(
      visibleUnitCalendarEventsProvider(
        UnitCalendarEventsRequest(
          unitId: unitId,
          start: _initialEventsStart(),
          end: _initialEventsEnd(),
        ),
      ),
    );
    final departmentsAsync = ref.watch(departmentsProvider(unitId));
    final unitLabel = _nonEmptyOrFallback(unitName, 'Unidade');
    final canEdit =
        permissionsAsync.whenOrNull(
          data: (permissions) => permissions.isUnitAdmin,
        ) ??
        false;

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
          itemBuilder: (context, index) {
            final event = events[index];
            final departments =
                departmentsAsync.whenOrNull(
                  data: (departments) => departments,
                ) ??
                const <DepartmentEntity>[];
            return EventCard(
              event: event,
              organizerLabel: _organizerLabelForEvent(
                event,
                unitLabel,
                departments,
              ),
              onEdit: canEdit
                  ? () => context.pushNamed(
                      AppRoutes.adminCalendarEditName,
                      pathParameters: {'id': event.id},
                    )
                  : null,
              onTap: () =>
                  showEventDetailBottomSheet(context, eventId: event.id),
            );
          },
        );
      },
    );
  }
}

String _organizerLabelForEvent(
  CalendarEventEntity event,
  String unitLabel,
  List<DepartmentEntity> departments,
) {
  final departmentId = event.departmentId?.trim();
  if (departmentId == null || departmentId.isEmpty) return unitLabel;

  final departmentName = _departmentName(departments, departmentId);
  return departmentName == null ? unitLabel : '$unitLabel - $departmentName';
}

String? _departmentName(List<DepartmentEntity> departments, String id) {
  for (final department in departments) {
    if (department.id == id) return department.name;
  }
  return null;
}

String _nonEmptyOrFallback(String? value, String fallback) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
}

class DepartmentsTab extends ConsumerWidget {
  const DepartmentsTab({super.key, required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentsAsync = ref.watch(segmentedDepartmentsProvider(unitId));
    final permissionsAsync = ref.watch(sessionPermissionsProvider);
    return departmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const _InlineStatus(
        icon: Icons.groups_2_outlined,
        title: 'Não foi possível carregar os departamentos.',
      ),
      data: (segmentedDepartments) {
        final sections = <_DepartmentSection>[
          if (segmentedDepartments.myDepartments.isNotEmpty)
            _DepartmentSection(
              category: DepartmentCategory.my,
              title: 'Meus departamentos',
              departments: segmentedDepartments.myDepartments,
            ),
          if (segmentedDepartments.generalDepartments.isNotEmpty)
            _DepartmentSection(
              category: DepartmentCategory.general,
              title: 'Geral',
              departments: segmentedDepartments.generalDepartments,
            ),
          if (segmentedDepartments.administrativeDepartments.isNotEmpty)
            _DepartmentSection(
              category: DepartmentCategory.administrative,
              title: 'Administrativo',
              departments: segmentedDepartments.administrativeDepartments,
            ),
        ];

        if (sections.isEmpty) {
          return const _InlineStatus(
            icon: Icons.groups_outlined,
            title: 'Nenhum departamento encontrado.',
            subtitle:
                'Quando houver departamentos ativos, eles aparecerão aqui.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: sections.length,
          separatorBuilder: (context, index) => const SizedBox(height: 24),
          itemBuilder: (context, index) => _DepartmentSectionContent(
            category: sections[index].category,
            title: sections[index].title,
            departments: sections[index].departments,
            permissionsAsync: permissionsAsync,
          ),
        );
      },
    );
  }
}

class _DepartmentSection {
  const _DepartmentSection({
    required this.category,
    required this.title,
    required this.departments,
  });

  final DepartmentCategory category;
  final String title;
  final List<DepartmentEntity> departments;
}

class _DepartmentSectionContent extends StatelessWidget {
  const _DepartmentSectionContent({
    required this.category,
    required this.title,
    required this.departments,
    required this.permissionsAsync,
  });

  final DepartmentCategory category;
  final String title;
  final List<DepartmentEntity> departments;
  final AsyncValue<SessionPermissions> permissionsAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.pushNamed(
            AppRoutes.homeChurchDepartmentsCategoryName,
            pathParameters: {'category': departmentCategoryPathValue(category)},
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: departments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final department = departments[index];
            final canOpen = permissionsAsync.whenOrNull(
              data: (permissions) => permissions.canObserveDept(department.id),
            );

            return DepartmentCard(
              department: department,
              onTap: canOpen == true
                  ? () => context.pushNamed(
                      AppRoutes.homeChurchDepartmentDetailName,
                      pathParameters: {'id': department.id},
                    )
                  : null,
            );
          },
        ),
      ],
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
      subtitle:
          'Esta área ficará disponível quando o backend expuser esse feed.',
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

DateTime _initialEventsStart() {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}

DateTime _initialEventsEnd() {
  final now = DateTime.now();
  return DateTime(now.year, now.month + 2, 0, 23, 59, 59);
}
