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

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => const _MemberFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMembershipAsync = ref.watch(activeMembershipProvider);
    final filters = ref.watch(memberFilterProvider);

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
              : 'Não foi possível carregar a unidade ativa.',
        ),
        data: (membership) {
          final unitId = membership?.unitId;
          if (unitId == null || unitId.isEmpty) {
            return const _InlineStatus(
              icon: Icons.people_outline,
              title: 'Nenhuma unidade ativa encontrada.',
              subtitle: 'Não foi possível identificar os membros para listar.',
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
                  loading: () => _CounterRow(
                    count: null,
                    hasActiveFilters: filters != MemberFilterState.defaultState,
                    onOpenFilters: _openFilterSheet,
                  ),
                  error: (error, stackTrace) => _CounterRow(
                    count: 0,
                    hasActiveFilters: filters != MemberFilterState.defaultState,
                    onOpenFilters: _openFilterSheet,
                  ),
                  data: (members) => _CounterRow(
                    count: members.length,
                    hasActiveFilters: filters != MemberFilterState.defaultState,
                    onOpenFilters: _openFilterSheet,
                  ),
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
                        : 'Não foi possível carregar os membros.',
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
  const _CounterRow({
    required this.count,
    required this.hasActiveFilters,
    required this.onOpenFilters,
  });

  final int? count;
  final bool hasActiveFilters;
  final VoidCallback onOpenFilters;

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
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onOpenFilters,
              icon: const Icon(Icons.filter_list),
              color: hasActiveFilters
                  ? AppColors.primary
                  : AppColors.textSecondary,
              tooltip: 'Filtrar membros',
            ),
            if (hasActiveFilters)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MemberFilterSheet extends ConsumerStatefulWidget {
  const _MemberFilterSheet();

  @override
  ConsumerState<_MemberFilterSheet> createState() => _MemberFilterSheetState();
}

class _MemberFilterSheetState extends ConsumerState<_MemberFilterSheet> {
  static const _allAffiliations = ['VISITOR', 'CONGREGATED', 'MEMBER'];
  static const _minAllowedAge = 0;
  static const _maxAllowedAge = 120;

  late Set<String> _localAffiliations;
  late String? _localGender;
  late bool _localAgeEnabled;
  late int _localMinAge;
  late int _localMaxAge;
  late final TextEditingController _minAgeController;
  late final TextEditingController _maxAgeController;

  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(memberFilterProvider);
    _localAffiliations = Set<String>.from(currentFilters.affiliations);
    _localGender = currentFilters.gender;
    _localAgeEnabled = currentFilters.hasActiveAgeRange;
    _localMinAge = currentFilters.minAge ?? _minAllowedAge;
    _localMaxAge = currentFilters.maxAge ?? _maxAllowedAge;
    _minAgeController = TextEditingController(text: '$_localMinAge');
    _maxAgeController = TextEditingController(text: '$_localMaxAge');
  }

  @override
  void dispose() {
    _minAgeController.dispose();
    _maxAgeController.dispose();
    super.dispose();
  }

  void _syncAgeControllers() {
    _minAgeController.value = TextEditingValue(
      text: '$_localMinAge',
      selection: TextSelection.collapsed(offset: '$_localMinAge'.length),
    );
    _maxAgeController.value = TextEditingValue(
      text: '$_localMaxAge',
      selection: TextSelection.collapsed(offset: '$_localMaxAge'.length),
    );
  }

  int _normalizeAgeValue(String rawValue, int fallback) {
    final parsed = int.tryParse(rawValue);
    if (parsed == null) return fallback;
    return parsed.clamp(_minAllowedAge, _maxAllowedAge);
  }

  void _updateMinAge(String value) {
    setState(() {
      _localMinAge = _normalizeAgeValue(value, _localMinAge);
      if (_localMinAge > _localMaxAge) {
        _localMaxAge = _localMinAge;
      }
      _syncAgeControllers();
    });
  }

  void _updateMaxAge(String value) {
    setState(() {
      _localMaxAge = _normalizeAgeValue(value, _localMaxAge);
      if (_localMaxAge < _localMinAge) {
        _localMinAge = _localMaxAge;
      }
      _syncAgeControllers();
    });
  }

  void _apply() {
    final notifier = ref.read(memberFilterProvider.notifier);
    notifier.setAffiliations(_localAffiliations);
    notifier.setGender(_localGender);
    notifier.setAgeRange(
      _localAgeEnabled ? _localMinAge : null,
      _localAgeEnabled ? _localMaxAge : null,
    );
    Navigator.of(context).pop();
  }

  void _resetAndClose() {
    ref.read(memberFilterProvider.notifier).reset();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                'Filtrar membros',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              const _SectionTitle('Filiação'),
              const SizedBox(height: 8),
              for (final affiliation in _allAffiliations)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_translateAffiliation(affiliation)),
                  value: _localAffiliations.contains(affiliation),
                  onChanged: (value) {
                    setState(() {
                      if (value) {
                        _localAffiliations.add(affiliation);
                      } else {
                        _localAffiliations.remove(affiliation);
                      }
                    });
                  },
                ),
              const SizedBox(height: 12),
              const _SectionTitle('Categoria'),
              RadioGroup<String?>(
                groupValue: _localGender,
                onChanged: (value) => setState(() => _localGender = value),
                child: const Column(
                  children: [
                    RadioListTile<String?>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Todos'),
                      value: null,
                    ),
                    RadioListTile<String?>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Homens'),
                      value: 'MALE',
                    ),
                    RadioListTile<String?>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Mulheres'),
                      value: 'FEMALE',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const _SectionTitle('Faixa etária'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Filtrar por idade'),
                value: _localAgeEnabled,
                onChanged: (value) => setState(() => _localAgeEnabled = value),
              ),
              if (_localAgeEnabled) ...[
                RangeSlider(
                  values: RangeValues(
                    _localMinAge.toDouble(),
                    _localMaxAge.toDouble(),
                  ),
                  min: _minAllowedAge.toDouble(),
                  max: _maxAllowedAge.toDouble(),
                  divisions: _maxAllowedAge - _minAllowedAge,
                  labels: RangeLabels('$_localMinAge', '$_localMaxAge'),
                  onChanged: (values) {
                    setState(() {
                      _localMinAge = values.start.round();
                      _localMaxAge = values.end.round();
                      _syncAgeControllers();
                    });
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minAgeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Idade mínima',
                        ),
                        onChanged: _updateMinAge,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxAgeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Idade máxima',
                        ),
                        onChanged: _updateMaxAge,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: _resetAndClose,
                    child: const Text('Limpar filtros'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _apply,
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final UnitMemberEntity member;

  @override
  Widget build(BuildContext context) {
    final age = calculateAge(member.birthDate);
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

String _translateAffiliation(String affiliation) {
  return switch (affiliation.toUpperCase()) {
    'MEMBER' => 'Membros',
    'CONGREGATED' => 'Congregados',
    'VISITOR' => 'Visitantes',
    _ => affiliation,
  };
}
