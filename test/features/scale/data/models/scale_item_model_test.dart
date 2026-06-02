import 'package:client/features/scale/data/models/scale_item_read_model.dart';
import 'package:client/features/scale/data/models/scale_item_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('read model parses complete ScaleItemDto json', () {
    final model = ScaleItemReadModel.fromJson(const {
      'id': 'item-1',
      'scaleId': 'scale-1',
      'roleId': 'role-1',
      'personId': 'person-1',
    });

    final entity = model.toEntity();

    expect(entity.id, 'item-1');
    expect(entity.scaleId, 'scale-1');
    expect(entity.roleId, 'role-1');
    expect(entity.personId, 'person-1');
  });

  test('request serializes roleId and personId', () {
    const request = ScaleItemRequestModel(
      roleId: 'role-1',
      personId: 'person-1',
    );

    expect(request.toJson(), {'roleId': 'role-1', 'personId': 'person-1'});
  });
}
