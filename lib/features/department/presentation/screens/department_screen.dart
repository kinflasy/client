import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/presentation/widgets/app_tab_bar.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/providers/department_detail_providers.dart';
import 'package:client/features/membership/presentation/widgets/member_summary_card.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  int _selectedTabIndex = 0;

  static const _tabs = ['Eventos', 'Participantes'];

  @override
  Widget build(BuildContext context) {
    final departmentAsync = ref.watch(
      departmentDetailProvider(widget.departmentId),
    );
    final permissionsAsync = ref.watch(sessionPermissionsProvider);
    final accessDenied = permissionsAsync.whenOrNull(
      data: (permissions) => !permissions.canObserveDept(widget.departmentId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        title: Text(_buildTitle(departmentAsync)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: accessDenied == true
          ? const _InlineStatus(
              icon: Icons.lock_outline,
              title: 'Voce nao tem permissao para abrir este departamento.',
              subtitle:
                  'Se precisar de acesso, fale com a lideranca da unidade.',
            )
          : departmentAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => const _InlineStatus(
                icon: Icons.groups_2_outlined,
                title: 'Nao foi possivel carregar o departamento.',
                subtitle: 'Tente novamente em instantes.',
              ),
              data: (_) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 16),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedTabIndex,
                        children: [
                          const _DepartmentEventsPlaceholder(),
                          _DepartmentParticipantsTab(
                            departmentId: widget.departmentId,
                          ),
                        ],
                      ),
                    ),
                  ],
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

class _DepartmentEventsPlaceholder extends StatelessWidget {
  const _DepartmentEventsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _InlineStatus(
      icon: Icons.event_note_outlined,
      title: 'Eventos do departamento em breve.',
      subtitle:
          'Nesta primeira versao, esta aba vai comecar com conteudo mockado.',
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
        title: 'Nao foi possivel carregar os participantes.',
        subtitle: 'Tente novamente em instantes.',
      ),
      data: (participants) {
        if (participants.isEmpty) {
          return const _InlineStatus(
            icon: Icons.groups_outlined,
            title: 'Nenhum participante encontrado.',
            subtitle:
                'Quando houver pessoas vinculadas a este departamento, elas aparecerao aqui.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: participants.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final participant = participants[index];
            return MemberSummaryCard(
              fullName: participant.fullName,
              affiliation: participant.affiliation,
              gender: participant.gender,
              birthDate: participant.birthDate,
              age: participant.age,
            );
          },
        );
      },
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
