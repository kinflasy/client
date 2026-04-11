import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/unit_member_entity.dart';
import 'package:client/features/membership/providers/unit_member_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MembersListScreen extends ConsumerStatefulWidget {
  const MembersListScreen({super.key});

  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends ConsumerState<MembersListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeMembershipAsync = ref.watch(activeMembershipProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Membros e Pessoas Vinculadas'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: activeMembershipAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _InlineStatus(
          icon: Icons.error_outline,
          title: error is Failure
              ? error.message
              : 'Nao foi possivel carregar a unidade ativa.',
        ),
        data: (membership) {
          final unitId = membership?.unitId;
          if (unitId == null || unitId.isEmpty) {
            return const _InlineStatus(
              icon: Icons.people_outline,
              title: 'Nenhuma unidade ativa encontrada.',
              subtitle: 'Nao foi possivel identificar os membros para listar.',
            );
          }

          final membersAsync = ref.watch(filteredMembersProvider(unitId));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => ref
                      .read(memberSearchQueryProvider.notifier)
                      .update(value),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou apelido',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: membersAsync.when(
                  loading: () => const _CounterRow(count: null),
                  error: (error, stackTrace) => const _CounterRow(count: 0),
                  data: (members) => _CounterRow(count: members.length),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: membersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => _InlineStatus(
                    icon: Icons.group_off_outlined,
                    title: error is Failure
                        ? error.message
                        : 'Nao foi possivel carregar os membros.',
                    subtitle: 'Tente novamente em instantes.',
                  ),
                  data: (members) {
                    if (members.isEmpty) {
                      return const _InlineStatus(
                        icon: Icons.search_off_outlined,
                        title: 'Nenhum membro encontrado.',
                        subtitle: 'Tente buscar por outro nome ou apelido.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: members.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _MemberCard(member: members[index]),
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
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final label = count == null ? 'Carregando...' : '$count pessoas';

    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: null,
          icon: const Icon(Icons.filter_list),
          color: AppColors.textSecondary,
          tooltip: 'Filtros em breve',
        ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final UnitMemberEntity member;

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge(member.birthDate);
    final affiliation = _translateAffiliation(member.affiliation);
    final subtitle = age == null ? affiliation : '$affiliation · $age anos';
    final isMale = member.gender.toUpperCase() == 'MALE';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(
            isMale ? Icons.person : Icons.person_2,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          member.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({
    required this.icon,
    required this.title,
    this.subtitle,
  });

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

int? _calculateAge(DateTime? birthDate) {
  if (birthDate == null) return null;

  final now = DateTime.now();
  var age = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }

  return age;
}

String _translateAffiliation(String affiliation) {
  return switch (affiliation.toUpperCase()) {
    'MEMBER' => 'Membro',
    'CONGREGATED' => 'Congregado',
    'VISITOR' => 'Visitante',
    _ => affiliation,
  };
}
