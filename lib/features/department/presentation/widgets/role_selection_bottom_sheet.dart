import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/utils/string_utils.dart';
import 'package:client/features/department/data/models/role_request_model.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:client/features/department/providers/department_lineup_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RoleSelectionMode { lineup, ability }

Future<void> showRoleSelectionBottomSheet({
  required BuildContext context,
  required Map<String, int> selectedRoleCounts,
  required ValueChanged<RoleEntity> onSelect,
  RoleSelectionMode mode = RoleSelectionMode.lineup,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RoleSelectionSheet(
      selectedRoleCounts: selectedRoleCounts,
      onSelect: onSelect,
      mode: mode,
    ),
  );
}

class _RoleSelectionSheet extends ConsumerStatefulWidget {
  const _RoleSelectionSheet({
    required this.selectedRoleCounts,
    required this.onSelect,
    required this.mode,
  });

  final Map<String, int> selectedRoleCounts;
  final ValueChanged<RoleEntity> onSelect;
  final RoleSelectionMode mode;

  @override
  ConsumerState<_RoleSelectionSheet> createState() =>
      _RoleSelectionSheetState();
}

class _RoleSelectionSheetState extends ConsumerState<_RoleSelectionSheet> {
  final _searchController = TextEditingController();
  late final Map<String, int> _selectedCounts;
  final List<RoleEntity> _createdRoles = [];

  @override
  void initState() {
    super.initState();
    _selectedCounts = Map<String, int>.from(widget.selectedRoleCounts);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Material(
            color: AppColors.surface,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDADCE0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  ListTile(
                    title: const Text(
                      'Selecionar papel',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar papel...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: rolesAsync.when(
                      loading: () => const _RoleLoadingList(),
                      error: (error, stackTrace) => const _SheetStatus(
                        icon: Icons.assignment_late_outlined,
                        title: 'Não foi possível carregar os papéis.',
                      ),
                      data: (roles) =>
                          _buildRoleList(context, scrollController, roles),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleList(
    BuildContext context,
    ScrollController scrollController,
    List<RoleEntity> providerRoles,
  ) {
    final roles = _mergeRoles(providerRoles);
    final query = _searchController.text;
    final normalizedQuery = normalizeSearchTerm(query);
    final filteredRoles = roles.where((role) {
      if (normalizedQuery.isEmpty) return true;
      return normalizeSearchTerm(role.name).contains(normalizedQuery);
    }).toList()..sort(_compareRolesForSheet);
    final hasExactMatch = roles.any(
      (role) => normalizeSearchTerm(role.name) == normalizedQuery,
    );
    final canCreate = normalizedQuery.isNotEmpty && !hasExactMatch;

    if (roles.isEmpty && normalizedQuery.isEmpty) {
      return const _SheetStatus(
        icon: Icons.assignment_outlined,
        title: 'Nenhum papel encontrado',
      );
    }

    final showSearchEmpty = filteredRoles.isEmpty && normalizedQuery.isNotEmpty;
    if (showSearchEmpty && !canCreate) {
      return _SheetStatus(
        icon: Icons.search_off_outlined,
        title: 'Nenhum papel encontrado para "$query"',
      );
    }

    final rowCount =
        filteredRoles.length + (canCreate ? 1 : 0) + (showSearchEmpty ? 1 : 0);

    return ListView.separated(
      controller: scrollController,
      itemCount: rowCount,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (canCreate && index == 0) {
          return _CreateRoleTile(term: query.trim(), onTap: _createRole);
        }

        final roleIndex = canCreate ? index - 1 : index;
        if (showSearchEmpty && roleIndex >= filteredRoles.length) {
          return SizedBox(
            height: 180,
            child: _SheetStatus(
              icon: Icons.search_off_outlined,
              title: 'Nenhum papel encontrado para "$query"',
            ),
          );
        }

        final role = filteredRoles[roleIndex];
        final count = _selectedCounts[role.id] ?? 0;

        return ListTile(
          title: Text(role.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(_counterLabel(count)),
          trailing: IconButton(
            tooltip: 'Adicionar papel',
            onPressed: () => _selectRole(role),
            icon: const Icon(Icons.add),
          ),
          onTap: () => _selectRole(role),
        );
      },
    );
  }

  List<RoleEntity> _mergeRoles(List<RoleEntity> providerRoles) {
    final byId = <String, RoleEntity>{};
    for (final role in _createdRoles) {
      byId[role.id] = role;
    }
    for (final role in providerRoles) {
      byId.putIfAbsent(role.id, () => role);
    }
    return byId.values.toList();
  }

  int _compareRolesForSheet(RoleEntity a, RoleEntity b) {
    final countA = _selectedCounts[a.id] ?? 0;
    final countB = _selectedCounts[b.id] ?? 0;
    if (countA != countB) return countB.compareTo(countA);
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  void _selectRole(RoleEntity role) {
    setState(() {
      _selectedCounts[role.id] = (_selectedCounts[role.id] ?? 0) + 1;
    });
    widget.onSelect(role);
  }

  Future<void> _createRole(String term) async {
    final trimmedTerm = term.trim();
    if (trimmedTerm.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(roleActionsProvider.notifier)
        .create(RoleRequestModel(name: trimmedTerm));

    result.fold(
      (failure) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível criar o papel.')),
        );
      },
      (role) {
        setState(() {
          _createdRoles.insert(0, role);
        });
        _selectRole(role);
      },
    );
  }

  String _counterLabel(int count) {
    if (count <= 0) return '-';
    final suffix = widget.mode == RoleSelectionMode.lineup
        ? 'na formação'
        : 'selecionado';
    return '$count $suffix';
  }
}

class _CreateRoleTile extends StatelessWidget {
  const _CreateRoleTile({required this.term, required this.onTap});

  final String term;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
      title: Text('Criar papel "$term"'),
      onTap: () => onTap(term),
    );
  }
}

class _RoleLoadingList extends StatelessWidget {
  const _RoleLoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Container(
        key: const Key('role-loading-placeholder'),
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EAED),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _SheetStatus extends StatelessWidget {
  const _SheetStatus({required this.icon, required this.title});

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
