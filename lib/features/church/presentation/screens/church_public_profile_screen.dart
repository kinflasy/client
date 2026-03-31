import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class ChurchPublicProfileScreen extends ConsumerWidget {
  const ChurchPublicProfileScreen({super.key, required this.churchId});
  final String churchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final churchAsync = ref.watch(publicChurchProfileProvider(churchId));

    return churchAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _ErrorState(
        message: 'Não foi possível carregar o perfil da igreja.',
        onRetry: () => ref.invalidate(publicChurchProfileProvider(churchId)),
      ),
      data: (church) => _ProfileContent(church: church),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.church});
  final ChurchEntity church;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _ChurchCoverHeader(church: church)),
            SliverToBoxAdapter(child: _IdentitySection(church: church)),
            const SliverToBoxAdapter(child: Divider(height: 1, color: AppColors.background)),
            SliverToBoxAdapter(child: _InfoSection(church: church)),
            if (_hasLinks(church))
              SliverToBoxAdapter(child: _LinksSection(church: church)),
            if (_hasAffiliation(church))
              SliverToBoxAdapter(child: _AffiliationSection(church: church)),
          ],
        ),
      ),
    );
  }

  bool _hasLinks(ChurchEntity c) =>
      c.instagramUrl != null ||
      c.youtubeUrl != null ||
      c.spotifyUrl != null ||
      c.whatsappNumber != null ||
      c.website != null;

  bool _hasAffiliation(ChurchEntity c) =>
      c.isHeadquarters != null || c.parentChurchId != null;
}

class _ChurchCoverHeader extends StatelessWidget {
  const _ChurchCoverHeader({required this.church});
  final ChurchEntity church;

  @override
  Widget build(BuildContext context) {
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
          child: church.coverUrl == null
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
                  church.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, exception, stackTrace) => const SizedBox.shrink(),
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
              backgroundImage: church.logoUrl != null ? NetworkImage(church.logoUrl!) : null,
              child: church.logoUrl == null
                  ? Text(
                      _churchInitials(church.name),
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
      ],
    );
  }

  String _churchInitials(String name) {
    return name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .take(2)
        .join();
  }
}

class _IdentitySection extends StatelessWidget {
  const _IdentitySection({required this.church});
  final ChurchEntity church;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 70, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            church.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${church.slug}',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.church});
  final ChurchEntity church;

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
          if (church.address != null)
            _InfoRow(
              icon: Icons.location_on_outlined,
              value: church.address!,
              onTap: () => _launchMaps(church.address!),
            ),
          if (church.phone != null)
            _PhoneInfoRow(phone: church.phone!),
          _InfoRow(
            icon: Icons.mail_outline,
            value: church.email,
            onTap: () => _launchEmail(church.email),
          ),
        ],
      ),
    );
  }

  Future<void> _launchMaps(String address) async {
    final uri = Uri.parse('https://maps.google.com/?q=${Uri.encodeComponent(address)}');
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
  const _InfoRow({
    required this.icon,
    required this.value,
    this.onTap,
  });
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
                  color: onTap != null ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de telefone — preparado para múltiplos números no futuro.
class _PhoneInfoRow extends StatefulWidget {
  const _PhoneInfoRow({required this.phone});
  final String phone;

  @override
  State<_PhoneInfoRow> createState() => _PhoneInfoRowState();
}

class _PhoneInfoRowState extends State<_PhoneInfoRow> {
  bool _expanded = false;

  List<String> get _numbers =>
      widget.phone.split(',').map((n) => n.trim()).where((n) => n.isNotEmpty).toList();

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
                const Icon(Icons.call_outlined, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    numbers.first,
                    style: const TextStyle(fontSize: 15, color: AppColors.primary),
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
            children: numbers.skip(1).map((n) => _InfoRow(
              icon: Icons.call_outlined,
              value: n,
              onTap: () => _launchPhone(n),
            )).toList(),
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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

class _LinksSection extends StatelessWidget {
  const _LinksSection({required this.church});
  final ChurchEntity church;

  @override
  Widget build(BuildContext context) {
    // TODO: implementar quando o backend expuser os campos
    return const SizedBox.shrink();
  }
}

class _AffiliationSection extends StatelessWidget {
  const _AffiliationSection({required this.church});
  final ChurchEntity church;

  @override
  Widget build(BuildContext context) {
    // TODO: implementar quando o backend expuser os campos
    return const SizedBox.shrink();
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
              ElevatedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      ),
    );
  }
}
