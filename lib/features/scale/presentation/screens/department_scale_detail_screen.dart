import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/presentation/widgets/action_confirmation_dialog.dart';
import 'package:client/core/presentation/widgets/user_avatar.dart';
import 'package:client/core/router/app_routes.dart';
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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final deleteScaleState = ref.watch(deleteDepartmentScaleProvider);
    final isSavingAssignments = saveState.isLoading;
    final isDeletingScale = deleteScaleState.isLoading;
    final canManageScale = permissionsAsync.maybeWhen(
      data: (permissions) => permissions.canManageDept(widget.departmentId),
      orElse: () => false,
    );
    final actionsEnabled =
        canManageScale && !isSavingAssignments && !isDeletingScale;

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle(detailAsync)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        actions: [
          if (canManageScale)
            _ScaleDetailActions(
              enabled: actionsEnabled,
              isDeleting: isDeletingScale,
              onDelete: _confirmAndDeleteScale,
            ),
        ],
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
            canManageScale: actionsEnabled,
            canAddPeople: detail.roleAssignments.any(_hasEditableVacancy),
            onAddPerson: isSavingAssignments
                ? null
                : () => _openAssignmentPicker(detail),
            onOpenVacancy: (role) =>
                _openAssignmentPicker(detail, initialRole: role),
            onRemoveAssignment: _removeAssignment,
          );
        },
      ),
      bottomNavigationBar: detailAsync.maybeWhen(
        data: (detail) => canManageScale && _hasPendingChanges
            ? _ScaleEditActionBar(
                isSaving: isSavingAssignments || isDeletingScale,
                onCancel: actionsEnabled ? _cancelAssignmentChanges : null,
                onComplete: actionsEnabled
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

  Future<void> _confirmAndDeleteScale() async {
    final confirmed = await showActionConfirmationDialog(
      context,
      title: 'Excluir escala',
      message: 'Tem certeza que deseja excluir esta escala?',
      confirmLabel: 'Excluir',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(deleteDepartmentScaleProvider.notifier)
        .delete(departmentId: widget.departmentId, scaleId: widget.scaleId);

    if (!mounted) return;

    result.fold(
      (failure) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_errorMessage(failure))));
      },
      (_) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Escala excluída.')));
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else {
          router.go(
            AppRoutes.departmentDetail.replaceFirst(':id', widget.departmentId),
          );
        }
      },
    );
  }

  void _removeAssignment(String localId) {
    setState(() {
      _assignmentSnapshot = _assignmentSnapshot.removeByLocalId(localId);
    });
  }

  void _cancelAssignmentChanges() {
    setState(() {
      _assignmentSnapshot = EditableScaleAssignmentSnapshot(
        original: _assignmentSnapshot.original,
        current: _assignmentSnapshot.original,
      );
    });
  }

  bool _hasEditableVacancy(ScaleRoleAssignmentsEntity assignment) {
    final assignedCount = _assignmentSnapshot
        .assignmentsForRole(assignment.item.roleId)
        .length;
    return assignedCount < assignment.capacity;
  }
}

class _ScaleDetailActions extends StatelessWidget {
  const _ScaleDetailActions({
    required this.enabled,
    required this.isDeleting,
    required this.onDelete,
  });

  final bool enabled;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (isDeleting) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return PopupMenuButton<_ScaleDetailAction>(
      enabled: enabled,
      tooltip: 'Ações da escala',
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (action) {
        if (action == _ScaleDetailAction.delete) onDelete();
      },
      itemBuilder: (context) => const [
        PopupMenuItem<_ScaleDetailAction>(
          value: _ScaleDetailAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline),
              SizedBox(width: 12),
              Text('Excluir escala'),
            ],
          ),
        ),
      ],
    );
  }
}

enum _ScaleDetailAction { delete }

class _ScaleDetailContent extends StatelessWidget {
  const _ScaleDetailContent({
    required this.detail,
    required this.assignments,
    required this.canManageScale,
    required this.canAddPeople,
    required this.onAddPerson,
    required this.onOpenVacancy,
    required this.onRemoveAssignment,
  });

  final DepartmentScaleDetailEntity detail;
  final EditableScaleAssignmentSnapshot assignments;
  final bool canManageScale;
  final bool canAddPeople;
  final VoidCallback? onAddPerson;
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
        if (canManageScale) ...[
          const SizedBox(height: 16),
          _AddPersonButton(enabled: canAddPeople, onPressed: onAddPerson),
        ],
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
        color: AppColors.primary.withValues(alpha: 0.04),
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
    final row = Row(
      children: [
        Expanded(
          child: Row(
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
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (kIsWeb && onRemove != null)
          PopupMenuButton<_AssignedPersonAction>(
            tooltip: 'Ações de ${assignment.displayName}',
            icon: const Icon(Icons.more_vert_rounded),
            itemBuilder: (context) => _removeAssignmentMenuItems,
            onSelected: (action) {
              if (action == _AssignedPersonAction.remove) {
                onRemove?.call();
              }
            },
          ),
      ],
    );

    if (onRemove == null || kIsWeb) return row;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showRemoveAssignmentMenu(context),
      child: row,
    );
  }

  Future<void> _showRemoveAssignmentMenu(BuildContext context) async {
    final anchor = context.findRenderObject();
    if (anchor is! RenderBox) return;

    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) return;

    final anchorBounds = MatrixUtils.transformRect(
      anchor.getTransformTo(overlay),
      Offset.zero & anchor.size,
    );

    final action = await showMenu<_AssignedPersonAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        anchorBounds.left,
        anchorBounds.bottom,
        overlay.size.width - anchorBounds.right,
        overlay.size.height - anchorBounds.bottom,
      ),
      items: _removeAssignmentMenuItems,
    );

    if (action == _AssignedPersonAction.remove) {
      onRemove?.call();
    }
  }
}

enum _AssignedPersonAction { remove }

const _removeAssignmentMenuItems = [
  PopupMenuItem<_AssignedPersonAction>(
    value: _AssignedPersonAction.remove,
    child: SizedBox(
      width: 184,
      child: Row(
        children: [
          Icon(Icons.person_remove_outlined),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Remover da escala',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  ),
];

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

class _AddPersonButton extends StatelessWidget {
  const _AddPersonButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      child: const Text('Adicionar pessoa'),
    );
  }
}

class _ScaleEditActionBar extends StatelessWidget {
  const _ScaleEditActionBar({
    required this.isSaving,
    required this.onCancel,
    required this.onComplete,
  });

  final bool isSaving;
  final VoidCallback? onCancel;
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
                onPressed: onCancel,
                child: const Text('Cancelar'),
              ),
            ),
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
