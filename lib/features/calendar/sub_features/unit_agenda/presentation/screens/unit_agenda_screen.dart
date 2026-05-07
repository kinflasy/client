import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UnitAgendaScreen extends StatelessWidget {
  const UnitAgendaScreen({super.key});

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Em breve')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calendário'),
        backgroundColor: AppColors.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.adminCalendarCreate),
              icon: const Icon(Icons.add),
              label: const Text('Criar evento'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showComingSoon(context),
              icon: const Icon(Icons.list),
              label: const Text('Ver eventos'),
            ),
          ],
        ),
      ),
    );
  }
}
