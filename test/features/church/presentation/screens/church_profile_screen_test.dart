import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/data/datasources/church_departments_api.dart';
import 'package:client/features/church/data/datasources/church_events_api.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/current_church_profile_entity.dart';
import 'package:client/features/church/domain/entities/public_church_unit_profile_entity.dart';
import 'package:client/features/church/presentation/screens/church_profile_screen.dart';
import 'package:client/features/church/presentation/widgets/church_shared_widgets.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeChurchEventsApi extends ChurchEventsApi {
  _FakeChurchEventsApi(this.events) : super(Dio());

  final List<dynamic> events;

  @override
  Future<List<dynamic>> getEventsByUnitId({
    required String unitId,
    required DateTime start,
    required DateTime end,
  }) async {
    return events;
  }
}

class _FakeChurchDepartmentsApi extends ChurchDepartmentsApi {
  _FakeChurchDepartmentsApi(this.departments) : super(Dio());

  final List<dynamic> departments;

  @override
  Future<List<dynamic>> getDepartmentsByUnitId(String unitId) async {
    return departments;
  }
}

void main() {
  CurrentChurchProfileEntity buildMemberProfile() {
    return const CurrentChurchProfileEntity(
      membership: MembershipEntity(
        id: 'membership-1',
        unitId: 'unit-1',
        affiliation: 'MEMBER',
      ),
      unit: ChurchUnitEntity(
        id: 'unit-1',
        churchId: 'church-1',
        name: 'Sede Central',
        slug: 'sede-central',
      ),
      church: ChurchEntity(
        id: 'church-1',
        name: 'Igreja Central',
        slug: 'igreja-central',
        email: 'contato@igreja.dev',
      ),
    );
  }

  PublicChurchUnitProfileEntity buildVisitorProfile() {
    return const PublicChurchUnitProfileEntity(
      unit: ChurchUnitEntity(
        id: 'unit-1',
        churchId: 'church-1',
        name: 'Sede Central',
        slug: 'sede-central',
      ),
      church: ChurchEntity(
        id: 'church-1',
        name: 'Igreja Central',
        slug: 'igreja-central',
        email: 'contato@igreja.dev',
      ),
      relatedUnits: [],
    );
  }

  testWidgets('shows loading state for member mode', (tester) async {
    final completer = Completer<CurrentChurchProfileEntity>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentChurchProfileProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: ChurchProfileScreen()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when member has no church', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentChurchProfileProvider.overrideWith(
            (ref) => Future<CurrentChurchProfileEntity>.error(
              const NotFoundFailure('Nenhuma igreja vinculada'),
            ),
          ),
        ],
        child: const MaterialApp(home: ChurchProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cadastrar Igreja'), findsOneWidget);
    expect(
      find.text('Você ainda não participa de nenhuma igreja no app.'),
      findsOneWidget,
    );
  });

  testWidgets('shows generic error state for member mode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentChurchProfileProvider.overrideWith(
            (ref) => Future<CurrentChurchProfileEntity>.error(
              const NetworkFailure('Falha ao carregar'),
            ),
          ),
        ],
        child: const MaterialApp(home: ChurchProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Falha ao carregar'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('renders member profile with unit identity and switches tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentChurchProfileProvider.overrideWith(
            (ref) async => buildMemberProfile(),
          ),
          churchEventsApiProvider.overrideWithValue(
            _FakeChurchEventsApi([
              {
                'id': 'event-1',
                'title': 'Culto de Domingo',
                'description': 'Celebracao principal',
                'startDateTime': '2026-04-05T19:00:00',
                'endDateTime': '2026-04-05T21:00:00',
              },
            ]),
          ),
          churchDepartmentsApiProvider.overrideWithValue(
            _FakeChurchDepartmentsApi([
              {
                'id': 'dept-1',
                'name': 'Louvor',
                'slug': 'louvor',
                'type': 'MINISTRY',
              },
            ]),
          ),
        ],
        child: const MaterialApp(home: ChurchProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sede Central'), findsOneWidget);
    expect(find.text('@sede-central'), findsOneWidget);
    expect(find.text('Culto de Domingo'), findsOneWidget);

    await tester.tap(find.text('Ministérios'));
    await tester.pumpAndSettle();
    expect(find.text('Louvor'), findsOneWidget);

    await tester.tap(find.text('Avisos'));
    await tester.pumpAndSettle();
    expect(find.text('Avisos em breve.'), findsOneWidget);
  });

  testWidgets('member expand action opens public profile with unit id', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.homeChurch,
      routes: [
        GoRoute(
          path: AppRoutes.homeChurch,
          name: AppRoutes.homeChurchName,
          builder: (context, state) => const ChurchProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.churchPublicProfile,
          name: AppRoutes.churchPublicProfileName,
          builder: (context, state) =>
              Text('opened:${state.pathParameters['id']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentChurchProfileProvider.overrideWith(
            (ref) async => buildMemberProfile(),
          ),
          churchEventsApiProvider.overrideWithValue(_FakeChurchEventsApi([])),
          churchDepartmentsApiProvider.overrideWithValue(
            _FakeChurchDepartmentsApi([]),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('opened:unit-1'), findsOneWidget);
  });

  testWidgets('visitor mode shows only events tab placeholder', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicChurchUnitProfileProvider.overrideWith(
            (ref, unitId) async => buildVisitorProfile(),
          ),
        ],
        child: const MaterialApp(home: ChurchProfileScreen(unitId: 'unit-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sede Central'), findsOneWidget);
    expect(find.text('Eventos'), findsOneWidget);
    expect(find.text('Ministérios'), findsNothing);
    expect(find.text('Avisos'), findsNothing);
    expect(find.text('Eventos públicos em breve.'), findsOneWidget);
    expect(find.byKey(ChurchFloatingBackButton.buttonKey), findsOneWidget);
  });

  testWidgets('visitor mode back button pops to previous screen', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/church/unit-1'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/church/:id',
          builder: (context, state) =>
              ChurchProfileScreen(unitId: state.pathParameters['id']!),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicChurchUnitProfileProvider.overrideWith(
            (ref, unitId) async => buildVisitorProfile(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Sede Central'), findsOneWidget);
    expect(find.byKey(ChurchFloatingBackButton.buttonKey), findsOneWidget);

    await tester.tap(find.byKey(ChurchFloatingBackButton.buttonKey));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
    expect(find.text('Sede Central'), findsNothing);
  });

  testWidgets('member mode keeps search row and hides floating back button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentChurchProfileProvider.overrideWith(
            (ref) async => buildMemberProfile(),
          ),
          churchEventsApiProvider.overrideWithValue(_FakeChurchEventsApi([])),
          churchDepartmentsApiProvider.overrideWithValue(
            _FakeChurchDepartmentsApi([]),
          ),
        ],
        child: const MaterialApp(home: ChurchProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pesquisar igreja'), findsOneWidget);
    expect(find.byKey(ChurchFloatingBackButton.buttonKey), findsNothing);
  });
}
