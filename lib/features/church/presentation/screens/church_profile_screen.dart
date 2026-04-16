import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/presentation/widgets/church_sidebar.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/domain/entities/current_church_profile_entity.dart';
import 'package:client/features/church/domain/entities/public_church_unit_profile_entity.dart';
import 'package:client/features/church/presentation/widgets/church_profile_cover_header.dart';
import 'package:client/features/church/presentation/widgets/church_profile_identity_card.dart';
import 'package:client/features/church/presentation/widgets/church_profile_tabs.dart';
import 'package:client/features/church/presentation/widgets/church_profile_top_bar.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChurchProfileScreen extends ConsumerWidget {
  const ChurchProfileScreen({super.key, this.unitId});

  final String? unitId;

  bool get _isVisitorMode => unitId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_isVisitorMode) {
      final profileAsync = ref.watch(publicChurchUnitProfileProvider(unitId!));
      return profileAsync.when(
        loading: () => const Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(child: Center(child: CircularProgressIndicator())),
        ),
        error: (error, _) => _ErrorChurchState(
          message: error is Failure
              ? error.message
              : 'Não foi possível carregar a igreja agora.',
          onRetry: () =>
              ref.invalidate(publicChurchUnitProfileProvider(unitId!)),
        ),
        data: (profile) => _VisitorProfileBody(profile: profile),
      );
    }

    final profileAsync = ref.watch(currentChurchProfileProvider);
    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stackTrace) {
        if (error is NotFoundFailure) {
          return const _EmptyChurchState();
        }
        return _ErrorChurchState(
          message: error is Failure
              ? error.message
              : 'Não foi possível carregar a igreja agora.',
          onRetry: () => ref.invalidate(currentChurchProfileProvider),
        );
      },
      data: (profile) => _MemberProfileBody(profile: profile),
    );
  }
}

class _MemberProfileBody extends StatefulWidget {
  const _MemberProfileBody({required this.profile});

  final CurrentChurchProfileEntity profile;

  @override
  State<_MemberProfileBody> createState() => _MemberProfileBodyState();
}

class _MemberProfileBodyState extends State<_MemberProfileBody> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: const ChurchSidebar(),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ChurchProfileCoverHeader(
                  unit: widget.profile.unit,
                  fallbackChurch: widget.profile.church,
                  topBar: ChurchProfileTopBar(
                    onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: ChurchProfileIdentityCard(
                  unit: widget.profile.unit,
                  fallbackChurch: widget.profile.church,
                  onOpenPublicProfile: () => context.pushNamed(
                    AppRoutes.churchPublicProfileName,
                    pathParameters: {'id': widget.profile.unit.id},
                  ),
                ),
              ),
              const SliverPersistentHeader(
                delegate: ChurchProfileTabBarDelegate(),
              ),
              SliverFillRemaining(
                hasScrollBody: true,
                child: ChurchProfileMemberTabView(unitId: widget.profile.unit.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisitorProfileBody extends StatelessWidget {
  const _VisitorProfileBody({required this.profile});

  final PublicChurchUnitProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ChurchProfileCoverHeader(
                  unit: profile.unit,
                  fallbackChurch: profile.church,
                  showBackButton: true,
                ),
              ),
              SliverToBoxAdapter(
                child: ChurchProfileIdentityCard(
                  unit: profile.unit,
                  fallbackChurch: profile.church,
                  onOpenPublicProfile: () => context.pushNamed(
                    AppRoutes.churchPublicProfileName,
                    pathParameters: {'id': profile.unit.id},
                  ),
                ),
              ),
              const SliverPersistentHeader(
                delegate: ChurchProfileTabBarDelegate(isVisitorMode: true),
              ),
              const SliverFillRemaining(
                hasScrollBody: true,
                child: ChurchProfileVisitorTabView(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChurchState extends StatelessWidget {
  const _EmptyChurchState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.church_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Você ainda não participa de nenhuma igreja no app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Você pode procurar uma igreja existente ou cadastrar uma nova se não encontrar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () =>
                      context.pushNamed(AppRoutes.churchSearchName),
                  child: const Text('Buscar Igreja'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () =>
                      context.pushNamed(AppRoutes.registerChurchName),
                  child: const Text('Cadastrar Igreja'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorChurchState extends StatelessWidget {
  const _ErrorChurchState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
