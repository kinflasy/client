import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/data/datasources/church_departments_api.dart';
import 'package:client/features/church/data/datasources/church_events_api.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/current_church_profile_entity.dart';
import 'package:client/features/church/presentation/screens/church_profile_screen.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  CurrentChurchProfileEntity buildProfile() {
    return const CurrentChurchProfileEntity(
      membership: MembershipEntity(
        id: 'membership-1',
        unitId: 'unit-1',
        affiliation: 'MEMBER',
      ),
      unit: ChurchUnitEntity(id: 'unit-1', churchId: 'church-1', name: 'Sede'),
      church: ChurchEntity(
        id: 'church-1',
        name: 'Igreja Central',
        slug: 'igreja-central',
        email: 'contato@igreja.dev',
      ),
    );
  }

  testWidgets('shows loading state', (tester) async {
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

  testWidgets('shows empty state when user has no church', (tester) async {
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
      find.text('Você ainda não está vinculado a nenhuma igreja.'),
      findsOneWidget,
    );
  });

  testWidgets('shows generic error state', (tester) async {
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

  testWidgets('renders profile and switches tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentChurchProfileProvider.overrideWith(
            (ref) async => buildProfile(),
          ),
          churchEventsApiProvider.overrideWithValue(
            _FakeChurchEventsApi([
              {
                'id': 'event-1',
                'title': 'Culto de Domingo',
                'description': 'Celebração principal',
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

    expect(find.text('Igreja Central'), findsOneWidget);
    expect(find.text('Culto de Domingo'), findsOneWidget);

    await tester.tap(find.text('Ministérios'));
    await tester.pumpAndSettle();

    expect(find.text('Louvor'), findsOneWidget);

    await tester.tap(find.text('Avisos'));
    await tester.pumpAndSettle();

    expect(find.text('Avisos em breve.'), findsOneWidget);
  });
}
