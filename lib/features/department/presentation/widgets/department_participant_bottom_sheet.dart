import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/core/presentation/widgets/user_avatar.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/providers/department_detail_providers.dart';
import 'package:client/features/membership/data/models/person_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showDepartmentParticipantBottomSheet(
  BuildContext context, {
  required DepartmentParticipantEntity participant,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DepartmentParticipantBottomSheet(participant: participant),
  );
}

String translateIntegrationType(IntegrationType type) => switch (type) {
  IntegrationType.observer => 'Observador',
  IntegrationType.consultant => 'Consultor',
  IntegrationType.integrant => 'Integrante',
  IntegrationType.assistant => 'Assistente',
  IntegrationType.leader => 'Líder',
};

class _DepartmentParticipantBottomSheet extends ConsumerWidget {
  const _DepartmentParticipantBottomSheet({required this.participant});

  final DepartmentParticipantEntity participant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(
      departmentParticipantPersonProvider(participant.personId),
    );

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
              child: personAsync.when(
                loading: () =>
                    _ParticipantLoading(scrollController: scrollController),
                error: (error, stackTrace) =>
                    _ParticipantError(scrollController: scrollController),
                data: (person) => _ParticipantContent(
                  participant: participant,
                  person: person,
                  scrollController: scrollController,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ParticipantContent extends StatelessWidget {
  const _ParticipantContent({
    required this.participant,
    required this.person,
    required this.scrollController,
  });

  final DepartmentParticipantEntity participant;
  final PersonProfileModel person;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final nickname = _resolvedNickname(person, participant);
    final phone = person.phone?.trim();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const _SheetHandle(),
        const SizedBox(height: 24),
        Center(
          child: UserAvatar(
            displayName: nickname,
            radius: 36,
            profileImageId: person.profileImageId,
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
          label: translateIntegrationType(participant.integrationType),
        ),
      ],
    );
  }
}

String _resolvedNickname(
  PersonProfileModel person,
  DepartmentParticipantEntity participant,
) {
  final personNickname = person.nickname?.trim();
  if (personNickname != null && personNickname.isNotEmpty) {
    return personNickname;
  }
  return participant.displayName;
}

class _ParticipantLoading extends StatelessWidget {
  const _ParticipantLoading({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: const [
        _SheetHandle(),
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator()),
        SizedBox(height: 16),
        Center(
          child: Text(
            'Carregando detalhes do participante...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _ParticipantError extends StatelessWidget {
  const _ParticipantError({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: const [
        _SheetHandle(),
        SizedBox(height: 120),
        Icon(
          Icons.person_off_outlined,
          size: 40,
          color: AppColors.textSecondary,
        ),
        SizedBox(height: 12),
        Text(
          'Não foi possível carregar os detalhes do participante.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Tente novamente em instantes.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
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
