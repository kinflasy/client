import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart' show XFile;

/// Creates a multipart file without relying on `dart:io`.
///
/// On Flutter Web, image picker paths are Blob URLs. Reading them through
/// [XFile] works both there and on native platforms.
Future<MultipartFile> multipartFileFromPath(String filePath) async {
  final bytes = await XFile(filePath).readAsBytes();

  return MultipartFile.fromBytes(
    bytes,
    filename: _resolveFilename(filePath, bytes),
  );
}

String _resolveFilename(String filePath, List<int> bytes) {
  final uri = Uri.tryParse(filePath);
  final path = uri?.path ?? filePath;
  final candidate = path.split('/').last;

  if (_hasSupportedImageExtension(candidate)) {
    return candidate;
  }

  return 'image.${_detectImageExtension(bytes)}';
}

bool _hasSupportedImageExtension(String filename) {
  final lower = filename.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp');
}

String _detectImageExtension(List<int> bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47) {
    return 'png';
  }

  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'jpg';
  }

  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'webp';
  }

  return 'jpg';
}
