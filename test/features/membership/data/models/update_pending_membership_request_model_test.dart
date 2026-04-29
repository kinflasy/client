import 'package:client/features/membership/data/models/update_pending_membership_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes required fields only when optional fields are absent', () {
    const model = UpdatePendingMembershipRequestModel(
      personId: 'person-1',
      affiliation: 'MEMBER',
    );

    expect(model.toJson(), {'personId': 'person-1', 'affiliation': 'MEMBER'});
  });

  test('serializes optional fields when present', () {
    const model = UpdatePendingMembershipRequestModel(
      personId: 'person-1',
      affiliation: 'CONGREGATED',
      entryMode: 'TRANSFER',
      entryDate: '2026-04-28',
    );

    expect(model.toJson(), {
      'personId': 'person-1',
      'affiliation': 'CONGREGATED',
      'entryMode': 'TRANSFER',
      'entryDate': '2026-04-28',
    });
  });
}
