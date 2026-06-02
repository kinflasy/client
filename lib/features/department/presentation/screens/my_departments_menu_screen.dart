import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/domain/entities/my_departments_unit_group.dart';
import 'package:client/features/department/presentation/widgets/department_card.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyDepartmentsMenuScreen extends ConsumerStatefulWidget {
  const MyDepartmentsMenuScreen({super.key});

  @override
  ConsumerState<MyDepartmentsMenuScreen> createState() =>
      _MyDepartmentsMenuScreenState();
}

class _MyDepartmentsMenuScreenState
    extends ConsumerState<MyDepartmentsMenuScreen> {
  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(myDepartmentsByUnitProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meus departamentos'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _InlineStatus(
          icon: Icons.groups_2_outlined,
          title: 'Não foi possível carregar seus departamentos.',
          subtitle: 'Tente novamente em instantes.',
        ),
        data: (groups) {
          return Column(
            children: [
              Expanded(
                child: groups.isEmpty
                    ? _buildEmptyState(groups)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: groups.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 24),
                        itemBuilder: (context, index) =>
                            _UnitGroupSection(group: groups[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(List<MyDepartmentsUnitGroup> groups) {
    return const _InlineStatus(
      icon: Icons.groups_outlined,
      title: 'Você ainda não participa de nenhum departamento.',
      subtitle:
          'Quando houver departamentos vinculados ao seu perfil, eles aparecerão aqui.',
    );
  }
}

class _UnitGroupSection extends StatelessWidget {
  const _UnitGroupSection({required this.group});

  final MyDepartmentsUnitGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.unitName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _DepartmentList(departments: group.departments),
      ],
    );
  }
}

class _DepartmentList extends StatelessWidget {
  const _DepartmentList({required this.departments});

  final List<DepartmentEntity> departments;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: departments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final department = departments[index];

        return DepartmentCard(
          department: department,
          onTap: () => context.pushNamed(
            AppRoutes.departmentDetailName,
            pathParameters: {'id': department.id},
          ),
        );
      },
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
