import 'dart:typed_data';

import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/presentation/widgets/action_confirmation_dialog.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/presentation/widgets/church_unit_media.dart';
import 'package:client/features/church/providers/church_general_info_providers.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

const unitImageMaxBytes = 2 * 1024 * 1024;

final churchUnitImagePickerProvider = Provider<ChurchUnitImagePicker>(
  (ref) => ImagePickerChurchUnitImagePicker(ImagePicker()),
);

class PickedUnitImage {
  const PickedUnitImage({
    required this.path,
    required this.name,
    required this.sizeInBytes,
    this.bytes,
  });

  final String path;
  final String name;
  final int sizeInBytes;
  final Uint8List? bytes;
}

abstract class ChurchUnitImagePicker {
  Future<PickedUnitImage?> pickImage();
}

class ImagePickerChurchUnitImagePicker implements ChurchUnitImagePicker {
  const ImagePickerChurchUnitImagePicker(this._picker);

  final ImagePicker _picker;

  @override
  Future<PickedUnitImage?> pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final bytes = await image.readAsBytes();
    return PickedUnitImage(
      path: image.path,
      name: image.name,
      sizeInBytes: bytes.length,
      bytes: bytes,
    );
  }
}

String? validatePickedUnitImage(PickedUnitImage image) {
  if (image.sizeInBytes > unitImageMaxBytes) {
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

class EditChurchUnitImagesScreen extends ConsumerStatefulWidget {
  const EditChurchUnitImagesScreen({super.key});

  @override
  ConsumerState<EditChurchUnitImagesScreen> createState() =>
      _EditChurchUnitImagesScreenState();
}

class _EditChurchUnitImagesScreenState
    extends ConsumerState<EditChurchUnitImagesScreen> {
  Uint8List? _profilePreview;
  Uint8List? _coverPreview;

  Future<void> _pickProfileImage() async {
    await _pickAndSubmitImage(
      onSelected: (image) => setState(() => _profilePreview = image.bytes),
      submit: (image) => ref
          .read(churchGeneralInfoActionsProvider)
          .updateActiveUnitProfileImage(image.path),
      successMessage: 'Foto atualizada com sucesso.',
    );
  }

  Future<void> _pickCoverImage() async {
    await _pickAndSubmitImage(
      onSelected: (image) => setState(() => _coverPreview = image.bytes),
      submit: (image) => ref
          .read(churchGeneralInfoActionsProvider)
          .updateActiveUnitCoverImage(image.path),
      successMessage: 'Capa atualizada com sucesso.',
    );
  }

  Future<void> _pickAndSubmitImage({
    required void Function(PickedUnitImage image) onSelected,
    required Future<Either<Failure, ChurchUnitEntity>> Function(
      PickedUnitImage image,
    )
    submit,
    required String successMessage,
  }) async {
    final image = await ref.read(churchUnitImagePickerProvider).pickImage();
    if (image == null) return;

    final validationMessage = validatePickedUnitImage(image);
    if (validationMessage != null) {
      _showErrorToast(validationMessage);
      return;
    }

    onSelected(image);
    final result = await submit(image);
    result.fold(
      (failure) => _showErrorToast(_failureMessage(failure)),
      (_) => _showSuccessToast(successMessage),
    );
  }

  Future<void> _confirmDeleteProfileImage() async {
    await _confirmAndDelete(
      title: 'Remover foto',
      message: 'Tem certeza que deseja remover a foto da unidade?',
      action: () => ref
          .read(churchGeneralInfoActionsProvider)
          .deleteActiveUnitProfileImage(),
      onSuccess: () {
        setState(() => _profilePreview = null);
        _showSuccessToast('Foto removida.');
      },
    );
  }

  Future<void> _confirmDeleteCoverImage() async {
    await _confirmAndDelete(
      title: 'Remover capa',
      message: 'Tem certeza que deseja remover a capa da unidade?',
      action: () => ref
          .read(churchGeneralInfoActionsProvider)
          .deleteActiveUnitCoverImage(),
      onSuccess: () {
        setState(() => _coverPreview = null);
        _showSuccessToast('Capa removida.');
      },
    );
  }

  Future<void> _confirmAndDelete({
    required String title,
    required String message,
    required Future<Either<Failure, void>> Function() action,
    required VoidCallback onSuccess,
  }) async {
    final confirmed = await showActionConfirmationDialog(
      context,
      title: title,
      message: message,
      confirmLabel: 'Remover',
      isDestructive: true,
    );

    if (!confirmed) return;

    final result = await action();
    result.fold((failure) => _showErrorToast(_failureMessage(failure)), (_) {
      onSuccess();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentChurchProfileProvider);
    final submitState = ref.watch(unitImageSubmitProvider);
    final isLoading = submitState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Imagens da unidade'),
        backgroundColor: AppColors.surface,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _LoadError(
          onRetry: () => ref.invalidate(currentChurchProfileProvider),
        ),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ImageSection(
              title: 'Foto de perfil',
              subtitle: 'Usada no avatar da unidade.',
              imageId: profile.unit.profileImageId,
              imageUrl: profile.unit.logoUrl ?? profile.church.logoUrl,
              previewBytes: _profilePreview,
              height: 160,
              isRound: true,
              isLoading: isLoading,
              onChange: _pickProfileImage,
              onRemove: _confirmDeleteProfileImage,
            ),
            const SizedBox(height: 16),
            _ImageSection(
              title: 'Capa',
              subtitle: 'Usada no topo dos perfis da unidade.',
              imageId: profile.unit.coverImageId,
              imageUrl: profile.unit.coverUrl ?? profile.church.coverUrl,
              previewBytes: _coverPreview,
              height: 180,
              isLoading: isLoading,
              onChange: _pickCoverImage,
              onRemove: _confirmDeleteCoverImage,
            ),
          ],
        ),
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

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.title,
    required this.subtitle,
    required this.imageId,
    required this.imageUrl,
    required this.previewBytes,
    required this.height,
    required this.isLoading,
    required this.onChange,
    required this.onRemove,
    this.isRound = false,
  });

  final String title;
  final String subtitle;
  final String? imageId;
  final String? imageUrl;
  final Uint8List? previewBytes;
  final double height;
  final bool isLoading;
  final VoidCallback onChange;
  final VoidCallback onRemove;
  final bool isRound;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: UnitImagePreview(
              imageId: imageId,
              imageUrl: imageUrl,
              previewBytes: previewBytes,
              height: height,
              isRound: isRound,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: isLoading ? null : onChange,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(isRound ? 'Alterar foto' : 'Alterar capa'),
              ),
              OutlinedButton.icon(
                onPressed: isLoading ? null : onRemove,
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
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Erro ao carregar imagens.'),
          const SizedBox(height: 12),
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
