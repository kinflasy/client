import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/scale/domain/entities/editable_scale_assignment_snapshot.dart';
import 'package:client/features/scale/domain/entities/scale_assignment_person_entity.dart';
import 'package:client/features/scale/domain/entities/scale_role_assignments_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deduplica mesma pessoa no mesmo papel', () {
    final snapshot = EditableScaleAssignmentSnapshot.fromRoleAssignments([
      _roleAssignment(
        people: const [
          ScaleAssignmentPersonEntity(
            personId: 'person-1',
            displayName: 'Ana Silva',
            scaleItemId: 'item-1',
            source: ScaleAssignmentPersonSource.participant,
          ),
          ScaleAssignmentPersonEntity(
            personId: 'person-1',
            displayName: 'Ana Silva',
            scaleItemId: 'item-2',
            source: ScaleAssignmentPersonSource.participant,
          ),
        ],
      ),
    ]);

    expect(snapshot.current, hasLength(1));
    expect(snapshot.current.single.personId, 'person-1');
    expect(snapshot.current.single.roleId, 'role-1');
  });

  test('nao adiciona mesma pessoa no mesmo papel', () {
    final snapshot = _snapshot().addPerson(
      localId: 'local:1',
      roleId: 'role-1',
      personId: 'person-1',
      displayName: 'Ana Silva',
    );

    expect(snapshot.current, hasLength(1));
    expect(snapshot.hasPendingChanges, isFalse);
  });

  test('adiciona pessoa sem remover alocacoes existentes', () {
    final snapshot = _snapshot().addPerson(
      localId: 'local:1',
      roleId: 'role-1',
      personId: 'person-2',
      displayName: 'Bruno Lima',
    );

    expect(snapshot.current, hasLength(2));
    expect(
      snapshot.current.map((assignment) => assignment.displayName),
      containsAll(['Ana Silva', 'Bruno Lima']),
    );
    expect(snapshot.current.last.isPersisted, isFalse);
    expect(snapshot.current.last.scaleItemId, isNull);
  });

  test('permite mesma pessoa em papeis diferentes', () {
    final snapshot = _snapshot().addPerson(
      localId: 'local:1',
      roleId: 'role-2',
      personId: 'person-1',
      displayName: 'Ana Silva',
    );

    expect(snapshot.current, hasLength(2));
    expect(snapshot.current.map((assignment) => assignment.roleId), [
      'role-1',
      'role-2',
    ]);
  });

  test('remove apenas a linha selecionada', () {
    final snapshot = _snapshot()
        .addPerson(
          localId: 'local:1',
          roleId: 'role-1',
          personId: 'person-2',
          displayName: 'Bruno Lima',
        )
        .removeByLocalId('persisted:item-1');

    expect(snapshot.current, hasLength(1));
    expect(snapshot.current.single.localId, 'local:1');
    expect(snapshot.current.single.personId, 'person-2');
  });

  test('marca alteracao pendente apos adicionar', () {
    final snapshot = _snapshot().addPerson(
      localId: 'local:1',
      roleId: 'role-1',
      personId: 'person-2',
      displayName: 'Bruno Lima',
    );

    expect(snapshot.hasPendingChanges, isTrue);
  });

  test('marca alteracao pendente apos remover', () {
    final snapshot = _snapshot().removeByLocalId('persisted:item-1');

    expect(snapshot.hasPendingChanges, isTrue);
  });
}

EditableScaleAssignmentSnapshot _snapshot() {
  return EditableScaleAssignmentSnapshot.fromRoleAssignments([
    _roleAssignment(
      people: const [
        ScaleAssignmentPersonEntity(
          personId: 'person-1',
          displayName: 'Ana Silva',
          scaleItemId: 'item-1',
          source: ScaleAssignmentPersonSource.participant,
        ),
      ],
    ),
  ]);
}

ScaleRoleAssignmentsEntity _roleAssignment({
  List<ScaleAssignmentPersonEntity> people = const [],
}) {
  return ScaleRoleAssignmentsEntity(
    item: const LineupItemEntity(
      id: 'lineup-item-1',
      lineupId: 'lineup-1',
      roleId: 'role-1',
      description: 'Vocal',
    ),
    people: people,
  );
}
