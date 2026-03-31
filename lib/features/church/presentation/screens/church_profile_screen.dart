import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/domain/entities/church_department_entity.dart';
import 'package:client/features/church/domain/entities/church_event_entity.dart';
import 'package:client/features/church/domain/entities/current_church_profile_entity.dart';
import 'package:client/features/church/presentation/screens/church_shared_widgets.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChurchProfileScreen extends ConsumerWidget {
  const ChurchProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentChurchProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stackTrace) {
        if (error is NotFoundFailure) {
          return const _EmptyChurchState();
        }
        return _ErrorChurchState(
          message: error is Failure
              ? error.message
              : 'Não foi possível carregar a igreja agora.',
          onRetry: () => ref.invalidate(currentChurchProfileProvider),
        );
      },
      data: (profile) => DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _ChurchCoverHeader(profile: profile)),
                SliverToBoxAdapter(child: _ChurchInfoCard(profile: profile)),
                SliverPersistentHeader(delegate: const _ChurchTabBarDelegate()),
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: SizedBox.expand(
                    child: TabBarView(
                      children: [
                        _EventsTab(unitId: profile.unit.id),
                        _DepartmentsTab(unitId: profile.unit.id),
                        const _AnnouncementsTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChurchCoverHeader extends StatelessWidget {
  const _ChurchCoverHeader({required this.profile});

  final CurrentChurchProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final coverUrl = profile.church.coverUrl;
    final logoUrl = profile.church.logoUrl;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 168,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F4C81), AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: coverUrl == null
              ? const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x22000000), Color(0x00000000)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                )
              : Image.network(
                  coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
        ),
        Positioned(
          top: 10,
          left: 16,
          right: 16,
          child: ChurchSearchRow(),
        ),
        Positioned(
          bottom: -58,
          child: CircleAvatar(
            radius: 64,
            backgroundColor: AppColors.surface,
            child: CircleAvatar(
              radius: 58,
              backgroundColor: const Color(0xFFE8F0FE),
              backgroundImage: logoUrl != null ? NetworkImage(logoUrl) : null,
              child: logoUrl == null
                  ? Text(
                      churchInitials(profile.church.name),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChurchInfoCard extends StatelessWidget {
  const _ChurchInfoCard({required this.profile});

  final CurrentChurchProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.church.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '@${profile.church.slug}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => context.pushNamed(
                  AppRoutes.churchPublicProfileName,
                  pathParameters: {'id': profile.church.id},
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              alignment: WrapAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.location_city_outlined,
                  label: profile.unit.name ?? 'Sede principal',
                ),
                if ((profile.church.phone ?? '').isNotEmpty)
                  _InfoChip(
                    icon: Icons.call_outlined,
                    label: profile.church.phone!,
                  ),
                _InfoChip(
                  icon: Icons.mail_outline,
                  label: profile.church.email,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChurchTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _ChurchTabBarDelegate();

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
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      child: const TabBar(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: [
          Tab(text: 'Eventos'),
          Tab(text: 'Ministérios'),
          Tab(text: 'Avisos'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class _EventsTab extends ConsumerWidget {
  const _EventsTab({required this.unitId});

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

class _DepartmentsTab extends ConsumerWidget {
  const _DepartmentsTab({required this.unitId});

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
            subtitle: 'Quando houver departamentos ativos, eles aparecerão aqui.',
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

class _AnnouncementsTab extends StatelessWidget {
  const _AnnouncementsTab();

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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({
    required this.icon,
    required this.title,
    this.subtitle,
  });

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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
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

class _EmptyChurchState extends StatelessWidget {
  const _EmptyChurchState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.church_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Você ainda não participa de nenhuma igreja no app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Você pode procurar uma igreja existente ou cadastrar uma nova se não encontrar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Busca de igrejas em breve.'),
                      ),
                    );
                  },
                  child: const Text('Buscar Igreja'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => context.pushNamed(AppRoutes.registerChurchName),
                  child: const Text('Cadastrar Igreja'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorChurchState extends StatelessWidget {
  const _ErrorChurchState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
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
