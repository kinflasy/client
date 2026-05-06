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
      expect(model.addressValue, isNull);
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
          'zip': '60000-000',
          'country': 'Brasil',
          'street': 'Rua B',
          'number': '45',
          'neighborhood': 'Centro',
          'city': 'Fortaleza',
          'state': 'CE',
          'complement': 'Sala 2',
          'reference': 'Perto da praca',
        },
      });

      expect(
        model.address,
        'Rua B, 45, Centro, Fortaleza, CE, Brasil | Sala 2 - Perto da praca - 60000-000',
      );
      expect(model.addressValue?.zip, '60000-000');
      expect(model.addressValue?.country, 'Brasil');
      expect(model.addressValue?.street, 'Rua B');
      expect(model.addressValue?.number, '45');
      expect(model.addressValue?.neighborhood, 'Centro');
      expect(model.addressValue?.city, 'Fortaleza');
      expect(model.addressValue?.state, 'CE');
      expect(model.addressValue?.complement, 'Sala 2');
      expect(model.addressValue?.reference, 'Perto da praca');
    });

    test('ignores blank structured address fields', () {
      final model = ChurchUnitReadModel.fromJson({
        'id': 'unit-1',
        'churchId': 'church-1',
        'address': {
          'zip': ' ',
          'street': '',
          'city': '  Fortaleza  ',
          'state': 'CE',
        },
      });

      expect(model.address, 'Fortaleza, CE');
      expect(model.addressValue?.zip, isNull);
      expect(model.addressValue?.street, isNull);
      expect(model.addressValue?.city, 'Fortaleza');
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

    test('builds media download URLs from image ids', () {
      final model = ChurchUnitReadModel.fromJson({
        'id': 'unit-1',
        'churchId': 'church-1',
        'profileImageId': 'profile-123',
        'coverImageId': 'cover-456',
      });

      expect(
        model.logoUrl,
        'https://app-production-647c.up.railway.app/v1/media/profile-123/download',
      );
      expect(
        model.coverUrl,
        'https://app-production-647c.up.railway.app/v1/media/cover-456/download',
      );
    });

    test('keeps direct image URLs when ids are also present', () {
      final model = ChurchUnitReadModel.fromJson({
        'id': 'unit-1',
        'churchId': 'church-1',
        'logoUrl': 'https://cdn/logo.png',
        'coverUrl': 'https://cdn/cover.png',
        'profileImageId': 'profile-123',
        'coverImageId': 'cover-456',
      });

      expect(model.logoUrl, 'https://cdn/logo.png');
      expect(model.coverUrl, 'https://cdn/cover.png');
    });
  });
}
