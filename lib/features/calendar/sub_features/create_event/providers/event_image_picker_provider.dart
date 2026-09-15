import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

const eventImageMaxBytes = 2 * 1024 * 1024;

final eventImagePickerProvider = Provider<EventImagePicker>(
  (ref) => ImagePickerEventImagePicker(ImagePicker()),
);

class PickedEventImage {
  const PickedEventImage({
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

abstract class EventImagePicker {
  Future<PickedEventImage?> pickImage();
}

class ImagePickerEventImagePicker implements EventImagePicker {
  const ImagePickerEventImagePicker(this._picker);

  final ImagePicker _picker;

  @override
  Future<PickedEventImage?> pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final bytes = await image.readAsBytes();
    return PickedEventImage(
      path: image.path,
      name: image.name,
      sizeInBytes: bytes.length,
      bytes: bytes,
    );
  }
}

String? validatePickedEventImage(PickedEventImage image) {
  if (image.sizeInBytes > eventImageMaxBytes) {
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
