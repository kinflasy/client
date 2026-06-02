import 'package:client/features/scale/domain/entities/editable_scale_assignment_entity.dart';
import 'package:client/features/scale/domain/services/scale_assignment_diff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('diff sem mudancas retorna listas vazias', () {
    final original = [_assignment('a1', 'role-1', 'person-1')];

    final diff = calculateScaleAssignmentDiff(
      original: original,
      current: original,
    );

    expect(diff.isEmpty, isTrue);
    expect(diff.toCreate, isEmpty);
    expect(diff.toDelete, isEmpty);
  });

  test('diff cria apenas a diferenca de quantidade', () {
    final diff = calculateScaleAssignmentDiff(
      original: [_assignment('a1', 'role-1', 'person-1')],
      current: [
        _assignment('a1', 'role-1', 'person-1'),
        _assignment('a2', 'role-1', 'person-2'),
      ],
    );

    expect(diff.toDelete, isEmpty);
    expect(diff.toCreate.map((request) => request.toJson()), [
      {'roleId': 'role-1', 'personId': 'person-2'},
    ]);
  });

  test('diff remove apenas a diferenca de quantidade', () {
    final diff = calculateScaleAssignmentDiff(
      original: [
        _assignment('a1', 'role-1', 'person-1'),
        _assignment('a2', 'role-1', 'person-2'),
      ],
      current: [_assignment('a2', 'role-1', 'person-2')],
    );

    expect(diff.toCreate, isEmpty);
    expect(diff.toDelete.map((request) => request.toJson()), [
      {'roleId': 'role-1', 'personId': 'person-1'},
    ]);
  });

  test('diff trata mudanca de funcao como delete e post', () {
    final diff = calculateScaleAssignmentDiff(
      original: [_assignment('a1', 'role-1', 'person-1')],
      current: [_assignment('a1', 'role-2', 'person-1')],
    );

    expect(diff.toDelete.map((request) => request.toJson()), [
      {'roleId': 'role-1', 'personId': 'person-1'},
    ]);
    expect(diff.toCreate.map((request) => request.toJson()), [
      {'roleId': 'role-2', 'personId': 'person-1'},
    ]);
  });

  test('diff trata duplicidade adicionada na mesma funcao', () {
    final diff = calculateScaleAssignmentDiff(
      original: [_assignment('a1', 'role-1', 'person-1')],
      current: [
        _assignment('a1', 'role-1', 'person-1'),
        _assignment('a2', 'role-1', 'person-1'),
      ],
    );

    expect(diff.toDelete, isEmpty);
    expect(diff.toCreate.map((request) => request.toJson()), [
      {'roleId': 'role-1', 'personId': 'person-1'},
    ]);
  });

  test('diff trata duplicidade removida parcialmente', () {
    final diff = calculateScaleAssignmentDiff(
      original: [
        _assignment('a1', 'role-1', 'person-1'),
        _assignment('a2', 'role-1', 'person-1'),
      ],
      current: [_assignment('a2', 'role-1', 'person-1')],
    );

    expect(diff.toCreate, isEmpty);
    expect(diff.toDelete.map((request) => request.toJson()), [
      {'roleId': 'role-1', 'personId': 'person-1'},
    ]);
  });
}

EditableScaleAssignmentEntity _assignment(
  String localId,
  String roleId,
  String personId,
) {
  return EditableScaleAssignmentEntity(
    localId: localId,
    scaleItemId: localId,
    roleId: roleId,
    personId: personId,
    displayName: personId,
    isPersisted: true,
  );
}
