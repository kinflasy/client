import 'package:client/features/church/data/models/church_read_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChurchUnitReadModel.fromJson', () {
    test('parses address as string and optional image aliases', () {
      final model = ChurchUnitReadModel.fromJson({
        'id': 'unit-1',
        'churchId': 'church-1',
        'name': 'Sede Central',
        'slug': 'sede-central',
        'address': 'Rua A, 123',
        'phone': '(11) 99999-0000',
        'email': 'contato@igreja.dev',
        'logo_url': 'https://cdn/logo.png',
        'cover_url': 'https://cdn/cover.png',
      });

      expect(model.address, 'Rua A, 123');
      expect(model.phone, '(11) 99999-0000');
      expect(model.email, 'contato@igreja.dev');
      expect(model.logoUrl, 'https://cdn/logo.png');
      expect(model.coverUrl, 'https://cdn/cover.png');
    });

    test('parses address as object', () {
      final model = ChurchUnitReadModel.fromJson({
        'id': 'unit-1',
        'churchId': 'church-1',
        'address': {
          'street': 'Rua B',
          'number': '45',
          'neighborhood': 'Centro',
          'city': 'Fortaleza',
          'state': 'CE',
        },
      });

      expect(model.address, 'Rua B, 45, Centro, Fortaleza, CE');
    });

    test('keeps image fields null when absent', () {
      final model = ChurchUnitReadModel.fromJson({
        'id': 'unit-1',
        'churchId': 'church-1',
      });

      expect(model.logoUrl, isNull);
      expect(model.coverUrl, isNull);
    });

    test('parses camelCase image aliases', () {
      final model = ChurchUnitReadModel.fromJson({
        'id': 'unit-1',
        'churchId': 'church-1',
        'logoImageUrl': 'https://cdn/logo.png',
        'coverImageUrl': 'https://cdn/cover.png',
      });

      expect(model.logoUrl, 'https://cdn/logo.png');
      expect(model.coverUrl, 'https://cdn/cover.png');
    });
  });
}
