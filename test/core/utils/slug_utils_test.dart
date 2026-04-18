import 'package:client/core/utils/slug_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('slugifyValue removes accents and uses kebab-case', () {
    expect(slugifyValue('Ministério Infantil'), 'ministerio-infantil');
  });

  test('slugifyValue removes invalid symbols', () {
    expect(slugifyValue('Louvor & Adoração!'), 'louvor-and-adoracao');
  });

  test('slugifyValue collapses repeated separators', () {
    expect(slugifyValue('Secretaria   Geral'), 'secretaria-geral');
  });

  test(
    'slugifyValue returns empty string when text has no valid slug chars',
    () {
      expect(slugifyValue('!!!'), isEmpty);
    },
  );
}
