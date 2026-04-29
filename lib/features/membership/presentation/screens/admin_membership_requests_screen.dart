import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/presentation/widgets/action_confirmation_dialog.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/pending_unit_membership_entity.dart';
import 'package:client/features/membership/providers/membership_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminMembershipRequestsScreen extends ConsumerWidget {
  const AdminMembershipRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMembershipAsync = ref.watch(activeMembershipProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Solicitações de vínculo'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: activeMembershipAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _InlineStatus(
          icon: Icons.error_outline,
          title: error is Failure
              ? error.message
              : 'Não foi possível carregar a unidade ativa.',
        ),
        data: (membership) {
          final unitId = membership?.unitId;
          if (unitId == null || unitId.isEmpty) {
            return const _InlineStatus(
              icon: Icons.link_off_outlined,
              title: 'Nenhuma unidade ativa encontrada.',
              subtitle:
                  'Não foi possível identificar a unidade para listar as solicitações.',
            );
          }

          return _PendingRequestsBody(unitId: unitId);
        },
      ),
    );
  }
}

class _PendingRequestsBody extends ConsumerWidget {
  const _PendingRequestsBody({required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingUnitMembershipsProvider(unitId));
    final actionState = ref.watch(pendingUnitMembershipActionProvider);
    final isBusy = actionState.isLoading;

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _InlineStatus(
        icon: Icons.group_off_outlined,
        title: error is Failure
            ? error.message
            : 'Não foi possível carregar as solicitações.',
        subtitle: 'Tente novamente em instantes.',
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return const _InlineStatus(
            icon: Icons.mark_email_read_outlined,
            title: 'Nenhuma solicitação pendente.',
            subtitle: 'Quando houver novos pedidos, eles aparecerão aqui.',
          );
        }

        final countLabel = requests.length == 1
            ? '1 solicitação pendente'
            : '${requests.length} solicitações pendentes';

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  countLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: requests.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return _PendingMembershipCard(
                    request: request,
                    isLoading: isBusy,
                    onApprove: () => _handleApprove(context, ref, request),
                    onReject: () => _handleReject(context, ref, request),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleApprove(
    BuildContext context,
    WidgetRef ref,
    PendingUnitMembershipEntity request,
  ) async {
    final actionState = ref.read(pendingUnitMembershipActionProvider);
    if (actionState.isLoading) return;

    final selectedAffiliation = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => _ApproveMembershipSheet(
        isLoading: actionState.isLoading,
        onMemberSelected: () => Navigator.of(sheetContext).pop('MEMBER'),
        onCongregatedSelected: () =>
            Navigator.of(sheetContext).pop('CONGREGATED'),
      ),
    );

    if (selectedAffiliation == null || !context.mounted) return;

    final affiliationLabel = _translateAffiliation(selectedAffiliation);
    final confirmed = await showActionConfirmationDialog(
      context,
      title: 'Aprovar solicitação',
      message:
          'Deseja aceitar ${_displayName(request)} como $affiliationLabel nesta unidade?',
      confirmLabel: 'Confirmar',
    );

    if (!confirmed || !context.mounted) return;

    final result = await ref
        .read(pendingUnitMembershipActionProvider.notifier)
        .approveWithAffiliation(unitId, request.personId, selectedAffiliation);

    if (!context.mounted) return;

    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação aprovada com sucesso.')),
      ),
    );
  }

  Future<void> _handleReject(
    BuildContext context,
    WidgetRef ref,
    PendingUnitMembershipEntity request,
  ) async {
    final confirmed = await showActionConfirmationDialog(
      context,
      title: 'Rejeitar solicitação',
      message:
          'Deseja rejeitar a solicitação de vínculo de ${_displayName(request)}?',
      confirmLabel: 'Rejeitar',
      isDestructive: true,
    );

    if (!confirmed || !context.mounted) return;

    final result = await ref
        .read(pendingUnitMembershipActionProvider.notifier)
        .reject(unitId, request.personId);

    if (!context.mounted) return;

    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação rejeitada com sucesso.')),
      ),
    );
  }
}

class _ApproveMembershipSheet extends StatelessWidget {
  const _ApproveMembershipSheet({
    required this.isLoading,
    required this.onMemberSelected,
    required this.onCongregatedSelected,
  });

  final bool isLoading;
  final VoidCallback onMemberSelected;
  final VoidCallback onCongregatedSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Como deseja aceitar esta solicitação?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escolha a filiação final que será aplicada antes da confirmação.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              _ApproveOptionTile(
                icon: Icons.person,
                title: 'Aceitar como membro',
                subtitle: 'Confirma a solicitação com filiação de membro.',
                onTap: isLoading ? null : onMemberSelected,
              ),
              const SizedBox(height: 12),
              _ApproveOptionTile(
                icon: Icons.groups_2_outlined,
                title: 'Aceitar como congregado',
                subtitle: 'Confirma a solicitação com filiação de congregado.',
                onTap: isLoading ? null : onCongregatedSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApproveOptionTile extends StatelessWidget {
  const _ApproveOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingMembershipCard extends StatelessWidget {
  const _PendingMembershipCard({
    required this.request,
    required this.isLoading,
    required this.onApprove,
    required this.onReject,
  });

  final PendingUnitMembershipEntity request;
  final bool isLoading;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _displayName(request),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Solicitou vínculo como ${_translateAffiliation(request.affiliation)}.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: isLoading ? null : onReject,
                icon: const Icon(Icons.close),
                label: const Text('Rejeitar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
              FilledButton.icon(
                onPressed: isLoading ? null : onApprove,
                icon: const Icon(Icons.check),
                label: const Text('Aprovar'),
              ),
            ],
          ),
        ],
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

String _displayName(PendingUnitMembershipEntity request) {
  final name = request.fullName?.trim();
  if (name != null && name.isNotEmpty) {
    return name;
  }
  return 'Pessoa sem identificação';
}

String _translateAffiliation(String affiliation) {
  return switch (affiliation.toUpperCase()) {
    'CONGREGATED' => 'congregado',
    'MEMBER' => 'membro',
    'VISITOR' => 'visitante',
    _ => affiliation.toLowerCase(),
  };
}
