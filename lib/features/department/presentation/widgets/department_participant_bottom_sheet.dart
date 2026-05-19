import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/presentation/widgets/action_confirmation_dialog.dart';
import 'package:client/core/presentation/widgets/user_avatar.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/providers/department_detail_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showDepartmentParticipantBottomSheet(
  BuildContext context, {
  required String departmentId,
  required DepartmentParticipantEntity participant,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DepartmentParticipantBottomSheet(
      departmentId: departmentId,
      participant: participant,
    ),
  );
}

String translateIntegrationType(IntegrationType type) => switch (type) {
  IntegrationType.observer => 'Observador',
  IntegrationType.consultant => 'Consultor',
  IntegrationType.integrant => 'Integrante',
  IntegrationType.assistant => 'Assistente',
  IntegrationType.leader => 'Líder',
};

class _DepartmentParticipantBottomSheet extends StatelessWidget {
  const _DepartmentParticipantBottomSheet({
    required this.departmentId,
    required this.participant,
  });

  final String departmentId;
  final DepartmentParticipantEntity participant;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.52,
      minChildSize: 0.36,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: ColoredBox(
            color: AppColors.surface,
            child: SafeArea(
              top: false,
              child: _ParticipantContent(
                departmentId: departmentId,
                participant: participant,
                scrollController: scrollController,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ParticipantContent extends ConsumerStatefulWidget {
  const _ParticipantContent({
    required this.departmentId,
    required this.participant,
    required this.scrollController,
  });

  final String departmentId;
  final DepartmentParticipantEntity participant;
  final ScrollController scrollController;

  @override
  ConsumerState<_ParticipantContent> createState() =>
      _ParticipantContentState();
}

class _ParticipantContentState extends ConsumerState<_ParticipantContent> {
  late IntegrationType _selectedRole = widget.participant.integrationType;

  @override
  Widget build(BuildContext context) {
    final nickname = widget.participant.displayName;
    final phone = widget.participant.phone?.trim();
    final permissionsAsync = ref.watch(sessionPermissionsProvider);
    final canEdit =
        permissionsAsync.whenOrNull(
          data: (permissions) => permissions.canEditDept(widget.departmentId),
        ) ??
        false;
    final canManage =
        permissionsAsync.whenOrNull(
          data: (permissions) => permissions.canManageDept(widget.departmentId),
        ) ??
        false;
    final updateState = ref.watch(updateDepartmentParticipantRoleProvider);
    final removeState = ref.watch(removeDepartmentParticipantProvider);
    final isSubmitting = updateState.isLoading || removeState.isLoading;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const _SheetHandle(),
        const SizedBox(height: 24),
        Center(
          child: UserAvatar(
            displayName: nickname,
            radius: 36,
            profileImageId: widget.participant.profileImageId,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          nickname,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        if (phone != null && phone.isNotEmpty) ...[
          _DetailRow(icon: Icons.phone_outlined, label: phone),
          const SizedBox(height: 16),
        ],
        _DetailRow(
          icon: Icons.badge_outlined,
          label: translateIntegrationType(_selectedRole),
        ),
        if (canEdit) ...[
          const SizedBox(height: 24),
          const Text(
            'Papel no ministério',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<IntegrationType>(
            initialValue: _selectedRole,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: IntegrationType.values
                .map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Text(translateIntegrationType(role)),
                  ),
                )
                .toList(),
            onChanged: isSubmitting
                ? null
                : (role) {
                    if (role != null) {
                      setState(() => _selectedRole = role);
                    }
                  },
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed:
                isSubmitting ||
                    _selectedRole == widget.participant.integrationType
                ? null
                : _updateRole,
            child: const Text('Salvar papel'),
          ),
        ],
        if (canManage) ...[
          const SizedBox(height: 24),
          _RemoveParticipantButton(
            enabled: !isSubmitting,
            onTap: _confirmAndRemove,
          ),
        ],
        if (isSubmitting) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Future<void> _updateRole() async {
    final result = await ref
        .read(updateDepartmentParticipantRoleProvider.notifier)
        .updateRole(
          departmentId: widget.departmentId,
          membershipId: widget.participant.membershipId,
          role: _selectedRole,
        );
    if (!mounted) return;
    result.fold((failure) {
      setState(() => _selectedRole = widget.participant.integrationType);
      _showSnackBar(_failureMessage(failure));
    }, (_) => _showSnackBar('Papel atualizado.'));
  }

  Future<void> _confirmAndRemove() async {
    final confirmed = await showActionConfirmationDialog(
      context,
      title: 'Retirar do ministério',
      message: 'Tem certeza que deseja retirar esta pessoa do ministério?',
      confirmLabel: 'Retirar',
      isDestructive: true,
    );
    if (!confirmed) return;

    final result = await ref
        .read(removeDepartmentParticipantProvider.notifier)
        .remove(
          departmentId: widget.departmentId,
          membershipId: widget.participant.membershipId,
        );
    if (!mounted) return;
    result.fold((failure) => _showSnackBar(_failureMessage(failure)), (_) {
      Navigator.of(context).pop();
      _showSnackBar('Participante retirado do ministério.');
    });
  }

  String _failureMessage(Object failure) {
    if (failure is Failure) return failure.message;
    return failure.toString();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _RemoveParticipantButton extends StatelessWidget {
  const _RemoveParticipantButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(Icons.person_remove_alt_1_rounded, color: colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Retirar do ministério',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.error,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colorScheme.error),
            ],
          ),
        ),
      ),
    );
  }
}
