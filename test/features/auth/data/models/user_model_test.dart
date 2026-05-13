import 'package:client/features/auth/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses profileImageId and maps it to entity', () {
    final model = UserModel.fromJson({
      'id': 'user-1',
      'username': 'lisa',
      'fullName': 'Lisa Silva',
      'email': 'lisa@example.com',
      'profileImageId': 'image-123',
    });

    expect(model.profileImageId, 'image-123');

    final entity = model.toEntity();
    expect(entity.profileImageId, 'image-123');
  });
}
