import 'package:client/features/church/presentation/screens/edit_church_unit_images_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validatePickedUnitImage accepts supported image under 2 MB', () {
    const image = PickedUnitImage(
      path: '/tmp/foto.png',
      name: 'foto.png',
      sizeInBytes: 1024,
    );

    expect(validatePickedUnitImage(image), isNull);
  });

  test('validatePickedUnitImage rejects image above 2 MB', () {
    const image = PickedUnitImage(
      path: '/tmp/foto.png',
      name: 'foto.png',
      sizeInBytes: unitImageMaxBytes + 1,
    );

    expect(
      validatePickedUnitImage(image),
      'Arquivo muito grande. Envie uma imagem de até 2 MB.',
    );
  });

  test('validatePickedUnitImage rejects unsupported extension', () {
    const image = PickedUnitImage(
      path: '/tmp/documento.pdf',
      name: 'documento.pdf',
      sizeInBytes: 1024,
    );

    expect(
      validatePickedUnitImage(image),
      'Formato inválido. Envie uma imagem JPG, PNG ou WEBP.',
    );
  });
}
