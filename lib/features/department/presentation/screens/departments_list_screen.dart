import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/department/presentation/widgets/department_card.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DepartmentsListScreen extends ConsumerStatefulWidget {
  const DepartmentsListScreen({super.key});

  @override
  ConsumerState<DepartmentsListScreen> createState() =>
      _DepartmentsListScreenState();
}

class _DepartmentsListScreenState extends ConsumerState<DepartmentsListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(departmentSearchQueryProvider),
    );
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
        title: const Text('Departamentos'),
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
              icon: Icons.account_tree_outlined,
              title: 'Nenhuma unidade ativa encontrada.',
              subtitle:
                  'Não foi possível identificar os departamentos para listar.',
            );
          }

          final rawDepartmentsAsync = ref.watch(departmentsProvider(unitId));
          final filteredDepartmentsAsync = ref.watch(
            filteredDepartmentsProvider(unitId),
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => ref
                          .read(departmentSearchQueryProvider.notifier)
                          .update(value),
                      decoration: InputDecoration(
                        hintText: 'Buscar departamento por nome',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            context.push(AppRoutes.adminDepartmentsRegister),
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar departamento'),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: filteredDepartmentsAsync.when(
                  loading: () => const _CounterRow(count: null),
                  error: (error, stackTrace) => const _CounterRow(count: 0),
                  data: (departments) => _CounterRow(count: departments.length),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filteredDepartmentsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => _InlineStatus(
                    icon: Icons.groups_2_outlined,
                    title: error is Failure
                        ? error.message
                        : 'Não foi possível carregar os departamentos.',
                    subtitle: 'Tente novamente em instantes.',
                  ),
                  data: (departments) => rawDepartmentsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => _InlineStatus(
                      icon: Icons.groups_2_outlined,
                      title: error is Failure
                          ? error.message
                          : 'Não foi possível carregar os departamentos.',
                      subtitle: 'Tente novamente em instantes.',
                    ),
                    data: (rawDepartments) {
                      if (departments.isEmpty) {
                        if (rawDepartments.isEmpty) {
                          return const _InlineStatus(
                            icon: Icons.groups_outlined,
                            title: 'Nenhum departamento cadastrado.',
                            subtitle: 'Adicione um departamento para começar.',
                          );
                        }

                        return const _InlineStatus(
                          icon: Icons.search_off_outlined,
                          title:
                              'Nenhum departamento encontrado para esta busca.',
                          subtitle:
                              'Tente buscar por outro nome de departamento.',
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: departments.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) => DepartmentCard(
                          department: departments[index],
                          onTap: () => context.pushNamed(
                            AppRoutes.departmentDetailName,
                            pathParameters: {'id': departments[index].id},
                          ),
                        ),
                      );
                    },
                  ),
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
    final label = count == null ? 'Carregando...' : '$count departamentos';

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
      ],
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
