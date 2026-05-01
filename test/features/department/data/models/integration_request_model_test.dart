import 'package:client/features/department/data/models/integration_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes membership id and default integrant type', () {
    const model = IntegrationRequestModel(membershipId: 'membership-1');

    expect(model.toJson(), {
      'membershipId': 'membership-1',
      'type': 'INTEGRANT',
    });
  });
}
