import 'package:client/core/router/app_routes.dart';
import 'package:client/features/church/domain/repositories/church_unit_repository.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/presentation/screens/admin_membership_requests_screen.dart';
import 'package:client/features/membership/presentation/screens/member_options_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockChurchUnitRepository extends Mock implements ChurchUnitRepository {}

void main() {
  testWidgets('navigates to membership requests from options item', (
    tester,
  ) async {
    final repository = _MockChurchUnitRepository();
    when(
      () => repository.getPendingMembers('unit-1'),
    ).thenAnswer((_) async => const Right([]));

    final router = GoRouter(
      initialLocation: AppRoutes.adminMembers,
      routes: [
        GoRoute(
          path: AppRoutes.adminMembers,
          builder: (context, state) => const MemberOptionsScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminMembershipRequests,
          builder: (context, state) => const AdminMembershipRequestsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          churchUnitRepositoryProvider.overrideWithValue(repository),
          activeMembershipProvider.overrideWith(
            (ref) async => const MembershipEntity(
              id: 'membership-1',
              unitId: 'unit-1',
              affiliation: 'UNIT_ADMIN',
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Solicita\u00e7\u00f5es de v\u00ednculo'));
    await tester.pumpAndSettle();

    expect(find.text('Solicita\u00e7\u00f5es de v\u00ednculo'), findsOneWidget);
    expect(
      find.text('Nenhuma solicita\u00e7\u00e3o pendente.'),
      findsOneWidget,
    );
  });

  testWidgets('navigates to activate member flow from Pontis user option', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.adminMembers,
      routes: [
        GoRoute(
          path: AppRoutes.adminMembers,
          builder: (context, state) => const MemberOptionsScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminMembersActivate,
          builder: (context, state) =>
              const Scaffold(body: Text('activate-member-flow')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adicionar membro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usuário do Pontis'));
    await tester.pumpAndSettle();

    expect(find.text('activate-member-flow'), findsOneWidget);
  });
}
