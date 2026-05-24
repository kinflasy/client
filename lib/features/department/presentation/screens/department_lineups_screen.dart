import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/department/presentation/widgets/department_lineup_card.dart';
import 'package:client/features/department/providers/department_lineup_providers.dart';
import 'package:client/features/user_profile/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DepartmentLineupsScreen extends ConsumerWidget {
  const DepartmentLineupsScreen({super.key, required this.departmentId});

  final String departmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineupsAsync = ref.watch(departmentLineupsProvider(departmentId));
    final canManageDepartment =
        ref
            .watch(sessionPermissionsProvider)
            .whenOrNull(
              data: (permissions) => permissions.canManageDept(departmentId),
            ) ??
        false;
    final createButton = _CreateLineupButton(
      onPressed: () async {
        await context.pushNamed(
          AppRoutes.departmentLineupCreateName,
          pathParameters: {'id': departmentId},
        );
        ref.invalidate(departmentLineupsProvider(departmentId));
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Escalas'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: lineupsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const _LineupsStatus(
            icon: Icons.assignment_late_outlined,
            title: 'Não foi possível carregar as escalas.',
            subtitle: 'Tente novamente em instantes.',
          ),
          data: (lineups) {
            if (lineups.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (canManageDepartment) ...[
                      createButton,
                      const SizedBox(height: 16),
                    ],
                    const Expanded(
                      child: _LineupsStatus(
                        icon: Icons.assignment_outlined,
                        title: 'Nenhuma escala criada ainda.',
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: lineups.length + (canManageDepartment ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (canManageDepartment && index == 0) return createButton;

                final lineupIndex = canManageDepartment ? index - 1 : index;
                final lineup = lineups[lineupIndex];

                return DepartmentLineupCard(
                  lineup: lineup,
                  onTap: () async {
                    await context.pushNamed(
                      AppRoutes.departmentLineupDetailName,
                      pathParameters: {
                        'departmentId': departmentId,
                        'lineupId': lineup.id,
                      },
                    );
                    ref.invalidate(departmentLineupsProvider(departmentId));
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CreateLineupButton extends StatelessWidget {
  const _CreateLineupButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('Criar nova formação de escala'),
    );
  }
}

class _LineupsStatus extends StatelessWidget {
  const _LineupsStatus({
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
