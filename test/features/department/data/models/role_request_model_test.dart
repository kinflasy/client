import 'package:client/features/department/data/models/role_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes role name only', () {
    const model = RoleRequestModel(name: 'Vocal');

    expect(model.toJson(), {'name': 'Vocal'});
  });
}
