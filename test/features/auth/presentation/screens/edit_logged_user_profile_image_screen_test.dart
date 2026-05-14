import 'package:client/features/auth/presentation/screens/edit_logged_user_profile_image_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validatePickedLoggedUserImage', () {
    test('aceita JPG, JPEG, PNG e WEBP', () {
      for (final fileName in [
        'perfil.jpg',
        'perfil.jpeg',
        'perfil.png',
        'perfil.webp',
        'PERFIL.JPG',
        'PERFIL.JPEG',
        'PERFIL.PNG',
        'PERFIL.WEBP',
      ]) {
        final result = validatePickedLoggedUserImage(
          PickedLoggedUserImage(
            path: '/tmp/$fileName',
            name: fileName,
            sizeInBytes: loggedUserImageMaxBytes,
          ),
        );

        expect(result, isNull, reason: '$fileName deveria ser aceito');
      }
    });

    test('rejeita arquivo acima de 2 MB', () {
      final result = validatePickedLoggedUserImage(
        const PickedLoggedUserImage(
          path: '/tmp/perfil.png',
          name: 'perfil.png',
          sizeInBytes: loggedUserImageMaxBytes + 1,
        ),
      );

      expect(result, 'Arquivo muito grande. Envie uma imagem de até 2 MB.');
    });

    test('rejeita extensão inválida', () {
      final result = validatePickedLoggedUserImage(
        const PickedLoggedUserImage(
          path: '/tmp/perfil.gif',
          name: 'perfil.gif',
          sizeInBytes: 1024,
        ),
      );

      expect(result, 'Formato inválido. Envie uma imagem JPG, PNG ou WEBP.');
    });

    test('valida a extensão pelo caminho quando o nome não tem extensão', () {
      final result = validatePickedLoggedUserImage(
        const PickedLoggedUserImage(
          path: '/tmp/cache/perfil.webp',
          name: 'image_picker_temp',
          sizeInBytes: 1024,
        ),
      );

      expect(result, isNull);
    });

    test('valida a extensão pelo nome quando o caminho não tem extensão', () {
      final result = validatePickedLoggedUserImage(
        const PickedLoggedUserImage(
          path: '/tmp/cache/image_picker_temp',
          name: 'perfil.jpeg',
          sizeInBytes: 1024,
        ),
      );

      expect(result, isNull);
    });
  });
}
