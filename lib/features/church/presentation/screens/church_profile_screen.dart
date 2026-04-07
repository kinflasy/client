import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/domain/entities/church_department_entity.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_event_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/current_church_profile_entity.dart';
import 'package:client/features/church/domain/entities/public_church_unit_profile_entity.dart';
import 'package:client/features/church/presentation/screens/church_shared_widgets.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _ChurchProfileViewerMode { member, visitor }

class ChurchProfileScreen extends ConsumerWidget {
  const ChurchProfileScreen({super.key, this.unitId});

  final String? unitId;

  bool get _isVisitorMode => unitId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_isVisitorMode) {
      final profileAsync = ref.watch(publicChurchUnitProfileProvider(unitId!));
      return profileAsync.when(
        loading: () => const Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(child: Center(child: CircularProgressIndicator())),
        ),
        error: (error, _) => _ErrorChurchState(
          message: error is Failure
              ? error.message
              : 'Nao foi possivel carregar a igreja agora.',
          onRetry: () =>
              ref.invalidate(publicChurchUnitProfileProvider(unitId!)),
        ),
        data: (profile) => _VisitorProfileBody(profile: profile),
      );
    }

    final profileAsync = ref.watch(currentChurchProfileProvider);
    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stackTrace) {
        if (error is NotFoundFailure) {
          return const _EmptyChurchState();
        }
        return _ErrorChurchState(
          message: error is Failure
              ? error.message
              : 'Nao foi possivel carregar a igreja agora.',
          onRetry: () => ref.invalidate(currentChurchProfileProvider),
        );
      },
      data: (profile) => _MemberProfileBody(profile: profile),
    );
  }
}

class _MemberProfileBody extends StatelessWidget {
  const _MemberProfileBody({required this.profile});

  final CurrentChurchProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ChurchCoverHeader(
                  unit: profile.unit,
                  fallbackChurch: profile.church,
                  showSearchRow: true,
                ),
              ),
              SliverToBoxAdapter(
                child: _ChurchInfoCard(
                  unit: profile.unit,
                  fallbackChurch: profile.church,
                ),
              ),
              const SliverPersistentHeader(delegate: _ChurchTabBarDelegate()),
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
    );
  }
}

class _VisitorProfileBody extends StatelessWidget {
  const _VisitorProfileBody({required this.profile});

  final PublicChurchUnitProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ChurchCoverHeader(
                  unit: profile.unit,
                  fallbackChurch: profile.church,
                  showBackButton: true,
                ),
              ),
              SliverToBoxAdapter(
                child: _ChurchInfoCard(
                  unit: profile.unit,
                  fallbackChurch: profile.church,
                ),
              ),
              const SliverPersistentHeader(
                delegate: _ChurchTabBarDelegate(
                  mode: _ChurchProfileViewerMode.visitor,
                ),
              ),
              const SliverFillRemaining(
                hasScrollBody: true,
                child: SizedBox.expand(child: _VisitorEventsPlaceholderTab()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChurchCoverHeader extends StatelessWidget {
  const _ChurchCoverHeader({
    required this.unit,
    required this.fallbackChurch,
    this.showSearchRow = false,
    this.showBackButton = false,
  });

  final ChurchUnitEntity unit;
  final ChurchEntity fallbackChurch;
  final bool showSearchRow;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final coverUrl = unit.coverUrl ?? fallbackChurch.coverUrl;
    final logoUrl = unit.logoUrl ?? fallbackChurch.logoUrl;
    final displayName = _displayName(unit, fallbackChurch);

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
        if (showBackButton) const ChurchFloatingBackButton(),
        if (showSearchRow)
          Positioned(top: 10, left: 16, right: 16, child: ChurchSearchRow()),
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
                      churchInitials(displayName),
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
  const _ChurchInfoCard({required this.unit, required this.fallbackChurch});

  final ChurchUnitEntity unit;
  final ChurchEntity fallbackChurch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName(unit, fallbackChurch),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '@${_displaySlug(unit, fallbackChurch)}',
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
              pathParameters: {'id': unit.id},
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChurchTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _ChurchTabBarDelegate({this.mode = _ChurchProfileViewerMode.member});

  final _ChurchProfileViewerMode mode;

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
    final tabs = mode == _ChurchProfileViewerMode.member
        ? const [
            Tab(text: 'Eventos'),
            Tab(text: 'Ministerios'),
            Tab(text: 'Avisos'),
          ]
        : const [Tab(text: 'Eventos')];

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
  bool shouldRebuild(covariant _ChurchTabBarDelegate oldDelegate) {
    return oldDelegate.mode != mode;
  }
}

class _VisitorEventsPlaceholderTab extends StatelessWidget {
  const _VisitorEventsPlaceholderTab();

  @override
  Widget build(BuildContext context) {
    return const _InlineStatus(
      icon: Icons.event_note_outlined,
      title: 'Eventos publicos em breve.',
      subtitle:
          'Esta area ficara disponivel quando trabalharmos o contrato de eventos publicos.',
    );
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
        title: 'Nao foi possivel carregar os eventos.',
      ),
      data: (events) {
        if (events.isEmpty) {
          return const _InlineStatus(
            icon: Icons.event_note_outlined,
            title: 'Nenhum evento encontrado.',
            subtitle: 'Os proximos eventos da sua igreja aparecerao aqui.',
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
        title: 'Nao foi possivel carregar os ministerios.',
      ),
      data: (departments) {
        if (departments.isEmpty) {
          return const _InlineStatus(
            icon: Icons.groups_outlined,
            title: 'Nenhum ministerio encontrado.',
            subtitle:
                'Quando houver departamentos ativos, eles aparecerao aqui.',
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
      subtitle:
          'Esta area ficara disponivel quando o backend expuser esse feed.',
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
              : department.type ?? 'Ministerio',
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
                  'Voce ainda nao participa de nenhuma igreja no app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Voce pode procurar uma igreja existente ou cadastrar uma nova se nao encontrar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () =>
                      context.pushNamed(AppRoutes.churchSearchName),
                  child: const Text('Buscar Igreja'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () =>
                      context.pushNamed(AppRoutes.registerChurchName),
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
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
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

String _displayName(ChurchUnitEntity unit, ChurchEntity fallbackChurch) {
  final name = unit.name?.trim();
  if (name != null && name.isNotEmpty) return name;
  return fallbackChurch.name;
}

String _displaySlug(ChurchUnitEntity unit, ChurchEntity fallbackChurch) {
  final slug = unit.slug?.trim();
  if (slug != null && slug.isNotEmpty) return slug;
  return fallbackChurch.slug;
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
