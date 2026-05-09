import 'package:client/features/calendar/sub_features/create_event/presentation/screens/create_event_screen.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/current_church_profile_entity.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp() {
    return ProviderScope(
      overrides: [
        currentChurchProfileProvider.overrideWith((ref) async => _profile()),
        departmentsProvider('unit-1').overrideWith(
          (ref) async => const [DepartmentEntity(id: 'dep-1', name: 'Louvor')],
        ),
      ],
      child: const MaterialApp(home: CreateEventScreen()),
    );
  }

  testWidgets('valida campos obrigatórios', (tester) async {
    await _pumpApp(tester, buildApp());

    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(find.text('Campo obrigatório'), findsNWidgets(5));
    expect(
      find.text('Adicione pelo menos uma regra de visibilidade.'),
      findsOneWidget,
    );
  });

  testWidgets('valida fim anterior ao início', (tester) async {
    await _pumpApp(tester, buildApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'Ensaio geral');
    await tester.enterText(_field('start-date-field'), '10/05/2026');
    await tester.enterText(_field('start-time-field'), '20:00');
    await tester.enterText(_field('end-date-field'), '10/05/2026');
    await tester.enterText(_field('end-time-field'), '18:00');
    await tester.tap(find.byKey(const Key('add-unit-visibility-rule')).last);
    await tester.pump();

    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(find.text('O fim deve ser posterior ao início.'), findsOneWidget);
  });

  testWidgets('exige ao menos uma regra de visibilidade', (tester) async {
    await _pumpApp(tester, buildApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'Ensaio geral');
    await tester.enterText(_field('start-date-field'), '10/05/2026');
    await tester.enterText(_field('start-time-field'), '18:00');
    await tester.enterText(_field('end-date-field'), '10/05/2026');
    await tester.enterText(_field('end-time-field'), '20:00');

    await tester.tap(find.byKey(const Key('save-event-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Adicione pelo menos uma regra de visibilidade.'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpApp(WidgetTester tester, Widget app) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

Finder _field(String key) {
  return find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(TextFormField),
  );
}

CurrentChurchProfileEntity _profile() {
  return const CurrentChurchProfileEntity(
    membership: MembershipEntity(
      id: 'membership-1',
      unitId: 'unit-1',
      affiliation: 'UNIT_ADMIN',
    ),
    unit: ChurchUnitEntity(id: 'unit-1', churchId: 'church-1'),
    church: ChurchEntity(
      id: 'church-1',
      name: 'Igreja Pontis',
      slug: 'igreja-pontis',
      email: 'contato@pontis.test',
    ),
  );
}
