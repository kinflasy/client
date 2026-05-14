import 'package:client/features/auth/data/models/logged_user_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> profileJson({Map<String, dynamic>? extra}) {
    return {
      'id': 'user-1',
      'fullName': 'Lisa Silva',
      'gender': 'FEMALE',
      ...?extra,
    };
  }

  test('parses camelCase profileImageId and maps it to entity', () {
    final model = LoggedUserProfileModel.fromJson(
      profileJson(extra: {'profileImageId': 'image-123'}),
    );

    expect(model.profileImageId, 'image-123');
    expect(model.toEntity().profileImageId, 'image-123');
  });

  test('parses snake_case profile_image_id and maps it to entity', () {
    final model = LoggedUserProfileModel.fromJson(
      profileJson(extra: {'profile_image_id': 'image-456'}),
    );

    expect(model.profileImageId, 'image-456');
    expect(model.toEntity().profileImageId, 'image-456');
  });

  test('parses snake_case person fields', () {
    final model = LoggedUserProfileModel.fromJson(
      profileJson(
        extra: {
          'fullName': null,
          'full_name': 'Lisa Silva',
          'birth_date': '1998-04-09',
          'address_id': 'address-123',
        },
      ),
    );

    expect(model.fullName, 'Lisa Silva');
    expect(model.birthDate, DateTime(1998, 4, 9));
    expect(model.addressId, 'address-123');
  });
}
