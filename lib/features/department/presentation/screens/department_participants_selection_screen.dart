import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/presentation/widgets/action_confirmation_dialog.dart';
import 'package:client/core/presentation/widgets/user_avatar.dart';
import 'package:client/core/utils/string_utils.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/department/providers/department_detail_providers.dart';
import 'package:client/features/membership/domain/entities/unit_member_entity.dart';
import 'package:client/features/membership/providers/unit_member_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _borderColor = Color(0xFFE0E0E0);

class DepartmentParticipantsSelectionScreen extends ConsumerStatefulWidget {
  const DepartmentParticipantsSelectionScreen({
    super.key,
    required this.departmentId,
  });

  final String departmentId;

  @override
  ConsumerState<DepartmentParticipantsSelectionScreen> createState() =>
      _DepartmentParticipantsSelectionScreenState();
}

class _DepartmentParticipantsSelectionScreenState
    extends ConsumerState<DepartmentParticipantsSelectionScreen> {
  final _searchController = TextEditingController();
  final _selectedByMembershipId = <String, UnitMemberEntity>{};
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeMembershipAsync = ref.watch(activeMembershipProvider);
    final addParticipantsState = ref.watch(addDepartmentParticipantsProvider);
    final isSubmitting = addParticipantsState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _SelectionActionBar(
        selectedCount: _selectedByMembershipId.length,
        isSubmitting: isSubmitting,
        onConfirm: _selectedByMembershipId.isEmpty || isSubmitting
            ? null
            : _confirmAndSubmit,
      ),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Pesquisar nome ou apelido...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
      body: activeMembershipAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _SelectionStatus(
          icon: Icons.group_off_outlined,
          title: 'Não foi possível carregar a unidade ativa.',
        ),
        data: (membership) {
          if (membership == null) {
            return const _SelectionStatus(
              icon: Icons.groups_outlined,
              title: 'Nenhuma unidade ativa encontrada.',
            );
          }

          final membersAsync = ref.watch(
            rawUnitMembersProvider(membership.unitId),
          );
          final participantsAsync = ref.watch(
            departmentParticipantsProvider(widget.departmentId),
          );

          if (membersAsync.isLoading || participantsAsync.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (membersAsync.hasError) {
            return const _SelectionStatus(
              icon: Icons.group_off_outlined,
              title: 'Não foi possível carregar os membros da unidade.',
            );
          }

          if (participantsAsync.hasError) {
            return const _SelectionStatus(
              icon: Icons.group_off_outlined,
              title: 'Não foi possível carregar os participantes atuais.',
            );
          }

          final members =
              membersAsync.asData?.value ?? const <UnitMemberEntity>[];
          final participants = participantsAsync.asData?.value ?? const [];
          final participantPersonIds = participants
              .map((participant) => participant.personId)
              .toSet();
          final eligibleMembers = members
              .where(
                (member) => !participantPersonIds.contains(member.personId),
              )
              .toList();
          final filteredMembers = _filterMembers(eligibleMembers);
          final selectedMembers = _selectedByMembershipId.values.toList()
            ..sort((a, b) => a.fullName.compareTo(b.fullName));

          return Column(
            children: [
              if (selectedMembers.isNotEmpty)
                _SelectedMembersStrip(
                  members: selectedMembers,
                  onRemove: _toggleSelection,
                ),
              Expanded(
                child: filteredMembers.isEmpty
                    ? const _SelectionStatus(
                        icon: Icons.person_search_outlined,
                        title: 'Nenhuma pessoa disponível para adicionar.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filteredMembers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final member = filteredMembers[index];
                          final isSelected = _selectedByMembershipId
                              .containsKey(member.membershipId);

                          return _SelectableMemberTile(
                            member: member,
                            isSelected: isSelected,
                            onToggle: () => _toggleSelection(member),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<UnitMemberEntity> _filterMembers(List<UnitMemberEntity> members) {
    final normalizedQuery = normalizeSearchTerm(_query);
    final filtered = members.where((member) {
      if (normalizedQuery.isEmpty) return true;

      final name = normalizeSearchTerm(member.fullName);
      final nickname = normalizeSearchTerm(member.nickname ?? '');
      return name.contains(normalizedQuery) ||
          nickname.contains(normalizedQuery);
    }).toList()..sort((a, b) => a.fullName.compareTo(b.fullName));

    return filtered;
  }

  void _toggleSelection(UnitMemberEntity member) {
    setState(() {
      if (_selectedByMembershipId.containsKey(member.membershipId)) {
        _selectedByMembershipId.remove(member.membershipId);
      } else {
        _selectedByMembershipId[member.membershipId] = member;
      }
    });
  }

  Future<void> _confirmAndSubmit() async {
    final selectedMembers = _selectedByMembershipId.values.toList();
    final confirmed = await showActionConfirmationDialog(
      context,
      title: 'Adicionar participantes',
      message:
          'Deseja adicionar ${_participantsLabel(selectedMembers.length)} ao departamento?',
      confirmLabel: 'Adicionar',
    );

    if (!confirmed) return;
    if (!mounted) return;

    final selectedMembershipIds = selectedMembers
        .map((member) => member.membershipId)
        .toList();
    final result = await ref
        .read(addDepartmentParticipantsProvider.notifier)
        .addParticipants(
          departmentId: widget.departmentId,
          membershipIds: selectedMembershipIds,
        );

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (result.hasSuccess && !result.hasFailures) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Participantes adicionados com sucesso.')),
      );
      Navigator.of(context).maybePop();
      return;
    }

    if (result.hasSuccess && result.hasFailures) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${_participantsLabel(result.successCount)} adicionados. '
            '${_participantsLabel(result.failureCount)} não puderam ser adicionados.',
          ),
        ),
      );
      Navigator.of(context).maybePop();
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Não foi possível adicionar os participantes selecionados.',
        ),
      ),
    );
  }
}

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.selectedCount,
    required this.isSubmitting,
    required this.onConfirm,
  });

  final int selectedCount;
  final bool isSubmitting;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onConfirm,
            icon: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward),
            label: Text(
              isSubmitting ? 'Adicionando...' : 'Adicionar $selectedCount',
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedMembersStrip extends StatelessWidget {
  const _SelectedMembersStrip({required this.members, required this.onRemove});

  final List<UnitMemberEntity> members;
  final ValueChanged<UnitMemberEntity> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final member = members[index];
          return _SelectedMemberChip(
            member: member,
            onRemove: () => onRemove(member),
          );
        },
      ),
    );
  }
}

class _SelectedMemberChip extends StatelessWidget {
  const _SelectedMemberChip({required this.member, required this.onRemove});

  final UnitMemberEntity member;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(
                displayName: member.fullName,
                radius: 22,
                profileImageId: member.profileImageId,
              ),
              Positioned(
                right: -8,
                bottom: -8,
                child: IconButton.filled(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: 'Remover ${member.fullName}',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            member.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableMemberTile extends StatelessWidget {
  const _SelectableMemberTile({
    required this.member,
    required this.isSelected,
    required this.onToggle,
  });

  final UnitMemberEntity member;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        onTap: onToggle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _borderColor),
        ),
        leading: UserAvatar(
          displayName: member.fullName,
          radius: 20,
          profileImageId: member.profileImageId,
        ),
        title: Text(
          member.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: member.nickname == null || member.nickname!.trim().isEmpty
            ? null
            : Text(
                member.nickname!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: Icon(
          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SelectionStatus extends StatelessWidget {
  const _SelectionStatus({required this.icon, required this.title});

  final IconData icon;
  final String title;

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
          ],
        ),
      ),
    );
  }
}

String _participantsLabel(int count) {
  return count == 1 ? '1 participante' : '$count participantes';
}
