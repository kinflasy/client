import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/public_church_unit_profile_entity.dart';
import 'package:client/features/church/presentation/screens/church_shared_widgets.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ChurchInfoProfileScreen extends ConsumerWidget {
  const ChurchInfoProfileScreen({super.key, required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicChurchUnitProfileProvider(unitId));

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _ErrorState(
        message: 'Não foi possível carregar o perfil da igreja.',
        onRetry: () => ref.invalidate(publicChurchUnitProfileProvider(unitId)),
      ),
      data: (profile) => _ProfileContent(profile: profile),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final PublicChurchUnitProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _ChurchCoverHeader(
                unit: profile.unit,
                fallbackChurch: profile.church,
              ),
            ),
            SliverToBoxAdapter(
              child: _IdentitySection(
                unit: profile.unit,
                fallbackChurch: profile.church,
              ),
            ),
            const SliverToBoxAdapter(
              child: Divider(height: 1, color: AppColors.background),
            ),
            SliverToBoxAdapter(child: _InfoSection(unit: profile.unit)),
            SliverToBoxAdapter(child: _AffiliationSection(profile: profile)),
          ],
        ),
      ),
    );
  }
}

class _ChurchCoverHeader extends StatelessWidget {
  const _ChurchCoverHeader({required this.unit, required this.fallbackChurch});

  final ChurchUnitEntity unit;
  final ChurchEntity fallbackChurch;

  @override
  Widget build(BuildContext context) {
    final coverUrl = unit.coverUrl ?? fallbackChurch.coverUrl;
    final logoUrl = unit.logoUrl ?? fallbackChurch.logoUrl;
    final displayName = _displayName(unit, fallbackChurch);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 168,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F4C81), AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: coverUrl == null
              ? const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x22000000), Color(0x00000000)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                )
              : Image.network(
                  coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, exception, stackTrace) =>
                      const SizedBox.shrink(),
                ),
        ),
        Positioned(
          bottom: -58,
          child: CircleAvatar(
            radius: 64,
            backgroundColor: AppColors.surface,
            child: CircleAvatar(
              radius: 58,
              backgroundColor: const Color(0xFFE8F0FE),
              backgroundImage: logoUrl != null ? NetworkImage(logoUrl) : null,
              child: logoUrl == null
                  ? Text(
                      churchInitials(displayName),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const ChurchFloatingBackButton(),
      ],
    );
  }
}

class _IdentitySection extends StatelessWidget {
  const _IdentitySection({required this.unit, required this.fallbackChurch});

  final ChurchUnitEntity unit;
  final ChurchEntity fallbackChurch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 70, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _displayName(unit, fallbackChurch),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${_displaySlug(unit, fallbackChurch)}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.unit});

  final ChurchUnitEntity unit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informações',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (unit.address != null)
            _InfoRow(
              icon: Icons.location_on_outlined,
              value: unit.address!,
              onTap: () => _launchMaps(unit.address!),
            ),
          if (unit.phone != null) _PhoneInfoRow(phone: unit.phone!),
          if (unit.email != null)
            _InfoRow(
              icon: Icons.mail_outline,
              value: unit.email!,
              onTap: () => _launchEmail(unit.email!),
            ),
        ],
      ),
    );
  }

  Future<void> _launchMaps(String address) async {
    final uri = Uri.parse(
      'https://maps.google.com/?q=${Uri.encodeComponent(address)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.value, this.onTap});

  final IconData icon;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: onTap != null
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneInfoRow extends StatefulWidget {
  const _PhoneInfoRow({required this.phone});

  final String phone;

  @override
  State<_PhoneInfoRow> createState() => _PhoneInfoRowState();
}

class _PhoneInfoRowState extends State<_PhoneInfoRow> {
  bool _expanded = false;

  List<String> get _numbers => widget.phone
      .split(',')
      .map((n) => n.trim())
      .where((n) => n.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final numbers = _numbers;
    final hasMultiple = numbers.length > 1;

    return Column(
      children: [
        InkWell(
          onTap: hasMultiple
              ? () => setState(() => _expanded = !_expanded)
              : () => _launchPhone(numbers.first),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.call_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    numbers.first,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (hasMultiple)
                  Icon(
                    _expanded ? Icons.expand_less : Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: numbers
                .skip(1)
                .map(
                  (n) => _InfoRow(
                    icon: Icons.call_outlined,
                    value: n,
                    onTap: () => _launchPhone(n),
                  ),
                )
                .toList(),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
      ],
    );
  }

  Future<void> _launchPhone(String number) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _AffiliationSection extends StatelessWidget {
  const _AffiliationSection({required this.profile});

  final PublicChurchUnitProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final isMain = profile.unit.type == 'MAIN';
    final headquarter = _findHeadquarter(profile);
    final relatedBranches = profile.relatedUnits
        .where((unit) => unit.id != profile.unit.id && unit.type == 'BRANCH')
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: AppColors.background),
          const SizedBox(height: 12),
          const Text(
            'Filiação',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (isMain) ...[
            _affiliationBadge(label: 'Sede da rede', icon: Icons.home_outlined),
            if (relatedBranches.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Unidades da rede',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...relatedBranches.map(
                (unit) => _AffiliationLinkTile(
                  label: _displayName(unit, profile.church),
                  onTap: () => context.pushNamed(
                    AppRoutes.churchPublicProfileName,
                    pathParameters: {'id': unit.id},
                  ),
                ),
              ),
            ],
          ] else if (headquarter != null) ...[
            _affiliationBadge(
              label:
                  'Pertence à rede ${_displayName(headquarter, profile.church)}',
              icon: Icons.account_balance_outlined,
            ),
            const SizedBox(height: 8),
            _AffiliationLinkTile(
              label: 'Ver unidade sede',
              onTap: () => context.pushNamed(
                AppRoutes.churchPublicProfileName,
                pathParameters: {'id': headquarter.id},
              ),
            ),
          ] else
            const Text(
              'Sem filiação registrada',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  ChurchUnitEntity? _findHeadquarter(PublicChurchUnitProfileEntity profile) {
    for (final unit in profile.relatedUnits) {
      if (unit.type == 'MAIN') return unit;
    }
    return null;
  }

  Widget _affiliationBadge({required String label, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AffiliationLinkTile extends StatelessWidget {
  const _AffiliationLinkTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.account_tree_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface, elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _displayName(ChurchUnitEntity unit, ChurchEntity fallbackChurch) {
  final name = unit.name?.trim();
  if (name != null && name.isNotEmpty) return name;
  return fallbackChurch.name;
}

String _displaySlug(ChurchUnitEntity unit, ChurchEntity fallbackChurch) {
  final slug = unit.slug?.trim();
  if (slug != null && slug.isNotEmpty) return slug;
  return fallbackChurch.slug;
}
