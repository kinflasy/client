import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MemberOptionsScreen extends StatelessWidget {
  const MemberOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Membros'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _AddMemberItem(),
          SizedBox(height: 12),
          _MemberOptionItem(
            icon: Icons.people_outline,
            title: 'Ver Membros',
            subtitle: 'Visualize todos os membros da sua igreja.',
          ),
          SizedBox(height: 12),
          _MemberOptionItem(
            icon: Icons.link,
            title: 'Solicitações de vínculo',
            subtitle: 'Gerencie pedidos de entrada na sua unidade.',
          ),
          SizedBox(height: 12),
          _MemberOptionItem(
            icon: Icons.history,
            title: 'Membros anteriores',
            subtitle: 'Consulte o histórico de membros desvinculados.',
          ),
        ],
      ),
    );
  }
}

class _MemberOptionItem extends StatelessWidget {
  const _MemberOptionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE8F0FE),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _AddMemberItem extends StatefulWidget {
  const _AddMemberItem();

  @override
  State<_AddMemberItem> createState() => _AddMemberItemState();
}

class _AddMemberItemState extends State<_AddMemberItem> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      menuChildren: [
        const MenuItemButton(
          child: Text('Usuário do Pontis'),
        ),
        MenuItemButton(
          onPressed: () => context.push(AppRoutes.adminMembersRegister),
          child: const Text('Pessoa sem conta'),
        ),
      ],
      child: _MemberOptionItem(
        icon: Icons.person_add_outlined,
        title: 'Adicionar membro',
        subtitle: 'Vincule um novo membro à sua unidade.',
        onTap: () {
          if (_menuController.isOpen) {
            _menuController.close();
            return;
          }
          _menuController.open();
        },
      ),
    );
  }
}
