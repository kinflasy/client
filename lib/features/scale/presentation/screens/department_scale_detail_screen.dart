import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/presentation/widgets/user_avatar.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/scale/domain/entities/department_scale_detail_entity.dart';
import 'package:client/features/scale/domain/entities/department_scale_with_lineup_entity.dart';
import 'package:client/features/scale/domain/entities/editable_scale_assignment_entity.dart';
import 'package:client/features/scale/domain/entities/editable_scale_assignment_snapshot.dart';
import 'package:client/features/scale/domain/entities/scale_role_assignments_entity.dart';
import 'package:client/features/scale/providers/calendar_event_scale_providers.dart';
import 'package:client/features/scale/presentation/widgets/scale_assignment_picker_bottom_sheet.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DepartmentScaleDetailScreen extends ConsumerStatefulWidget {
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
  ConsumerState<DepartmentScaleDetailScreen> createState() =>
      _DepartmentScaleDetailScreenState();
}

class _DepartmentScaleDetailScreenState
    extends ConsumerState<DepartmentScaleDetailScreen> {
  EditableScaleAssignmentSnapshot _assignmentSnapshot =
      EditableScaleAssignmentSnapshot.empty;
  String? _assignmentSnapshotSourceKey;

  bool get _hasPendingChanges => _assignmentSnapshot.hasPendingChanges;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      departmentScaleAssignmentDetailProvider(
        DepartmentScaleDetailRequest(
          departmentId: widget.departmentId,
          scaleId: widget.scaleId,
          initialScale: widget.initialScale,
        ),
      ),
    );
    final permissionsAsync = ref.watch(sessionPermissionsProvider);
    final saveState = ref.watch(saveScaleAssignmentsProvider);
    final isSavingAssignments = saveState.isLoading;
    final canManageScale = permissionsAsync.maybeWhen(
      data: (permissions) => permissions.canManageDept(widget.departmentId),
      orElse: () => false,
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
        data: (detail) {
          _syncEditableAssignments(detail);
          return _ScaleDetailContent(
            detail: detail,
            assignments: _assignmentSnapshot,
            canManageScale: canManageScale && !isSavingAssignments,
            onOpenVacancy: (role) =>
                _openAssignmentPicker(detail, initialRole: role),
            onRemoveAssignment: _removeAssignment,
          );
        },
      ),
      bottomNavigationBar: detailAsync.maybeWhen(
        data: (detail) => canManageScale
            ? _ScaleEditActionBar(
                canAddPeople: detail.roleAssignments.any(_hasEditableVacancy),
                hasPendingChanges: _hasPendingChanges,
                isSaving: isSavingAssignments,
                onAddPerson:
                    !detail.roleAssignments.any(_hasEditableVacancy) ||
                        isSavingAssignments
                    ? null
                    : () => _openAssignmentPicker(detail),
                onComplete: _hasPendingChanges && !isSavingAssignments
                    ? () => _saveAssignments(detail)
                    : null,
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  void _syncEditableAssignments(DepartmentScaleDetailEntity detail) {
    final sourceKey = _editableAssignmentsSourceKey(detail);
    if (_assignmentSnapshotSourceKey == sourceKey) return;
    if (_hasPendingChanges && detail.base.scale.scale.id == widget.scaleId) {
      return;
    }

    _assignmentSnapshot = EditableScaleAssignmentSnapshot.fromRoleAssignments(
      detail.roleAssignments,
    );
    _assignmentSnapshotSourceKey = sourceKey;
  }

  Future<void> _openAssignmentPicker(
    DepartmentScaleDetailEntity detail, {
    LineupItemEntity? initialRole,
  }) async {
    final selection = await showScaleAssignmentPickerBottomSheet(
      context: context,
      departmentId: widget.departmentId,
      roles: detail.roleAssignments
          .where(_hasEditableVacancy)
          .map((assignment) => assignment.item)
          .toList(),
      initialRole: initialRole,
    );
    if (selection == null || !mounted) return;

    setState(() {
      _assignmentSnapshot = _assignmentSnapshot.addPerson(
        localId: 'local:${DateTime.now().microsecondsSinceEpoch}',
        roleId: selection.role.roleId,
        personId: selection.participant.personId,
        displayName: selection.participant.displayName,
        profileImageId: selection.participant.profileImageId,
      );
    });
  }

  Future<void> _saveAssignments(DepartmentScaleDetailEntity detail) async {
    final result = await ref
        .read(saveScaleAssignmentsProvider.notifier)
        .save(
          departmentId: widget.departmentId,
          scaleId: widget.scaleId,
          originalAssignments: _assignmentSnapshot.original,
          currentAssignments: _assignmentSnapshot.current,
        );

    if (!mounted) return;

    result.fold(
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível atualizar a escala.')),
        );
      },
      (_) {
        setState(() {
          _assignmentSnapshot = EditableScaleAssignmentSnapshot(
            original: _assignmentSnapshot.current,
            current: _assignmentSnapshot.current,
          );
          _assignmentSnapshotSourceKey = _editableAssignmentsSourceKey(detail);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Escala atualizada')));
      },
    );
  }

  void _removeAssignment(String localId) {
    setState(() {
      _assignmentSnapshot = _assignmentSnapshot.removeByLocalId(localId);
    });
  }

  bool _hasEditableVacancy(ScaleRoleAssignmentsEntity assignment) {
    final assignedCount = _assignmentSnapshot
        .assignmentsForRole(assignment.item.roleId)
        .length;
    return assignedCount < assignment.capacity;
  }
}

class _ScaleDetailContent extends StatelessWidget {
  const _ScaleDetailContent({
    required this.detail,
    required this.assignments,
    required this.canManageScale,
    required this.onOpenVacancy,
    required this.onRemoveAssignment,
  });

  final DepartmentScaleDetailEntity detail;
  final EditableScaleAssignmentSnapshot assignments;
  final bool canManageScale;
  final ValueChanged<LineupItemEntity> onOpenVacancy;
  final ValueChanged<String> onRemoveAssignment;

  @override
  Widget build(BuildContext context) {
    final event = detail.base.scale.calendarEvent;
    final lineup = detail.base.lineup;

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
        if (detail.peopleLoadFailureMessage != null) ...[
          _InlineMessage(text: detail.peopleLoadFailureMessage!),
          const SizedBox(height: 12),
        ],
        _LineupItemsSection(
          detail: detail,
          assignments: assignments,
          canManageScale: canManageScale,
          onOpenVacancy: onOpenVacancy,
          onRemoveAssignment: onRemoveAssignment,
        ),
      ],
    );
  }
}

