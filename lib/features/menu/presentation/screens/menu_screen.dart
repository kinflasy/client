import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:go_router/go_router.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).whenOrNull(data: (u) => u);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _UserHeader(user: user),
              const SizedBox(height: 24),
              const _QuickActions(),
              const SizedBox(height: 24),
              const _FunctionalityGrid(),
              const SizedBox(height: 24),
              const _SignOutButton(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cabeçalho com foto e nome do usuário ───────────────────────────────────

class _UserHeader extends StatelessWidget {
  final UserEntity? user;
  const _UserHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          child: Text(initial, style: const TextStyle(fontSize: 24)),
          // TODO: foto de perfil — aguardando suporte do backend
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ],
    );
  }
}

// ─── Botões de ação rápida ───────────────────────────────────────────────────

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _QuickActionButton(
          icon: Icons.notifications_outlined,
          label: 'Notificações',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Em breve')),
          ),
        ),
        const SizedBox(width: 12),
        _QuickActionButton(
          icon: Icons.edit_outlined,
          label: 'Editar Dados',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Em breve')),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

// ─── Grid de funcionalidades ─────────────────────────────────────────────────

class _FunctionalityGrid extends StatelessWidget {
  const _FunctionalityGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _GridCard(
          icon: Icons.church_outlined,
          label: 'Cadastrar Igreja',
          onTap: () => context.go('/church/create'),// navegação — rota a criar na Fase 4
        ),
        _GridCard(
          icon: Icons.description_outlined,
          label: 'Termos de Uso',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Em breve')),
          ),
        ),
      ],
    );
  }
}

class _GridCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GridCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Botão de logout ─────────────────────────────────────────────────────────

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => ref.read(authProvider.notifier).signOut(),
        icon: const Icon(Icons.logout),
        label: const Text('Sair do aplicativo'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}