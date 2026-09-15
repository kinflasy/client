import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/presentation/widgets/user_avatar.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/presentation/widgets/church_shared_widgets.dart';
import 'package:client/features/membership/domain/entities/member_profile_entity.dart';
import 'package:client/features/membership/domain/entities/unit_member_entity.dart';
import 'package:client/features/membership/domain/enums/person_type.dart';
import 'package:client/features/membership/providers/member_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({
    super.key,
    required this.personId,
    this.initialMember,
  });

  final String personId;
  final UnitMemberEntity? initialMember;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(memberProfileProvider(personId));

    return profileAsync.when(
      loading: () => _LoadingState(initialMember: initialMember),
      error: (error, _) => _ErrorState(
        message: error is Failure
            ? error.message
            : 'Nao foi possivel carregar o perfil do membro.',
        onRetry: () => ref.invalidate(memberProfileProvider(personId)),
      ),
      data: (profile) => _ProfileContent(profile: profile),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({this.initialMember});

  final UnitMemberEntity? initialMember;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            if (initialMember != null)
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      title: initialMember!.fullName,
                      subtitle: initialMember!.nickname,
                      type: null,
                      profileImageId: initialMember!.profileImageId,
                    ),
                  ),
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              )
            else
              const Center(child: CircularProgressIndicator()),
            const ChurchFloatingBackButton(),
          ],
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final MemberProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final hasContact = _hasText(profile.phone) || _hasText(profile.email);
    final hasIdentity =
        _hasText(profile.affiliation) || profile.entryDate != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                title: profile.fullName,
                subtitle: profile.nickname,
                type: profile.personType,
                profileImageId: profile.profileImageId,
              ),
            ),
            if (profile.age != null || _hasText(profile.gender))
              SliverToBoxAdapter(
                child: _InfoSection(
                  title: 'Resumo',
                  children: [
                    if (profile.age != null)
                      _InfoRow(
                        icon: Icons.cake_outlined,
                        value: '${profile.age} anos',
                      ),
                    if (_hasText(profile.gender))
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        value: _translateGender(profile.gender),
                      ),
                  ],
                ),
              ),
            if (hasContact)
              SliverToBoxAdapter(
                child: _InfoSection(
                  title: 'Contato',
                  children: [
                    if (_hasText(profile.phone))
                      _InfoRow(
                        icon: Icons.call_outlined,
                        value: profile.phone!,
                      ),
                    if (_hasText(profile.email))
                      _InfoRow(icon: Icons.mail_outline, value: profile.email!),
                  ],
                ),
              ),
            if (_hasText(profile.address))
              SliverToBoxAdapter(
                child: _InfoSection(
                  title: 'Endereco',
                  children: [
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      value: profile.address!,
                    ),
                  ],
                ),
              ),
            if (hasIdentity)
              SliverToBoxAdapter(
                child: _InfoSection(
                  title: 'Vínculo',
                  children: [
                    if (_hasText(profile.affiliation))
                      _InfoRow(
                        icon: Icons.groups_outlined,
                        value: _translateAffiliation(profile.affiliation),
                      ),
                    if (profile.entryDate != null)
                      _InfoRow(
                        icon: Icons.event_outlined,
                        value: _formatDate(profile.entryDate!),
                      ),
                  ],
                ),
              ),
            if (profile.integrations.isNotEmpty)
              SliverToBoxAdapter(
                child: _InfoSection(
                  title: 'Integrações',
                  children: profile.integrations
                      .map(
                        (integration) => _InfoRow(
                          icon: Icons.account_tree_outlined,
                          value:
                              '${integration.departmentName} - ${_translateIntegrationType(integration.integrationType.name)}',
                        ),
                      )
                      .toList(),
                ),
              ),
            if (profile.personType == PersonType.inactive)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.pushNamed(
                          AppRoutes.adminMembersActivateName,
                          extra: profile,
                        ),
                        icon: const Icon(Icons.link),
                        label: const Text('Vincular usuário'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.pushNamed(
                          AppRoutes.peopleEditName,
                          pathParameters: {'id': profile.personId},
                          extra: profile,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar cadastro'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.type,
    this.profileImageId,
  });

  final String title;
  final String? subtitle;
  final PersonType? type;
  final String? profileImageId;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 68, 20, 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F4C81), AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
                child: UserAvatar(
                  displayName: title,
                  radius: 32,
                  profileImageId: profileImageId,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (_hasText(subtitle)) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
              if (type != null) ...[
                const SizedBox(height: 14),
                _TypeChip(type: type!),
              ],
            ],
          ),
        ),
        const ChurchFloatingBackButton(),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final PersonType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        switch (type) {
          PersonType.user => 'Usuario do app',
          PersonType.inactive => 'Pessoa inativa',
        },
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
              const SizedBox(height: 6),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

String _translateGender(String gender) {
  return switch (gender.toUpperCase()) {
    'MALE' => 'Homem',
    'FEMALE' => 'Mulher',
    _ => gender,
  };
}

String _translateAffiliation(String affiliation) {
  return switch (affiliation.toUpperCase()) {
    'MEMBER' => 'Membro',
    'CONGREGATED' => 'Congregado',
    'VISITOR' => 'Visitante',
    _ => affiliation,
  };
}

String _translateIntegrationType(String integrationType) {
  return switch (integrationType.toUpperCase()) {
    'OBSERVER' => 'Observador',
    'CONSULTANT' => 'Consultor',
    'INTEGRANT' => 'Integrante',
    'ASSISTANT' => 'Assistente',
    'LEADER' => 'Lider',
    _ => integrationType,
  };
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
