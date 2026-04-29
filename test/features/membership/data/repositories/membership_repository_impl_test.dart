import 'package:client/core/errors/failure.dart';
import 'package:client/features/membership/data/datasources/membership_api.dart';
import 'package:client/features/membership/data/models/membership_model.dart';
import 'package:client/features/membership/data/models/pending_membership_model.dart';
import 'package:client/features/membership/data/repositories/membership_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMembershipApi extends Mock implements MembershipApi {}

void main() {
  late MembershipRepositoryImpl repository;
  late _MockMembershipApi api;

  setUp(() {
    api = _MockMembershipApi();
    repository = MembershipRepositoryImpl(api);
  });

  test('returns memberships on success', () async {
    when(() => api.getMyMemberships()).thenAnswer(
      (_) async => const [
        MembershipModel(id: 'membership-1', unitId: 'unit-1'),
      ],
    );

    final result = await repository.getMyMemberships();

    expect(result.isRight(), isTrue);
    result.match((_) => fail('expected success'), (memberships) {
      expect(memberships, hasLength(1));
      expect(memberships.first.id, 'membership-1');
      expect(memberships.first.unitId, 'unit-1');
    });
  });

  test('returns pending memberships on success', () async {
    when(() => api.getMyPendingMemberships()).thenAnswer(
      (_) async => const [
        PendingMembershipModel(
          id: 'pending-1',
          unitId: 'unit-1',
          personId: 'person-1',
          affiliation: 'CONGREGATED',
          unitConfirmationDate: '2026-04-25T12:00:00Z',
        ),
      ],
    );

    final result = await repository.getMyPendingMemberships();

    expect(result.isRight(), isTrue);
    result.match((_) => fail('expected success'), (memberships) {
      expect(memberships, hasLength(1));
      expect(memberships.first.id, 'pending-1');
      expect(memberships.first.unitId, 'unit-1');
      expect(memberships.first.personId, 'person-1');
      expect(memberships.first.affiliation, 'CONGREGATED');
      expect(memberships.first.unitConfirmationDate, '2026-04-25T12:00:00Z');
    });
  });

  test(
    'maps pending membership request failures into NetworkFailure',
    () async {
      when(() => api.getMyPendingMemberships()).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/v1/core/church/unit/memberships/pending',
          ),
          message: 'timeout',
        ),
      );

      final result = await repository.getMyPendingMemberships();

      expect(result.isLeft(), isTrue);
      result.match((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'Erro ao buscar solicitacoes pendentes');
      }, (_) => fail('expected failure'));
    },
  );
}
