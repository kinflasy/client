import 'package:client/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/auth/providers/auth_providers.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref
        .watch(authProvider)
        .when(data: (u) => u, loading: () => null, error: (_, __) => null);
    final displayName = user?.nickname ?? user?.fullName ?? user?.username ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _UserHeader(displayName: displayName),
            const SizedBox(height: 16),
            _MenuSection(
              children: [
                _MenuItem(
                  icon: Icons.church_outlined,
                  label: 'Cadastrar Igreja',
                  onTap: () => ref.read(appRouterProvider).go(AppRoutes.registerChurch),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MenuSection(
              children: [
                _MenuItem(
                  icon: Icons.settings_outlined,
                  label: 'Configurações',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.logout,
                  label: 'Sair',
                  color: Colors.red.shade600,
                  onTap: () => _confirmLogout(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Sair', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authProvider.notifier).signOut();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }
}

class _UserHeader extends StatelessWidget {
  final String displayName;
  const _UserHeader({required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF1A73E8),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<Widget> children;
  const _MenuSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(children: children),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? const Color(0xFF1A73E8);
    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(label, style: TextStyle(color: color ?? Colors.black87)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      onTap: onTap,
    );
  }
}
