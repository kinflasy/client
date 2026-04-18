import 'package:client/features/church/domain/entities/church_department_entity.dart';
import 'package:client/features/church/domain/entities/church_event_entity.dart';
import 'package:client/features/church/presentation/widgets/church_profile_tabs.dart';
import 'package:client/features/church/providers/church_department_providers.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTabsHarness(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: DefaultTabController(length: 3, child: Scaffold(body: child)),
      ),
    );
  }

  testWidgets('tab bar shows Departamentos label', (tester) async {
    await tester.pumpWidget(
      buildTabsHarness(
        Builder(
          builder: (context) => CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: const ChurchProfileTabBarDelegate(),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Departamentos'), findsOneWidget);
    expect(find.text('Ministérios'), findsNothing);
  });

  testWidgets('departments tab shows empty state with updated copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          churchDepartmentsProvider.overrideWith(
            (ref, unitId) async => const [],
          ),
          churchEventsProvider.overrideWith(
            (ref, unitId) async => const <ChurchEventEntity>[],
          ),
        ],
        child: MaterialApp(
          home: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Eventos'),
                    Tab(text: 'Departamentos'),
                    Tab(text: 'Avisos'),
                  ],
                ),
              ),
              body: const ChurchProfileMemberTabView(unitId: 'unit-1'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Departamentos'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum departamento encontrado.'), findsOneWidget);
    expect(
      find.text('Quando houver departamentos ativos, eles aparecerão aqui.'),
      findsOneWidget,
    );
  });

  testWidgets('departments tab renders shared card', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          churchDepartmentsProvider.overrideWith(
            (ref, unitId) async => const [
              ChurchDepartmentEntity(
                id: 'dep-1',
                name: 'Recepção',
                slug: 'recepcao',
                type: 'MINISTRY',
              ),
            ],
          ),
          churchEventsProvider.overrideWith(
            (ref, unitId) async => const <ChurchEventEntity>[],
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ChurchDepartmentsTab(unitId: 'unit-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Recepção'), findsOneWidget);
    expect(find.text('@recepcao'), findsOneWidget);
  });
}
