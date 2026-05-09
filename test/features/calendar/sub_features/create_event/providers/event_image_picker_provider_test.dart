import 'package:client/features/calendar/sub_features/create_event/providers/event_image_picker_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validatePickedEventImage aceita imagem suportada menor que 2 MB', () {
    const image = PickedEventImage(
      path: '/tmp/card.png',
      name: 'card.png',
      sizeInBytes: 1024,
    );

    expect(validatePickedEventImage(image), isNull);
  });

  test('validatePickedEventImage rejeita imagem maior que 2 MB', () {
    const image = PickedEventImage(
      path: '/tmp/card.png',
      name: 'card.png',
      sizeInBytes: eventImageMaxBytes + 1,
    );

    expect(
      validatePickedEventImage(image),
      'Arquivo muito grande. Envie uma imagem de até 2 MB.',
    );
  });

  test('validatePickedEventImage rejeita extensão inválida', () {
    const image = PickedEventImage(
      path: '/tmp/documento.pdf',
      name: 'documento.pdf',
      sizeInBytes: 1024,
    );

    expect(
      validatePickedEventImage(image),
      'Formato inválido. Envie uma imagem JPG, PNG ou WEBP.',
    );
  });
}
