import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/domain/entities/public_church_unit_profile_entity.dart';
import 'package:client/features/church/presentation/screens/church_public_profile_screen.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PublicChurchUnitProfileEntity buildProfile({
    ChurchUnitEntity? unit,
    ChurchEntity? church,
  }) {
    return PublicChurchUnitProfileEntity(
      unit:
          unit ??
          const ChurchUnitEntity(
            id: 'unit-1',
            churchId: 'church-1',
            name: 'Sede Central',
            slug: 'sede-central',
            address: 'Rua A, 10',
            phone: '(11) 99999-0000',
            email: 'sede@igreja.dev',
          ),
      church:
          church ??
          const ChurchEntity(
            id: 'church-1',
            name: 'Igreja Central',
            slug: 'igreja-central',
            email: 'contato@igreja.dev',
            isHeadquarters: true,
          ),
      relatedUnits: const [],
    );
  }

  testWidgets('shows loading state', (tester) async {
    final completer = Completer<PublicChurchUnitProfileEntity>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicChurchUnitProfileProvider.overrideWith(
            (ref, unitId) => completer.future,
          ),
        ],
        child: const MaterialApp(
          home: ChurchPublicProfileScreen(unitId: 'unit-1'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders public profile with unit data', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicChurchUnitProfileProvider.overrideWith(
            (ref, unitId) async => buildProfile(),
          ),
        ],
        child: const MaterialApp(
          home: ChurchPublicProfileScreen(unitId: 'unit-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sede Central'), findsOneWidget);
    expect(find.text('@sede-central'), findsOneWidget);
    expect(find.text('Rua A, 10'), findsOneWidget);
    expect(find.text('(11) 99999-0000'), findsOneWidget);
    expect(find.text('sede@igreja.dev'), findsOneWidget);
    expect(find.text('Sede da rede'), findsOneWidget);
  });

  testWidgets('falls back to church name and slug when unit is incomplete', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicChurchUnitProfileProvider.overrideWith(
            (ref, unitId) async => buildProfile(
              unit: const ChurchUnitEntity(
                id: 'unit-1',
                churchId: 'church-1',
                email: 'sede@igreja.dev',
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ChurchPublicProfileScreen(unitId: 'unit-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Igreja Central'), findsOneWidget);
    expect(find.text('@igreja-central'), findsOneWidget);
  });

  testWidgets('shows error state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicChurchUnitProfileProvider.overrideWith(
            (ref, unitId) => Future<PublicChurchUnitProfileEntity>.error(
              const NetworkFailure('Falha'),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ChurchPublicProfileScreen(unitId: 'unit-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Nao foi possivel carregar o perfil da igreja.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
