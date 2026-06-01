import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/presentation/widgets/app_tab_bar.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/calendar/presentation/widgets/event_card.dart';
import 'package:client/features/calendar/presentation/widgets/event_detail_bottom_sheet.dart';
import 'package:client/features/calendar/providers/calendar_event_providers.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/presentation/widgets/department_participant_bottom_sheet.dart';
import 'package:client/features/department/providers/department_detail_providers.dart';
import 'package:client/features/membership/presentation/widgets/member_summary_card.dart';
import 'package:client/features/scale/presentation/widgets/department_scale_card.dart';
import 'package:client/features/scale/providers/calendar_event_scale_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DepartmentScreen extends ConsumerStatefulWidget {
  const DepartmentScreen({
    super.key,
    required this.departmentId,
    required this.showBackButton,
  });

  final String departmentId;
  final bool showBackButton;

  @override
  ConsumerState<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends ConsumerState<DepartmentScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedTabIndex = 0;

  static const _tabs = ['Eventos', 'Escalas', 'Participantes'];

  @override
  Widget build(BuildContext context) {
    final departmentAsync = ref.watch(
      departmentDetailProvider(widget.departmentId),
    );
    final permissionsAsync = ref.watch(sessionPermissionsProvider);
    final accessDenied = permissionsAsync.whenOrNull(
      data: (permissions) => !permissions.canObserveDept(widget.departmentId),
    );
    final canManageParticipants =
        permissionsAsync.whenOrNull(
          data: (permissions) => permissions.canManageDept(widget.departmentId),
        ) ??
        false;
    final canManageEvents =
        permissionsAsync.whenOrNull(
          data: (permissions) => permissions.canManageDept(widget.departmentId),
        ) ??
        false;
    final canObserveDepartment =
        permissionsAsync.whenOrNull(
          data: (permissions) =>
              permissions.canObserveDept(widget.departmentId),
        ) ??
        false;
    final showCreateEventButton = _selectedTabIndex == 0 && canManageEvents;
    final showAddParticipantsButton =
        _selectedTabIndex == 2 && canManageParticipants;
    final headerBottomHeight =
        showCreateEventButton || showAddParticipantsButton ? 140.0 : 76.0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: canObserveDepartment
          ? _DepartmentSettingsSidebar(
              departmentId: widget.departmentId,
              departmentName: _buildTitle(departmentAsync),
            )
          : null,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            automaticallyImplyLeading: widget.showBackButton,
            title: Text(_buildTitle(departmentAsync)),
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            floating: true,
            snap: true,
            actions: [
              if (canObserveDepartment)
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Configurações do departamento',
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                ),
            ],
            bottom: accessDenied == true
                ? null
                : PreferredSize(
                    preferredSize: Size.fromHeight(headerBottomHeight),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTabBar(
                            tabs: _tabs,
                            selectedIndex: _selectedTabIndex,
                            onTabChanged: (index) {
                              setState(() {
                                _selectedTabIndex = index;
                              });
                            },
                          ),
                          if (showCreateEventButton) ...[
                            const SizedBox(height: 16),
                            _CreateDepartmentEventButton(
                              departmentId: widget.departmentId,
                            ),
                          ],
                          if (showAddParticipantsButton) ...[
                            const SizedBox(height: 16),
                            _AddParticipantsButton(
                              departmentId: widget.departmentId,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
        body: accessDenied == true
            ? const _InlineStatus(
                icon: Icons.lock_outline,
                title: 'Você não tem permissão para abrir este departamento.',
                subtitle:
                    'Se precisar de acesso, fale com a liderança da unidade.',
              )
            : departmentAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => const _InlineStatus(
                  icon: Icons.groups_2_outlined,
                  title: 'Não foi possível carregar o departamento.',
                  subtitle: 'Tente novamente em instantes.',
                ),
                data: (department) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: IndexedStack(
                    index: _selectedTabIndex,
                    children: [
                      _DepartmentEventsTab(
                        departmentId: widget.departmentId,
                        departmentName: department.name,
                        canManageEvents: canManageEvents,
                      ),
                      _DepartmentScalesTab(
                        departmentId: widget.departmentId,
                        canManageScales: canManageEvents,
                        isActive: _selectedTabIndex == 1,
                      ),
                      _DepartmentParticipantsTab(
                        departmentId: widget.departmentId,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String _buildTitle(AsyncValue<DepartmentDetailEntity> departmentAsync) {
    return departmentAsync.when(
      loading: () => 'Carregando...',
      error: (_, _) => 'Departamento',
      data: (department) => department.name,
    );
  }
}

class _DepartmentSettingsSidebar extends StatelessWidget {
  const _DepartmentSettingsSidebar({
    required this.departmentId,
    required this.departmentName,
  });

  final String departmentId;
  final String departmentName;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configurações',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    departmentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.assignment_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Formações de escala',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                context.pushNamed(
                  AppRoutes.departmentScaleFormationsName,
                  pathParameters: {'id': departmentId},
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DepartmentEventsTab extends ConsumerWidget {
  const _DepartmentEventsTab({
    required this.departmentId,
    required this.departmentName,
    required this.canManageEvents,
  });

  final String departmentId;
  final String departmentName;
  final bool canManageEvents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentChurchProfileProvider);
    final eventsAsync = ref.watch(
      departmentCalendarEventsProvider(
        DepartmentCalendarEventsRequest(
          departmentId: departmentId,
          start: _initialEventsStart(),
          end: _initialEventsEnd(),
        ),
      ),
    );
    final unitName =
        profileAsync.whenOrNull(data: (profile) => profile.unit.name?.trim()) ??
        'Unidade';
    final unitAvatarImageId = profileAsync.whenOrNull(
      data: (profile) => profile.unit.profileImageId,
    );
    final unitAvatarImageUrl = profileAsync.whenOrNull(
      data: (profile) => profile.unit.logoUrl ?? profile.church.logoUrl,
    );
    final organizerLabel = '$unitName - $departmentName';

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const _InlineStatus(
        icon: Icons.event_busy_outlined,
        title: 'Não foi possível carregar os eventos.',
        subtitle: 'Tente novamente em instantes.',
      ),
      data: (events) {
        if (events.isEmpty && canManageEvents) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                child: _InlineStatus(
                  icon: Icons.event_note_outlined,
                  title: 'Nenhum evento encontrado.',
                  subtitle:
                      'Quando houver eventos deste departamento, eles aparecerão aqui.',
                ),
              ),
            ],
          );
        }

        if (events.isEmpty) {
          return const _InlineStatus(
            icon: Icons.event_note_outlined,
            title: 'Nenhum evento encontrado.',
            subtitle:
                'Quando houver eventos deste departamento, eles aparecerão aqui.',
          );
        }

        if (canManageEvents) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: events.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return EventCard(
                      event: event,
                      organizerLabel: organizerLabel,
                      unitAvatarDisplayName: unitName,
                      unitAvatarImageId: unitAvatarImageId,
                      unitAvatarImageUrl: unitAvatarImageUrl,
                      onEdit: () => context.pushNamed(
                        AppRoutes.adminCalendarEditName,
                        pathParameters: {'id': event.id},
                      ),
                      onDuplicate: () => context.pushNamed(
                        AppRoutes.adminCalendarDuplicateName,
                        pathParameters: {'id': event.id},
                      ),
                      onDelete: () =>
                          confirmAndDeleteCalendarEvent(context, ref, event),
                      onTap: () => showEventDetailBottomSheet(
                        context,
                        eventId: event.id,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: events.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final event = events[index];
            return EventCard(
              event: event,
              organizerLabel: organizerLabel,
              unitAvatarDisplayName: unitName,
              unitAvatarImageId: unitAvatarImageId,
              unitAvatarImageUrl: unitAvatarImageUrl,
              onEdit: canManageEvents
                  ? () => context.pushNamed(
                      AppRoutes.adminCalendarEditName,
                      pathParameters: {'id': event.id},
                    )
                  : null,
              onDuplicate: canManageEvents
                  ? () => context.pushNamed(
                      AppRoutes.adminCalendarDuplicateName,
                      pathParameters: {'id': event.id},
                    )
                  : null,
              onDelete: canManageEvents
                  ? () => confirmAndDeleteCalendarEvent(context, ref, event)
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

class _CreateDepartmentEventButton extends StatelessWidget {
  const _CreateDepartmentEventButton({required this.departmentId});

  final String departmentId;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => context.pushNamed(
        AppRoutes.departmentEventCreateName,
        pathParameters: {'id': departmentId},
      ),
      icon: const Icon(Icons.add),
      label: const Text('Criar evento'),
    );
  }
}

class _DepartmentScalesTab extends ConsumerStatefulWidget {
  const _DepartmentScalesTab({
    required this.departmentId,
    required this.canManageScales,
    required this.isActive,
  });

  final String departmentId;
  final bool canManageScales;
  final bool isActive;

  @override
  ConsumerState<_DepartmentScalesTab> createState() =>
      _DepartmentScalesTabState();
}

class _DepartmentScalesTabState extends ConsumerState<_DepartmentScalesTab> {
  late final DepartmentScalesRequest _scalesRequest;

  @override
  void initState() {
    super.initState();
    _scalesRequest = buildDepartmentScalesRequest(widget.departmentId);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    final scalesAsync = ref.watch(
      departmentScalesWithLineupsProvider(_scalesRequest),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.canManageScales) ...[
          ElevatedButton.icon(
            onPressed: () => context.pushNamed(
              AppRoutes.departmentScaleCreateName,
              pathParameters: {'id': widget.departmentId},
            ),
            icon: const Icon(Icons.add),
            label: const Text('Nova escala'),
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: scalesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const _InlineStatus(
              icon: Icons.assignment_late_outlined,
              title: 'Não foi possível carregar as escalas.',
              subtitle: 'Tente novamente em instantes.',
            ),
            data: (scales) {
              if (scales.isEmpty) {
                return const _InlineStatus(
                  icon: Icons.assignment_outlined,
                  title: 'Nenhuma escala cadastrada ainda.',
                  subtitle:
                      'Crie uma escala vinculando um evento a uma formação.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: scales.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return DepartmentScaleCard(
                    scale: scales[index],
                    onTap: () {},
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DepartmentParticipantsTab extends ConsumerWidget {
  const _DepartmentParticipantsTab({required this.departmentId});

  final String departmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(
      departmentParticipantsProvider(departmentId),
    );

    return participantsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const _InlineStatus(
        icon: Icons.group_off_outlined,
        title: 'Não foi possível carregar os participantes.',
        subtitle: 'Tente novamente em instantes.',
      ),
      data: (participants) {
        if (participants.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                child: _InlineStatus(
                  icon: Icons.groups_outlined,
                  title: 'Nenhum participante encontrado.',
                  subtitle:
                      'Quando houver pessoas vinculadas a este departamento, elas aparecerão aqui.',
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: participants.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final participant = participants[index];
                  return MemberSummaryCard(
                    fullName: participant.displayName,
                    affiliation: participant.affiliation,
                    gender: participant.gender,
                    birthDate: participant.birthDate,
                    age: participant.age,
                    profileImageId: participant.profileImageId,
                    onTap: () => showDepartmentParticipantBottomSheet(
                      context,
                      departmentId: departmentId,
                      participant: participant,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AddParticipantsButton extends StatelessWidget {
  const _AddParticipantsButton({required this.departmentId});

  final String departmentId;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => context.pushNamed(
        AppRoutes.departmentParticipantsAddName,
        pathParameters: {'id': departmentId},
      ),
      icon: const Icon(Icons.person_add_alt_1),
      label: const Text('Adicionar participantes'),
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
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
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

DateTime _initialEventsStart() {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}

DateTime _initialEventsEnd() {
  final now = DateTime.now();
  return DateTime(now.year, now.month + 2, 0, 23, 59, 59);
}
