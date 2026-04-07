import 'package:client/core/errors/failure.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/repositories/church_unit_repository.dart';
import 'package:client/features/church/presentation/screens/church_search_screen.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockChurchUnitRepository extends Mock implements ChurchUnitRepository {}

void main() {
  late _MockChurchUnitRepository unitRepository;

  setUp(() {
    unitRepository = _MockChurchUnitRepository();
  });

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: AppRoutes.churchSearch,
      routes: [
        GoRoute(
          path: AppRoutes.churchSearch,
          name: AppRoutes.churchSearchName,
          builder: (context, state) => const ChurchSearchScreen(),
        ),
        GoRoute(
          path: AppRoutes.churchProfile,
          name: AppRoutes.churchProfileName,
          builder: (context, state) =>
              Text('opened:${state.pathParameters['id']}'),
        ),
      ],
    );
  }

  testWidgets('navigates with headquarter unit id after selecting a church', (
    tester,
  ) async {
    when(() => unitRepository.getUnitsByChurchId('church-1')).thenAnswer(
      (_) async => const Right([
        ChurchUnitEntity(
          id: 'unit-main',
          churchId: 'church-1',
          name: 'Sede',
          type: 'MAIN',
        ),
      ]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          churchSearchProvider.overrideWith(
            (ref, term) async => term.toLowerCase().contains('central') ||
                    term.isEmpty
                ? const [
                    ChurchEntity(
                      id: 'church-1',
                      name: 'Igreja Central',
                      slug: 'igreja-central',
                      email: 'contato@igreja.dev',
                    ),
                  ]
                : const [],
          ),
          churchUnitRepositoryProvider.overrideWithValue(unitRepository),
        ],
        child: MaterialApp.router(routerConfig: buildRouter()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Igreja Central'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'central');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Igreja Central'));
    await tester.pumpAndSettle();

    expect(find.text('opened:unit-main'), findsOneWidget);
  });

  testWidgets('shows snackbar when no headquarter can be resolved', (
    tester,
  ) async {
    when(() => unitRepository.getUnitsByChurchId('church-1')).thenAnswer(
      (_) async => const Left(
        ValidationFailure(
          'Nao foi possivel identificar a unidade sede desta igreja.',
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          churchSearchProvider.overrideWith(
            (ref, term) async => term.toLowerCase().contains('central') ||
                    term.isEmpty
                ? const [
                    ChurchEntity(
                      id: 'church-1',
                      name: 'Igreja Central',
                      slug: 'igreja-central',
                      email: 'contato@igreja.dev',
                    ),
                  ]
                : const [],
          ),
          churchUnitRepositoryProvider.overrideWithValue(unitRepository),
        ],
        child: MaterialApp.router(routerConfig: buildRouter()),
      ),
    );

    await tester.enterText(find.byType(TextField), 'central');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Igreja Central'));
    await tester.pumpAndSettle();

    expect(
      find.text('Nao foi possivel identificar a unidade sede desta igreja.'),
      findsOneWidget,
    );
  });

  testWidgets('shows all churches initially and filters as the user types', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          churchSearchProvider.overrideWith((ref, term) async {
            if (term.isEmpty) {
              return const [
                ChurchEntity(
                  id: 'church-1',
                  name: 'Igreja Central',
                  slug: 'igreja-central',
                  email: 'contato@igreja.dev',
                ),
                ChurchEntity(
                  id: 'church-2',
                  name: 'Comunidade Vida',
                  slug: 'comunidade-vida',
                  email: 'vida@igreja.dev',
                ),
              ];
            }

            if (term.toLowerCase() == 'vida') {
              return const [
                ChurchEntity(
                  id: 'church-2',
                  name: 'Comunidade Vida',
                  slug: 'comunidade-vida',
                  email: 'vida@igreja.dev',
                ),
              ];
            }

            return const [];
          }),
          churchUnitRepositoryProvider.overrideWithValue(unitRepository),
        ],
        child: MaterialApp.router(routerConfig: buildRouter()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Igreja Central'), findsOneWidget);
    expect(find.text('Comunidade Vida'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'vida');
    await tester.pumpAndSettle();

    expect(find.text('Comunidade Vida'), findsOneWidget);
    expect(find.text('Igreja Central'), findsNothing);
  });
}
