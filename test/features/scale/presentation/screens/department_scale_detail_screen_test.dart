import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:client/features/department/providers/department_detail_providers.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/scale/domain/entities/department_scale_with_lineup_entity.dart';
import 'package:client/features/scale/presentation/screens/department_scale_detail_screen.dart';
import 'package:client/features/scale/providers/calendar_event_scale_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe título do evento', (tester) async {
    await _pumpScreen(tester, detail: _detail());

    expect(find.text('Culto da manhã'), findsOneWidget);
  });

  testWidgets('exibe data e horário sem departamento', (tester) async {
    await _pumpScreen(tester, detail: _detail());

    expect(find.text('Dom, 19 jul · 09h00'), findsOneWidget);
    expect(find.text('Dom, 19 jul · 09h00 · Louvor'), findsNothing);
  });

  testWidgets('exibe nome da formação', (tester) async {
    await _pumpScreen(tester, detail: _detail());

    expect(find.text('Louvor completo'), findsOneWidget);
  });

  testWidgets('exibe função com papel e descrição discreta', (tester) async {
    await _pumpScreen(tester, detail: _detail());

    expect(find.text('Vocal'), findsOneWidget);
    expect(find.text('Voz principal'), findsOneWidget);

    final description = tester.widget<Text>(find.text('Voz principal'));
    expect(description.style?.color, AppColors.textSecondary);
  });

  testWidgets('exibe formação sem itens', (tester) async {
    await _pumpScreen(
      tester,
      detail: _detail(
        lineup: const LineupEntity(
          id: 'lineup-1',
          name: 'Louvor completo',
          items: [],
        ),
      ),
    );

    expect(find.text('Nenhuma função definida'), findsOneWidget);
  });

  testWidgets('exibe falha parcial da formação', (tester) async {
    await _pumpScreen(
      tester,
      detail: _detail(
        lineupState: DepartmentScaleLineupLoadState.failed,
        lineup: null,
      ),
    );

    expect(
      find.text('Não foi possível carregar as funções da formação.'),
      findsOneWidget,
    );
    expect(find.text('Culto da manhã'), findsOneWidget);
  });

  testWidgets('não exibe elementos fora do escopo da entrega', (tester) async {
    await _pumpScreen(tester, detail: _detail());

    expect(find.text('Editar escala'), findsNothing);
    expect(find.text('Completa'), findsNothing);
    expect(find.text('Incompleta'), findsNothing);
    expect(find.text('Pessoa'), findsNothing);
    expect(find.text('Pessoas'), findsNothing);
    expect(find.text('Vaga aberta'), findsNothing);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required DepartmentScaleWithLineupEntity detail,
  DepartmentDetailEntity department = const DepartmentDetailEntity(
    id: 'dep-1',
    name: 'Louvor',
  ),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        departmentScaleDetailProvider.overrideWith(
          (ref, request) => Stream.value(detail),
        ),
        departmentDetailProvider.overrideWith(
          (ref, departmentId) async => department,
        ),
      ],
      child: const MaterialApp(
        home: DepartmentScaleDetailScreen(
          departmentId: 'dep-1',
          scaleId: 'scale-1',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

DepartmentScaleWithLineupEntity _detail({
  DepartmentScaleLineupLoadState lineupState =
      DepartmentScaleLineupLoadState.loaded,
  LineupEntity? lineup = const LineupEntity(
    id: 'lineup-1',
    name: 'Louvor completo',
    items: [
      LineupItemEntity(
        id: 'item-1',
        lineupId: 'lineup-1',
        roleId: 'role-1',
        description: 'Voz principal',
        role: RoleEntity(id: 'role-1', name: 'Vocal', slug: 'vocal'),
      ),
    ],
  ),
}) {
  return DepartmentScaleWithLineupEntity(
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
    lineupState: lineupState,
    lineup: lineup,
  );
}