class _LineupItemsSection extends StatelessWidget {
  const _LineupItemsSection({
    required this.detail,
    required this.assignments,
    required this.canManageScale,
    required this.onOpenVacancy,
    required this.onRemoveAssignment,
  });

  final DepartmentScaleDetailEntity detail;
  final EditableScaleAssignmentSnapshot assignments;
  final bool canManageScale;
  final ValueChanged<LineupItemEntity> onOpenVacancy;
  final ValueChanged<String> onRemoveAssignment;

  @override
  Widget build(BuildContext context) {
    if (detail.base.hasLineupFailure) {
      return const _InlineMessage(
        text: 'Não foi possível carregar as funções da formação.',
      );
    }

    final assignments = detail.roleAssignments;
    if (assignments.isEmpty) {
      return const _InlineMessage(text: 'Nenhuma função definida');
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inactiveBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var index = 0; index < assignments.length; index++) ...[
            _LineupItemTile(
              assignment: assignments[index],
              editableAssignments: this.assignments.assignmentsForRole(
                assignments[index].item.roleId,
              ),
              canManageScale: canManageScale,
              onOpenVacancy: onOpenVacancy,
              onRemoveAssignment: onRemoveAssignment,
            ),
            if (index < assignments.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _LineupItemTile extends StatelessWidget {
  const _LineupItemTile({
    required this.assignment,
    required this.editableAssignments,
    required this.canManageScale,
    required this.onOpenVacancy,
    required this.onRemoveAssignment,
  });

  final ScaleRoleAssignmentsEntity assignment;
  final List<EditableScaleAssignmentEntity> editableAssignments;
  final bool canManageScale;
  final ValueChanged<LineupItemEntity> onOpenVacancy;
  final ValueChanged<String> onRemoveAssignment;

  @override
  Widget build(BuildContext context) {
    final item = assignment.item;
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
          const SizedBox(height: 12),
          if (editableAssignments.isEmpty)
            _OpenVacancyRow(
              onTap: canManageScale ? () => onOpenVacancy(item) : null,
              vacancyCount: assignment.openVacancyCount,
            )
          else ...[
            for (
              var index = 0;
              index < editableAssignments.length;
              index++
            ) ...[
              _AssignedPersonRow(
                assignment: editableAssignments[index],
                onRemove: canManageScale
                    ? () =>
                          onRemoveAssignment(editableAssignments[index].localId)
                    : null,
              ),
              if (index < editableAssignments.length - 1)
                const Divider(height: 20),
            ],
            if (assignment.capacity > editableAssignments.length) ...[
              const Divider(height: 20),
              _OpenVacancyRow(
                onTap: canManageScale ? () => onOpenVacancy(item) : null,
                vacancyCount: assignment.capacity - editableAssignments.length,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AssignedPersonRow extends StatelessWidget {
  const _AssignedPersonRow({required this.assignment, required this.onRemove});

  final EditableScaleAssignmentEntity assignment;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        UserAvatar(
          displayName: assignment.displayName,
          radius: 18,
          profileImageId: assignment.profileImageId,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            assignment.displayName,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          ),
        ),
        if (onRemove != null)
          IconButton(
            tooltip: 'Remover ${assignment.displayName}',
            onPressed: onRemove,
            icon: const Icon(Icons.close),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _OpenVacancyRow extends StatelessWidget {
  const _OpenVacancyRow({required this.onTap, required this.vacancyCount});

  final VoidCallback? onTap;
  final int vacancyCount;

  @override
  Widget build(BuildContext context) {
    final label = vacancyCount <= 1
        ? 'Vaga aberta'
        : '$vacancyCount vagas abertas';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.transparent,
            child: Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScaleEditActionBar extends StatelessWidget {
  const _ScaleEditActionBar({
    required this.canAddPeople,
    required this.hasPendingChanges,
    required this.isSaving,
    required this.onAddPerson,
    required this.onComplete,
  });

  final bool canAddPeople;
  final bool hasPendingChanges;
  final bool isSaving;
  final VoidCallback? onAddPerson;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: canAddPeople ? onAddPerson : null,
                child: const Text('Adicionar pessoa'),
              ),
            ),
            if (hasPendingChanges) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onComplete,
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Concluir'),
                ),
              ),
            ],
          ],
        ),
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

String _appBarTitle(AsyncValue<DepartmentScaleDetailEntity> detailAsync) {
  return detailAsync.when(
    loading: () => 'Carregando...',
    error: (_, _) => 'Escala',
    data: (detail) => detail.base.scale.calendarEvent.title,
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

String _editableAssignmentsSourceKey(DepartmentScaleDetailEntity detail) {
  final assignmentKeys = <String>[];
  for (final roleAssignment in detail.roleAssignments) {
    for (final person in roleAssignment.people) {
      assignmentKeys.add(
        [
          roleAssignment.item.roleId,
          person.scaleItemId ?? '',
          person.personId,
          person.displayName,
          person.profileImageId ?? '',
        ].join('|'),
      );
    }
  }
  return '${detail.base.scale.scale.id}:${assignmentKeys.join(';')}';
}

String _errorMessage(Object error) {
  if (error is Failure && error.message.trim().isNotEmpty) {
    return error.message;
  }
  return 'Tente novamente em instantes.';
}
