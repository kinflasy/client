import 'dart:io';

import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/presentation/widgets/action_confirmation_dialog.dart';
import 'package:client/features/auth/providers/edit_logged_user_providers.dart';
import 'package:client/features/church/presentation/widgets/church_shared_widgets.dart';
import 'package:client/features/church/presentation/widgets/church_unit_media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

const loggedUserImageMaxBytes = 2 * 1024 * 1024;

final loggedUserImagePickerProvider = Provider<LoggedUserImagePicker>(
  (ref) => ImagePickerLoggedUserImagePicker(ImagePicker()),
);

class PickedLoggedUserImage {
  const PickedLoggedUserImage({
    required this.path,
    required this.name,
    required this.sizeInBytes,
  });

  final String path;
  final String name;
  final int sizeInBytes;
}

abstract class LoggedUserImagePicker {
  Future<PickedLoggedUserImage?> pickImage();
}

class ImagePickerLoggedUserImagePicker implements LoggedUserImagePicker {
  const ImagePickerLoggedUserImagePicker(this._picker);

  final ImagePicker _picker;

  @override
  Future<PickedLoggedUserImage?> pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    return PickedLoggedUserImage(
      path: image.path,
      name: image.name,
      sizeInBytes: await image.length(),
    );
  }
}

String? validatePickedLoggedUserImage(PickedLoggedUserImage image) {
  if (image.sizeInBytes > loggedUserImageMaxBytes) {
    return 'Arquivo muito grande. Envie uma imagem de até 2 MB.';
  }

  final lowerName = image.name.toLowerCase();
  final lowerPath = image.path.toLowerCase();
  final hasValidExtension = const ['.jpg', '.jpeg', '.png', '.webp'].any((
    extension,
  ) {
    return lowerName.endsWith(extension) || lowerPath.endsWith(extension);
  });

  if (!hasValidExtension) {
    return 'Formato inválido. Envie uma imagem JPG, PNG ou WEBP.';
  }

  return null;
}

class EditLoggedUserProfileImageScreen extends ConsumerStatefulWidget {
  const EditLoggedUserProfileImageScreen({super.key});

  @override
  ConsumerState<EditLoggedUserProfileImageScreen> createState() =>
      _EditLoggedUserProfileImageScreenState();
}

class _EditLoggedUserProfileImageScreenState
    extends ConsumerState<EditLoggedUserProfileImageScreen> {
  File? _preview;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    if (_isSubmitting) return;

    final image = await ref.read(loggedUserImagePickerProvider).pickImage();
    if (image == null) return;

    final validationMessage = validatePickedLoggedUserImage(image);
    if (validationMessage != null) {
      _showErrorToast(validationMessage);
      return;
    }

    setState(() => _preview = File(image.path));
    setState(() => _isSubmitting = true);
    final result = await updateLoggedUserProfileImage(
      ref,
      filePath: image.path,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => _showErrorToast(_failureMessage(failure)),
      (_) => _showSuccessToast('Foto atualizada com sucesso.'),
    );
  }

  Future<void> _confirmRemoveImage() async {
    if (_isSubmitting) return;

    final confirmed = await showActionConfirmationDialog(
      context,
      title: 'Remover foto',
      message: 'Tem certeza que deseja remover sua foto de perfil?',
      confirmLabel: 'Remover',
      isDestructive: true,
    );

    if (!confirmed) return;

    setState(() => _isSubmitting = true);
    final result = await deleteLoggedUserProfileImage(ref);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold((failure) => _showErrorToast(_failureMessage(failure)), (_) {
      setState(() => _preview = null);
      _showSuccessToast('Foto removida com sucesso.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(editLoggedUserInitialDataProvider);
    final submitState = ref.watch(loggedUserProfileImageSubmitProvider);
    final isLoading = submitState.isLoading || _isSubmitting;

    return _ScaffoldFrame(
      title: 'Editar foto',
      child: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LoadError(
          message: error is Failure
              ? error.message
              : 'Não foi possível carregar sua foto agora.',
          onRetry: () => ref.invalidate(editLoggedUserInitialDataProvider),
        ),
        data: (profile) {
          final hasImage =
              _preview != null ||
              (profile.profileImageId?.trim().isNotEmpty ?? false);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _ImageSection(
                imageId: profile.profileImageId,
                preview: _preview,
                isLoading: isLoading,
                canRemove: hasImage,
                onChange: _pickImage,
                onRemove: _confirmRemoveImage,
              ),
            ],
          );
        },
      ),
    );
  }

  String _failureMessage(Object failure) {
    if (failure is Failure) return failure.message;
    return failure.toString();
  }

  void _showSuccessToast(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  void _showErrorToast(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 4),
    );
  }
}

class _ScaffoldFrame extends StatelessWidget {
  const _ScaffoldFrame({required this.title, required this.child});

  final String title;
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      title,
                      style: const TextStyle(
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

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.imageId,
    required this.preview,
    required this.isLoading,
    required this.canRemove,
    required this.onChange,
    required this.onRemove,
  });

  final String? imageId;
  final File? preview;
  final bool isLoading;
  final bool canRemove;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Foto de perfil',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Usada no seu perfil, no menu e no topo do app.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          Center(
            child: UnitImagePreview(
              imageId: imageId,
              preview: preview,
              height: 160,
              isRound: true,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: isLoading ? null : onChange,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Alterar foto'),
              ),
              OutlinedButton.icon(
                onPressed: isLoading || !canRemove ? null : onRemove,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remover'),
              ),
            ],
          ),
          if (isLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
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
