import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/presentation/screens/church_shared_widgets.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChurchSearchScreen extends ConsumerStatefulWidget {
  const ChurchSearchScreen({super.key});

  @override
  ConsumerState<ChurchSearchScreen> createState() => _ChurchSearchScreenState();
}

class _ChurchSearchScreenState extends ConsumerState<ChurchSearchScreen> {
  final _controller = TextEditingController();
  String _term = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar por nome, slug ou sigla...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.textSecondary),
          ),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          onChanged: (value) => setState(() => _term = value),
        ),
      ),
      body: _term.trim().length < 2
          ? const _SearchHint()
          : _SearchResults(term: _term.trim()),
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'Digite o nome, slug ou sigla da igreja',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.term});

  final String term;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(churchSearchProvider(term));

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.error),
              const SizedBox(height: 12),
              const Text(
                'Nao foi possivel buscar igrejas.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(churchSearchProvider(term)),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
      data: (churches) {
        if (churches.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.church_outlined,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhuma igreja encontrada para "$term".',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: churches.length,
          separatorBuilder: (_, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _ChurchResultCard(church: churches[index]),
        );
      },
    );
  }
}

class _ChurchResultCard extends ConsumerStatefulWidget {
  const _ChurchResultCard({required this.church});

  final ChurchEntity church;

  @override
  ConsumerState<_ChurchResultCard> createState() => _ChurchResultCardState();
}

class _ChurchResultCardState extends ConsumerState<_ChurchResultCard> {
  bool _isLoading = false;

  Future<void> _openHeadquarterProfile() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final unit = await resolveHeadquarterUnitByChurch(
        churchId: widget.church.id,
        unitRepository: ref.read(churchUnitRepositoryProvider),
      );

      if (!mounted) return;
      context.pushNamed(
        AppRoutes.churchPublicProfileName,
        pathParameters: {'id': unit.id},
      );
    } on Failure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel abrir o perfil dessa igreja.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final church = widget.church;
    final acronymLabel = church.acronym?.trim();
    final subtitle = acronymLabel != null && acronymLabel.isNotEmpty
        ? '@${church.slug} - $acronymLabel'
        : '@${church.slug}';

    return ListTile(
      tileColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8F0FE),
        backgroundImage: church.logoUrl != null
            ? NetworkImage(church.logoUrl!)
            : null,
        child: church.logoUrl == null
            ? Text(
                churchInitials(church.name),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
      title: Text(
        church.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      trailing: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: _isLoading ? null : _openHeadquarterProfile,
    );
  }
}
