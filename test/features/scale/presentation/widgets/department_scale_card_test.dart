import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/scale/domain/entities/department_scale_with_lineup_entity.dart';
import 'package:client/features/scale/presentation/widgets/department_scale_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows event date title and chevron', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DepartmentScaleCard(scale: _scale)),
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
          body: DepartmentScaleCard(scale: _scale, onTap: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.text('Culto da manhã'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows lineup functions in separate rows', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentScaleCard(
            scale: _scaleWithItems([
              _lineupItem('item-1', roleName: 'Vocal'),
              _lineupItem('item-2', roleName: 'Violão'),
              _lineupItem('item-3', roleName: 'Baixo'),
            ]),
          ),
        ),
      ),
    );

    expect(find.text('Vocal'), findsOneWidget);
    expect(find.text('Violão'), findsOneWidget);
    expect(find.text('Baixo'), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsNWidgets(3));
  });

  testWidgets('uses role name before description and preserves item order', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentScaleCard(
            scale: _scaleWithItems([
              _lineupItem('item-1', description: 'Descrição um'),
              _lineupItem(
                'item-2',
                roleName: 'Teclado',
                description: 'Descrição dois',
              ),
              _lineupItem('item-3', description: 'Descrição três'),
            ]),
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

  testWidgets('groups duplicated roles and shows vacancy count', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentScaleCard(
            scale: _scaleWithItems([
              _lineupItem('item-1', roleId: 'role-1', roleName: 'Vocal'),
              _lineupItem('item-2', roleId: 'role-1', roleName: 'Vocal'),
              _lineupItem('item-3', roleName: 'ViolÃ£o'),
            ]),
          ),
        ),
      ),
    );

    expect(find.text('Vocal (2 vagas)'), findsOneWidget);
    expect(find.text('Vocal'), findsNothing);
    expect(find.text('ViolÃ£o'), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsNWidgets(2));
  });

  testWidgets('shows empty lineup message when there are no items', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DepartmentScaleCard(scale: _scaleWithItems([]))),
      ),
    );

    expect(find.text('Nenhuma função definida'), findsOneWidget);
  });

  testWidgets('hides lineup section when lineup load failed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DepartmentScaleCard(scale: _scaleWithFailure)),
      ),
    );

    expect(find.text('Culto da manhã'), findsOneWidget);
    expect(find.text('Nenhuma função definida'), findsNothing);
    expect(find.byIcon(Icons.circle), findsNothing);
  });

  testWidgets('limits functions to three and expands to show all', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentScaleCard(
            scale: _scaleWithItems([
              _lineupItem('item-1', roleName: 'Vocal'),
              _lineupItem('item-2', roleName: 'Violão'),
              _lineupItem('item-3', roleName: 'Baixo'),
              _lineupItem('item-4', roleName: 'Bateria'),
            ]),
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

  testWidgets('hides expansion button when there are up to three functions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentScaleCard(
            scale: _scaleWithItems([
              _lineupItem('item-1', roleName: 'Vocal'),
              _lineupItem('item-2', roleName: 'Violão'),
              _lineupItem('item-3', roleName: 'Baixo'),
            ]),
          ),
        ),
      ),
    );

    expect(find.text('Ver tudo (+0)'), findsNothing);
    expect(find.textContaining('Ver tudo'), findsNothing);
    expect(find.text('Mostrar menos'), findsNothing);
  });

  testWidgets('does not trigger card tap when expansion button is tapped', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartmentScaleCard(
            scale: _scaleWithItems([
              _lineupItem('item-1', roleName: 'Vocal'),
              _lineupItem('item-2', roleName: 'Violão'),
              _lineupItem('item-3', roleName: 'Baixo'),
              _lineupItem('item-4', roleName: 'Bateria'),
            ]),
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
}

final _scale = DepartmentScaleWithLineupEntity(
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

final _scaleWithFailure = DepartmentScaleWithLineupEntity(
  lineupState: DepartmentScaleLineupLoadState.failed,
  scale: _scale.scale,
);

DepartmentScaleWithLineupEntity _scaleWithItems(List<LineupItemEntity> items) {
  return DepartmentScaleWithLineupEntity(
    scale: _scale.scale,
    lineupState: DepartmentScaleLineupLoadState.loaded,
    lineup: LineupEntity(id: 'lineup-1', name: 'Banda', items: items),
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
