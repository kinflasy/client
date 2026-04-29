import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/data/datasources/church_unit_api.dart';
import 'package:client/features/church/data/repositories/church_unit_repository_impl.dart';
import 'package:client/features/membership/data/models/join_membership_request_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChurchUnitApi extends Mock implements ChurchUnitApi {}

class _FakeJoinMembershipRequestModel extends Fake
    implements JoinMembershipRequestModel {}

void main() {
  late ChurchUnitRepositoryImpl repository;
  late _MockChurchUnitApi api;

  setUpAll(() {
    registerFallbackValue(_FakeJoinMembershipRequestModel());
  });

  setUp(() {
    api = _MockChurchUnitApi();
    repository = ChurchUnitRepositoryImpl(api);
  });

  test('returns unit entity on success', () async {
    when(() => api.getUnitById('unit-1')).thenAnswer(
      (_) async => {
        'id': 'unit-1',
        'churchId': 'church-1',
        'name': 'Sede',
        'type': 'MAIN',
        'address': 'Rua A, 10',
        'phone': '(11) 99999-0000',
        'email': 'sede@igreja.dev',
        'logoUrl': 'https://cdn/logo.png',
      },
    );

    final result = await repository.getUnitById('unit-1');

    expect(result.isRight(), isTrue);
    result.match((_) => fail('expected success'), (unit) {
      expect(unit.id, 'unit-1');
      expect(unit.churchId, 'church-1');
      expect(unit.name, 'Sede');
      expect(unit.type, 'MAIN');
      expect(unit.address, 'Rua A, 10');
      expect(unit.phone, '(11) 99999-0000');
      expect(unit.email, 'sede@igreja.dev');
      expect(unit.logoUrl, 'https://cdn/logo.png');
    });
  });

  test('returns units by church id on success', () async {
    when(() => api.getUnitsByChurchId('church-1')).thenAnswer(
      (_) async => [
        {
          'id': 'unit-1',
          'churchId': 'church-1',
          'name': 'Sede',
          'type': 'MAIN',
        },
        {
          'id': 'unit-2',
          'churchId': 'church-1',
          'name': 'Filial',
          'type': 'BRANCH',
        },
      ],
    );

    final result = await repository.getUnitsByChurchId('church-1');

    expect(result.isRight(), isTrue);
    result.match((_) => fail('expected success'), (units) {
      expect(units, hasLength(2));
      expect(units.first.type, 'MAIN');
      expect(units.last.type, 'BRANCH');
    });
  });

  test('returns empty list when church has no units', () async {
    when(() => api.getUnitsByChurchId('church-1')).thenAnswer((_) async => []);

    final result = await repository.getUnitsByChurchId('church-1');

    expect(result.isRight(), isTrue);
    result.match(
      (_) => fail('expected success'),
      (units) => expect(units, isEmpty),
    );
  });

  test('maps list lookup errors into NetworkFailure', () async {
    when(() => api.getUnitsByChurchId('church-1')).thenThrow(
      DioException(
        requestOptions: RequestOptions(
          path: '/v1/core/churches/church-1/units',
        ),
        message: 'timeout',
      ),
    );

    final result = await repository.getUnitsByChurchId('church-1');

    expect(result.isLeft(), isTrue);
    result.match((failure) {
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'timeout');
    }, (_) => fail('expected failure'));
  });

  test('maps 404 into NotFoundFailure', () async {
    when(() => api.getUnitById('missing')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/v1/core/church/units/missing'),
        response: Response(
          requestOptions: RequestOptions(path: '/v1/core/church/units/missing'),
          statusCode: 404,
        ),
      ),
    );

    final result = await repository.getUnitById('missing');

    expect(result.isLeft(), isTrue);
    result.match(
      (failure) => expect(failure, isA<NotFoundFailure>()),
      (_) => fail('expected failure'),
    );
  });

  test('joins unit on success', () async {
    when(
      () =>
          api.joinUnit('unit-1', any(that: isA<JoinMembershipRequestModel>())),
    ).thenAnswer((_) async {});

    final result = await repository.joinUnit('unit-1', 'CONGREGATED');

    expect(result.isRight(), isTrue);
    verify(
      () => api.joinUnit(
        'unit-1',
        any(
          that: isA<JoinMembershipRequestModel>().having(
            (request) => request.affiliation,
            'affiliation',
            'CONGREGATED',
          ),
        ),
      ),
    ).called(1);
  });

  test('maps join errors into NetworkFailure', () async {
    when(
      () =>
          api.joinUnit('unit-1', any(that: isA<JoinMembershipRequestModel>())),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(
          path: '/v1/core/church/units/unit-1/join',
        ),
        message: 'timeout',
      ),
    );

    final result = await repository.joinUnit('unit-1', 'MEMBER');

    expect(result.isLeft(), isTrue);
    result.match((failure) {
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'timeout');
    }, (_) => fail('expected failure'));
  });

  test('returns pending members on success', () async {
    when(() => api.getPendingMembers('unit-1')).thenAnswer(
      (_) async => [
        {
          'id': 'pending-1',
          'unitId': 'unit-1',
          'person': {
            'id': 'person-1',
            'fullName': 'Maria Clara',
            'nickname': 'Mari',
            'gender': 'FEMALE',
            'birthDate': '2026-04-27',
            'phone': '(11) 99999-0000',
            'addressId': 'address-1',
            'profileImageId': 'image-1',
            'age': 19,
            'type': 'PERSON',
            'churchId': 'church-1',
            'email': 'maria@example.com',
          },
          'affiliation': 'VISITOR',
          'unitConfirmationDate': '2026-04-27T21:19:13.480Z',
          'userConfirmationDate': '2026-04-27T21:19:13.480Z',
        },
      ],
    );

    final result = await repository.getPendingMembers('unit-1');

    expect(result.isRight(), isTrue);
    result.match((_) => fail('expected success'), (items) {
      expect(items, hasLength(1));
      expect(items.first.id, 'pending-1');
      expect(items.first.personId, 'person-1');
      expect(items.first.unitId, 'unit-1');
      expect(items.first.fullName, 'Maria Clara');
      expect(items.first.affiliation, 'VISITOR');
      expect(items.first.unitConfirmationDate, '2026-04-27T21:19:13.480Z');
      expect(items.first.userConfirmationDate, '2026-04-27T21:19:13.480Z');
    });
  });

  test(
    'keeps compatibility when unit id comes nested in unit object',
    () async {
      when(() => api.getPendingMembers('unit-1')).thenAnswer(
        (_) async => [
          {
            'id': 'pending-1',
            'unit': {'id': 'unit-1'},
            'person': {'id': 'person-1', 'fullName': 'Maria Clara'},
            'affiliation': 'CONGREGATED',
          },
        ],
      );

      final result = await repository.getPendingMembers('unit-1');

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (items) {
        expect(items.single.unitId, 'unit-1');
      });
    },
  );

  test(
    'uses nickname when pending member full name is not available',
    () async {
      when(() => api.getPendingMembers('unit-1')).thenAnswer(
        (_) async => [
          {
            'id': 'pending-1',
            'unitId': 'unit-1',
            'person': {'id': 'person-1', 'nickname': 'Mari'},
            'affiliation': 'CONGREGATED',
          },
        ],
      );

      final result = await repository.getPendingMembers('unit-1');

      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected success'), (items) {
        expect(items, hasLength(1));
        expect(items.first.fullName, 'Mari');
      });
    },
  );

  test('confirms pending member on success', () async {
    when(
      () => api.confirmPendingMember('unit-1', 'person-1'),
    ).thenAnswer((_) async {});

    final result = await repository.confirmPendingMember('unit-1', 'person-1');

    expect(result.isRight(), isTrue);
    verify(() => api.confirmPendingMember('unit-1', 'person-1')).called(1);
  });

  test('rejects pending member on success', () async {
    when(
      () => api.rejectPendingMember('unit-1', 'person-1'),
    ).thenAnswer((_) async {});

    final result = await repository.rejectPendingMember('unit-1', 'person-1');

    expect(result.isRight(), isTrue);
    verify(() => api.rejectPendingMember('unit-1', 'person-1')).called(1);
  });

  test('maps pending members response message into NetworkFailure', () async {
    when(() => api.getPendingMembers('unit-1')).thenThrow(
      DioException(
        requestOptions: RequestOptions(
          path: '/v1/core/church/units/unit-1/members/pending',
        ),
        response: Response(
          requestOptions: RequestOptions(
            path: '/v1/core/church/units/unit-1/members/pending',
          ),
          statusCode: 500,
          data: {'message': 'Falha ao listar pendências da unidade.'},
        ),
        message:
            'Server error - the server failed to fulfil an apparently valid request',
      ),
    );

    final result = await repository.getPendingMembers('unit-1');

    expect(result.isLeft(), isTrue);
    result.match((failure) {
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'Falha ao listar pendências da unidade.');
    }, (_) => fail('expected failure'));
  });

  test('maps confirm errors into NetworkFailure', () async {
    when(() => api.confirmPendingMember('unit-1', 'person-1')).thenThrow(
      DioException(
        requestOptions: RequestOptions(
          path: '/v1/core/church/units/unit-1/member/person-1/confirm',
        ),
        message: 'timeout',
      ),
    );

    final result = await repository.confirmPendingMember('unit-1', 'person-1');

    expect(result.isLeft(), isTrue);
    result.match((failure) {
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'timeout');
    }, (_) => fail('expected failure'));
  });

  test('maps reject errors into NetworkFailure', () async {
    when(() => api.rejectPendingMember('unit-1', 'person-1')).thenThrow(
      DioException(
        requestOptions: RequestOptions(
          path: '/v1/core/church/units/unit-1/member/person-1/reject',
        ),
        message: 'timeout',
      ),
    );

    final result = await repository.rejectPendingMember('unit-1', 'person-1');

    expect(result.isLeft(), isTrue);
    result.match((failure) {
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'timeout');
    }, (_) => fail('expected failure'));
  });
}
