import 'package:client/features/department/data/models/lineup_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes lineup name only', () {
    const model = LineupRequestModel(name: 'Culto de domingo');

    expect(model.toJson(), {'name': 'Culto de domingo'});
  });
}
