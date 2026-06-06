import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/scale/domain/entities/department_scale_card_summary_entity.dart';
import 'package:client/features/scale/domain/entities/department_scale_with_lineup_entity.dart';
import 'package:client/features/scale/domain/entities/scale_assignment_person_entity.dart';
import 'package:client/features/scale/domain/entities/scale_role_assignments_entity.dart';
import 'package:client/features/scale/presentation/widgets/department_scale_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows event date title and chevron', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DepartmentScaleCard(scale: _summary())),
      ),
    );

    expect(find.text('Dom, 19 jul - 09:00'), findsOneWidget);
    expect(find.text('Culto da manhã'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('handles tap without built-in navigation', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentScaleCard(
            scale: _summary(),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Culto da manhã'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows role with one person in the same visual row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentScaleCard(
            scale: _summary(
              roles: [
                _roleSummary(
                  _lineupItem('item-1', roleName: 'Vocal'),
                  people: [_person('person-1', 'Ana')],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Vocal'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Vocal:'), findsNothing);
    expect(find.byIcon(Icons.circle), findsNothing);
  });

  testWidgets('shows multiple people separated by comma', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentScaleCard(
            scale: _summary(
              roles: [
                _roleSummary(
                  _lineupItem('item-1', roleName: 'Vocal'),
                  people: [
                    _person('person-1', 'Ana'),
                    _person('person-2', 'João'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Ana, João'), findsOneWidget);
  });

  testWidgets('shows role without person and no open vacancy text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentScaleCard(
            scale: _summary(
              roles: [
                _roleSummary(
                  _lineupItem('item-1', roleName: 'Bateria'),
                  capacity: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Bateria'), findsOneWidget);
    expect(find.textContaining('Vaga'), findsNothing);
    expect(find.textContaining('vaga'), findsNothing);
    expect(find.text('Bateria:'), findsNothing);
  });

  testWidgets('uses role name before description and preserves order', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentScaleCard(
            scale: _summary(
              roles: [
                _roleSummary(
                  _lineupItem('item-1', description: 'Descrição um'),
                ),
                _roleSummary(
                  _lineupItem(
                    'item-2',
                    roleName: 'Teclado',
                    description: 'Descrição dois',
                  ),
                ),
                _roleSummary(
                  _lineupItem('item-3', description: 'Descrição três'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Descrição um'), findsOneWidget);
    expect(find.text('Teclado'), findsOneWidget);
    expect(find.text('Descrição dois'), findsNothing);
    expect(find.text('Descrição três'), findsOneWidget);

    final firstTop = tester.getTopLeft(find.text('Descrição um')).dy;
    final secondTop = tester.getTopLeft(find.text('Teclado')).dy;
    final thirdTop = tester.getTopLeft(find.text('Descrição três')).dy;

    expect(firstTop, lessThan(secondTop));
    expect(secondTop, lessThan(thirdTop));
  });

  testWidgets('shows empty lineup message when there are no roles', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentScaleCard(scale: _summary(roles: [])),
        ),
      ),
    );

    expect(find.text('Nenhuma função definida'), findsOneWidget);
  });

  testWidgets('hides lineup section when lineup load failed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DepartmentScaleCard(scale: _summaryWithFailure)),
      ),
    );

    expect(find.text('Culto da manhã'), findsOneWidget);
    expect(find.text('Nenhuma função definida'), findsNothing);
    expect(find.text('Vocal'), findsNothing);
  });

  testWidgets('limits functions to three and expands to show all', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentScaleCard(
            scale: _summary(
              roles: [
                _roleSummary(_lineupItem('item-1', roleName: 'Vocal')),
                _roleSummary(_lineupItem('item-2', roleName: 'Violão')),
                _roleSummary(_lineupItem('item-3', roleName: 'Baixo')),
                _roleSummary(_lineupItem('item-4', roleName: 'Bateria')),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Vocal'), findsOneWidget);
    expect(find.text('Violão'), findsOneWidget);
    expect(find.text('Baixo'), findsOneWidget);
    expect(find.text('Bateria'), findsNothing);
    expect(find.text('Ver tudo (+1)'), findsOneWidget);

    await tester.tap(find.text('Ver tudo (+1)'));
    await tester.pumpAndSettle();

    expect(find.text('Bateria'), findsOneWidget);
    expect(find.text('Mostrar menos'), findsOneWidget);

    await tester.tap(find.text('Mostrar menos'));
    await tester.pumpAndSettle();

    expect(find.text('Bateria'), findsNothing);
    expect(find.text('Ver tudo (+1)'), findsOneWidget);
  });

  testWidgets('does not trigger card tap when expansion button is tapped', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentScaleCard(
            scale: _summary(
              roles: [
                _roleSummary(_lineupItem('item-1', roleName: 'Vocal')),
                _roleSummary(_lineupItem('item-2', roleName: 'Violão')),
                _roleSummary(_lineupItem('item-3', roleName: 'Baixo')),
                _roleSummary(_lineupItem('item-4', roleName: 'Bateria')),
              ],
            ),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ver tudo (+1)'));
    await tester.pumpAndSettle();

    expect(tapped, isFalse);
    expect(find.text('Bateria'), findsOneWidget);
  });

  testWidgets('renders horizontal names scroll without scrollbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 260,
          child: Scaffold(
            body: DepartmentScaleCard(
              scale: _summary(
                roles: [
                  _roleSummary(
                    _lineupItem('item-1', roleName: 'Vocal'),
                    people: [
                      _person('person-1', 'Ana Carolina'),
                      _person('person-2', 'João Pedro'),
                      _person('person-3', 'Carlos Eduardo'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('department-scale-card-names-scroll')),
      findsOneWidget,
    );
    expect(find.byType(Scrollbar), findsNothing);
    expect(find.byType(ShaderMask), findsOneWidget);
  });

  testWidgets('falls back to roles only when people failed to load', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentScaleCard(
            scale: _summaryWithItems([
              _lineupItem('item-1', roleId: 'role-1', roleName: 'Vocal'),
              _lineupItem('item-2', roleId: 'role-1', roleName: 'Vocal'),
            ], peopleLoadFailed: true),
          ),
        ),
      ),
    );

    expect(find.text('Vocal'), findsOneWidget);
    expect(find.textContaining('vaga'), findsNothing);
    expect(find.textContaining('Pessoa'), findsNothing);
  });
}

final _baseScale = DepartmentScaleWithLineupEntity(
  lineupState: DepartmentScaleLineupLoadState.loaded,
  scale: DepartmentCalendarEventScaleEntity(
    scale: const CalendarEventScaleEntity(
      id: 'scale-1',
      lineupId: 'lineup-1',
      type: CalendarEventScaleType.owner,
      calendarEventId: 'event-1',
    ),
    calendarEvent: CalendarEventEntity(
      id: 'event-1',
      title: 'Culto da manhã',
      startDateTime: DateTime(2026, 7, 19, 9),
      endDateTime: DateTime(2026, 7, 19, 11),
      type: CalendarEventType.department,
      departmentId: 'dep-1',
    ),
  ),
);

final _summaryWithFailure = DepartmentScaleCardSummaryEntity(
  base: DepartmentScaleWithLineupEntity(
    lineupState: DepartmentScaleLineupLoadState.failed,
    scale: _baseScale.scale,
  ),
  roleSummaries: const [],
);

DepartmentScaleCardSummaryEntity _summary({
  List<ScaleRoleAssignmentsEntity>? roles,
}) {
  final roleSummaries =
      roles ?? [_roleSummary(_lineupItem('item-1', roleName: 'Vocal'))];

  return DepartmentScaleCardSummaryEntity(
    base: DepartmentScaleWithLineupEntity(
      scale: _baseScale.scale,
      lineupState: DepartmentScaleLineupLoadState.loaded,
      lineup: LineupEntity(
        id: 'lineup-1',
        name: 'Banda',
        items: roleSummaries.map((role) => role.item).toList(),
      ),
    ),
    roleSummaries: roleSummaries,
  );
}

DepartmentScaleCardSummaryEntity _summaryWithItems(
  List<LineupItemEntity> items, {
  bool peopleLoadFailed = false,
}) {
  return DepartmentScaleCardSummaryEntity(
    base: DepartmentScaleWithLineupEntity(
      scale: _baseScale.scale,
      lineupState: DepartmentScaleLineupLoadState.loaded,
      lineup: LineupEntity(id: 'lineup-1', name: 'Banda', items: items),
    ),
    roleSummaries: const [],
    peopleLoadFailed: peopleLoadFailed,
  );
}

ScaleRoleAssignmentsEntity _roleSummary(
  LineupItemEntity item, {
  List<ScaleAssignmentPersonEntity> people = const [],
  int capacity = 1,
}) {
  return ScaleRoleAssignmentsEntity(
    item: item,
    people: people,
    capacity: capacity,
  );
}

ScaleAssignmentPersonEntity _person(String id, String name) {
  return ScaleAssignmentPersonEntity(
    personId: id,
    displayName: name,
    source: ScaleAssignmentPersonSource.participant,
  );
}

LineupItemEntity _lineupItem(
  String id, {
  String? roleId,
  String roleName = '',
  String description = '',
}) {
  final resolvedRoleId = roleId ?? 'role-$id';
  return LineupItemEntity(
    id: id,
    lineupId: 'lineup-1',
    roleId: resolvedRoleId,
    description: description,
    role: roleName.isEmpty
        ? null
        : RoleEntity(id: resolvedRoleId, name: roleName, slug: roleName),
  );
}
