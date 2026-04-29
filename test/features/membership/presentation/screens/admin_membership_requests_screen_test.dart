import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/domain/repositories/church_unit_repository.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/domain/entities/pending_unit_membership_entity.dart';
import 'package:client/features/membership/presentation/screens/admin_membership_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockChurchUnitRepository extends Mock implements ChurchUnitRepository {}

void main() {
  late _MockChurchUnitRepository repository;

  setUp(() {
    repository = _MockChurchUnitRepository();
    when(() => repository.getPendingMembers('unit-1')).thenAnswer(
      (_) async => const Right([
        PendingUnitMembershipEntity(
          id: 'pending-1',
          personId: 'person-1',
          unitId: 'unit-1',
          affiliation: 'CONGREGATED',
          fullName: 'Maria Clara',
        ),
      ]),
    );
    when(
      () => repository.confirmPendingMember('unit-1', 'person-1'),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => repository.rejectPendingMember('unit-1', 'person-1'),
    ).thenAnswer((_) async => const Right(null));
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Future<MembershipEntity?> Function(Ref ref)? activeMembershipBuilder,
    ChurchUnitRepository? overriddenRepository,
  }) async {
    final membershipBuilder =
        activeMembershipBuilder ??
        (ref) async => const MembershipEntity(
          id: 'membership-1',
          unitId: 'unit-1',
          affiliation: 'MEMBER',
        );

    final container = ProviderContainer(
      overrides: [
        churchUnitRepositoryProvider.overrideWithValue(
          overriddenRepository ?? repository,
        ),
        activeMembershipProvider.overrideWith(membershipBuilder),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AdminMembershipRequestsScreen()),
      ),
    );
  }

  testWidgets('shows loading while active membership is resolving', (
    tester,
  ) async {
    final completer = Completer<MembershipEntity?>();

    await pumpScreen(
      tester,
      activeMembershipBuilder: (ref) => completer.future,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error when active membership fails', (tester) async {
    await pumpScreen(
      tester,
      activeMembershipBuilder: (ref) async =>
          throw const NotFoundFailure('Falha na unidade ativa.'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Falha na unidade ativa.'), findsOneWidget);
  });

  testWidgets('shows empty state when there is no active unit', (tester) async {
    await pumpScreen(tester, activeMembershipBuilder: (ref) async => null);
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma unidade ativa encontrada.'), findsOneWidget);
  });

  testWidgets('shows error when pending requests fail to load', (tester) async {
    when(() => repository.getPendingMembers('unit-1')).thenAnswer(
      (_) async => const Left(
        NetworkFailure('Falha ao buscar solicita\u00e7\u00f5es pendentes.'),
      ),
    );

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Falha ao buscar solicita\u00e7\u00f5es pendentes.'),
      findsOneWidget,
    );
  });

  testWidgets('shows empty list state when there are no requests', (
    tester,
  ) async {
    when(
      () => repository.getPendingMembers('unit-1'),
    ).thenAnswer((_) async => const Right([]));

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhuma solicita\u00e7\u00e3o pendente.'),
      findsOneWidget,
    );
  });

  testWidgets('shows requests list with affiliation information', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('1 solicita\u00e7\u00e3o pendente'), findsOneWidget);
    expect(find.text('Maria Clara'), findsOneWidget);
    expect(
      find.text('Solicitou v\u00ednculo como congregado.'),
      findsOneWidget,
    );
    expect(find.text('Aprovar'), findsOneWidget);
    expect(find.text('Rejeitar'), findsOneWidget);
  });

  testWidgets('loads requests for the current active unit only', (
    tester,
  ) async {
    when(() => repository.getPendingMembers('unit-2')).thenAnswer(
      (_) async => const Right([
        PendingUnitMembershipEntity(
          id: 'pending-2',
          personId: 'person-2',
          unitId: 'unit-2',
          affiliation: 'MEMBER',
          fullName: 'Jo\u00e3o Pedro',
        ),
      ]),
    );

    await pumpScreen(
      tester,
      activeMembershipBuilder: (ref) async => const MembershipEntity(
        id: 'membership-2',
        unitId: 'unit-2',
        affiliation: 'UNIT_ADMIN',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jo\u00e3o Pedro'), findsOneWidget);
    verify(() => repository.getPendingMembers('unit-2')).called(1);
    verifyNever(() => repository.getPendingMembers('unit-1'));
  });

  testWidgets('opens confirmation dialog to approve request', (tester) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aprovar'));
    await tester.pumpAndSettle();

    expect(find.text('Aprovar solicita\u00e7\u00e3o'), findsOneWidget);
    expect(
      find.text(
        'Deseja aprovar a solicita\u00e7\u00e3o de v\u00ednculo de Maria Clara?',
      ),
      findsOneWidget,
    );
  });

  testWidgets('opens confirmation dialog to reject request', (tester) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rejeitar'));
    await tester.pumpAndSettle();

    expect(find.text('Rejeitar solicita\u00e7\u00e3o'), findsOneWidget);
    expect(
      find.text(
        'Deseja rejeitar a solicita\u00e7\u00e3o de v\u00ednculo de Maria Clara?',
      ),
      findsOneWidget,
    );
  });

  testWidgets('approving a request refreshes the list', (tester) async {
    var reads = 0;
    when(() => repository.getPendingMembers('unit-1')).thenAnswer((_) async {
      reads++;
      if (reads == 1) {
        return const Right([
          PendingUnitMembershipEntity(
            id: 'pending-1',
            personId: 'person-1',
            unitId: 'unit-1',
            affiliation: 'CONGREGATED',
            fullName: 'Maria Clara',
          ),
        ]);
      }

      return const Right([]);
    });

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aprovar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Aprovar').last);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.text('Solicita\u00e7\u00e3o aprovada com sucesso.'),
      findsOneWidget,
    );
    expect(
      find.text('Nenhuma solicita\u00e7\u00e3o pendente.'),
      findsOneWidget,
    );
    expect(find.text('Maria Clara'), findsNothing);
    verify(
      () => repository.confirmPendingMember('unit-1', 'person-1'),
    ).called(1);
    expect(reads, 2);
  });

  testWidgets('rejecting a request refreshes the list', (tester) async {
    var reads = 0;
    when(() => repository.getPendingMembers('unit-1')).thenAnswer((_) async {
      reads++;
      if (reads == 1) {
        return const Right([
          PendingUnitMembershipEntity(
            id: 'pending-1',
            personId: 'person-1',
            unitId: 'unit-1',
            affiliation: 'CONGREGATED',
            fullName: 'Maria Clara',
          ),
        ]);
      }

      return const Right([]);
    });

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rejeitar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Rejeitar').last);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.text('Solicita\u00e7\u00e3o rejeitada com sucesso.'),
      findsOneWidget,
    );
    expect(
      find.text('Nenhuma solicita\u00e7\u00e3o pendente.'),
      findsOneWidget,
    );
    expect(find.text('Maria Clara'), findsNothing);
    verify(
      () => repository.rejectPendingMember('unit-1', 'person-1'),
    ).called(1);
    expect(reads, 2);
  });
}
