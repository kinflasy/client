import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/presentation/forms/app_form_formatters.dart';
import 'package:client/core/presentation/widgets/user_avatar.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/auth/domain/entities/logged_user_profile_entity.dart';
import 'package:client/features/auth/providers/edit_logged_user_providers.dart';
import 'package:client/features/church/presentation/widgets/church_shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoggedUserProfileScreen extends ConsumerWidget {
  const LoggedUserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(editLoggedUserInitialDataProvider);

    return profileAsync.when(
      loading: () => const _ProfileFrame(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _ProfileFrame(
        child: _LoadError(
          message: error is Failure
              ? error.message
              : 'Não foi possível carregar seu perfil agora.',
          onRetry: () => ref.invalidate(editLoggedUserInitialDataProvider),
        ),
      ),
      data: (profile) =>
          _ProfileFrame(child: _ProfileContent(profile: profile)),
    );
  }
}

class _ProfileFrame extends StatelessWidget {
  const _ProfileFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      'Meu perfil',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
            const ChurchFloatingBackButton(),
          ],
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final LoggedUserProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName(profile);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Center(
          child: Column(
            children: [
              UserAvatar(
                displayName: displayName,
                radius: 48,
                profileImageId: profile.profileImageId,
              ),
              const SizedBox(height: 14),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_hasText(profile.nickname) &&
                  profile.nickname!.trim() != displayName) ...[
                const SizedBox(height: 4),
                Text(
                  profile.nickname!.trim(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        _ActionButton(
          icon: Icons.edit_outlined,
          label: 'Editar dados pessoais',
          onPressed: () =>
              context.pushNamed(AppRoutes.homeMenuEditProfileInfoName),
        ),
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.location_on_outlined,
          label: 'Editar endereço',
          onPressed: () =>
              context.pushNamed(AppRoutes.homeMenuEditProfileAddressName),
        ),
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.photo_camera_outlined,
          label: 'Editar foto',
          onPressed: () =>
              context.pushNamed(AppRoutes.homeMenuEditProfilePhotoName),
        ),
        const SizedBox(height: 24),
        _Section(
          title: 'Dados pessoais',
          children: [
            _InfoRow(
              label: 'Nome completo',
              value: _fallback(profile.fullName),
            ),
            _InfoRow(label: 'Apelido', value: _fallback(profile.nickname)),
            _InfoRow(label: 'Gênero', value: _formatGender(profile.gender)),
            _InfoRow(
              label: 'Data de nascimento',
              value: _fallback(formatBrazilianDate(profile.birthDate)),
            ),
            _InfoRow(
              label: 'Telefone',
              value: _fallback(formatBrazilianPhone(profile.phone ?? '')),
            ),
            _InfoRow(label: 'E-mail', value: _fallback(profile.email)),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Endereço',
          children: [
            _InfoRow(
              label: 'Endereço',
              value: profile.address.format() ?? 'Endereço não informado',
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}

class LoggedUserProfilePhotoPlaceholderScreen extends StatelessWidget {
  const LoggedUserProfilePhotoPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfileFrame(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Edição de foto em preparação.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

String _displayName(LoggedUserProfileEntity profile) {
  if (_hasText(profile.fullName)) return profile.fullName.trim();
  if (_hasText(profile.nickname)) return profile.nickname!.trim();
  return 'Usuário';
}

String _formatGender(String gender) {
  return switch (gender.trim().toUpperCase()) {
    'MALE' => 'Masculino',
    'FEMALE' => 'Feminino',
    _ => 'Não informado',
  };
}

String _fallback(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? 'Não informado' : trimmed;
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
