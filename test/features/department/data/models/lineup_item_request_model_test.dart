import 'package:client/features/department/data/models/lineup_item_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes lineup item role id and description', () {
    const model = LineupItemRequestModel(
      roleId: 'role-1',
      description: 'Ministra o louvor congregacional.',
    );

    expect(model.toJson(), {
      'roleId': 'role-1',
      'description': 'Ministra o louvor congregacional.',
    });
  });

  test('serializes lineup item update description only', () {
    const model = LineupItemUpdateRequestModel(
      description: 'Apoia a equipe durante o ensaio.',
    );

    expect(model.toJson(), {'description': 'Apoia a equipe durante o ensaio.'});
  });
}
