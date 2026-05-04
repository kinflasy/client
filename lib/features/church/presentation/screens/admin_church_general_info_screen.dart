import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/domain/entities/church_link_entity.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/current_church_profile_entity.dart';
import 'package:client/features/church/providers/church_general_info_providers.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminChurchGeneralInfoScreen extends ConsumerWidget {
  const AdminChurchGeneralInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentChurchProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Informações gerais'),
        backgroundColor: AppColors.surface,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _LoadError(
          onRetry: () => ref.invalidate(currentChurchProfileProvider),
        ),
        data: (profile) => _GeneralInfoContent(profile: profile),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Erro ao carregar informações',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _GeneralInfoContent extends ConsumerWidget {
  const _GeneralInfoContent({required this.profile});

  final CurrentChurchProfileEntity profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(unitLinksProvider(profile.unit.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoBlock(
          title: 'Capa',
          icon: Icons.image_outlined,
          onEdit: () {
            // TODO: navigate to edit cover/logo
          },
          child: _CoverPreview(unit: profile.unit, church: profile.church),
        ),
        const SizedBox(height: 16),
        _InfoBlock(
          title: 'Identidade',
          icon: Icons.badge_outlined,
          onEdit: () {
            context.pushNamed(AppRoutes.adminGeneralInfoIdentityEditName);
          },
          child: _IdentityPreview(
            unit: profile.unit,
            fallbackChurch: profile.church,
          ),
        ),
        const SizedBox(height: 16),
        _InfoBlock(
          title: 'Endereço',
          icon: Icons.location_on_outlined,
          onEdit: () {
            context.pushNamed(AppRoutes.adminGeneralInfoAddressEditName);
          },
          child: _AddressPreview(unit: profile.unit),
        ),
        const SizedBox(height: 16),
        _InfoBlock(
          title: 'Links externos',
          icon: Icons.link_outlined,
          onEdit: () {
            context.pushNamed(AppRoutes.adminGeneralInfoLinksName);
          },
          child: _LinksPreview(
            linksAsync: linksAsync,
            onRetry: () => ref.invalidate(unitLinksProvider(profile.unit.id)),
          ),
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.child,
  });

  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.primary,
                  onPressed: onEdit,
                  tooltip: 'Editar $title',
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.unit, required this.church});

  final ChurchUnitEntity unit;
  final ChurchEntity church;

  @override
  Widget build(BuildContext context) {
    final coverUrl = unit.coverUrl ?? church.coverUrl;
    final logoUrl = unit.logoUrl ?? church.logoUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (coverUrl != null)
          Text(
            'Capa: definida',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          )
        else
          Text(
            'Capa: não definida',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        const SizedBox(height: 8),
        if (logoUrl != null)
          Text(
            'Logo: definida',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          )
        else
          Text(
            'Logo: não definida',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
      ],
    );
  }
}

class _IdentityPreview extends StatelessWidget {
  const _IdentityPreview({required this.unit, required this.fallbackChurch});

  final ChurchUnitEntity unit;
  final ChurchEntity fallbackChurch;

  @override
  Widget build(BuildContext context) {
    final name = unit.name?.trim();
    final slug = unit.slug?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PreviewRow(
          label: 'Nome',
          value: (name != null && name.isNotEmpty) ? name : fallbackChurch.name,
        ),
        const SizedBox(height: 8),
        _PreviewRow(
          label: 'Slug',
          value: (slug != null && slug.isNotEmpty) ? slug : fallbackChurch.slug,
        ),
        if (unit.phone != null) ...[
          const SizedBox(height: 8),
          _PreviewRow(label: 'Telefone', value: unit.phone!),
        ],
        if (unit.email != null) ...[
          const SizedBox(height: 8),
          _PreviewRow(label: 'E-mail', value: unit.email!),
        ],
      ],
    );
  }
}

class _AddressPreview extends StatelessWidget {
  const _AddressPreview({required this.unit});

  final ChurchUnitEntity unit;

  @override
  Widget build(BuildContext context) {
    final address = unit.address;
    if (address == null || address.isEmpty) {
      return Text(
        'Nenhum endereço cadastrado.',
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      );
    }

    return Text(
      address,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
    );
  }
}

class _LinksPreview extends StatelessWidget {
  const _LinksPreview({required this.linksAsync, required this.onRetry});

  final AsyncValue<List<ChurchLinkEntity>> linksAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return linksAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stackTrace) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Erro ao carregar links.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
      data: (links) {
        if (links.isEmpty) {
          return const Text(
            'Nenhum link cadastrado.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          );
        }

        final visibleLinks = links.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < visibleLinks.length; index++) ...[
              if (index > 0) const SizedBox(height: 12),
              _LinkPreviewItem(link: visibleLinks[index]),
            ],
          ],
        );
      },
    );
  }
}

class _LinkPreviewItem extends StatelessWidget {
  const _LinkPreviewItem({required this.link});

  final ChurchLinkEntity link;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          link.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          link.url,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
