import 'package:client/features/church/data/models/church_link_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChurchLinkReadModel', () {
    test('parses link fields from json', () {
      final model = ChurchLinkReadModel.fromJson({
        'id': 'link-1',
        'label': 'Site',
        'url': 'https://igreja.dev',
      });

      expect(model.id, 'link-1');
      expect(model.label, 'Site');
      expect(model.url, 'https://igreja.dev');
    });

    test('uses empty strings for missing fields', () {
      final model = ChurchLinkReadModel.fromJson({});

      expect(model.id, '');
      expect(model.label, '');
      expect(model.url, '');
    });
  });

  group('ChurchLinkRequestModel', () {
    test('serializes request body', () {
      const model = ChurchLinkRequestModel(
        label: 'Instagram',
        url: 'https://instagram.com/igreja',
      );

      expect(model.toJson(), {
        'label': 'Instagram',
        'url': 'https://instagram.com/igreja',
      });
    });
  });
}
