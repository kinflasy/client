import 'package:client/core/errors/failure.dart';
import 'package:client/core/address/address_request_model.dart';
import 'package:client/features/membership/data/datasources/member_profile_api.dart';
import 'package:client/features/membership/data/models/update_inactive_person_request_model.dart';
import 'package:client/features/membership/data/repositories/member_profile_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

class _MockMemberProfileApi extends Mock implements MemberProfileApi {}

void main() {
  group('UpdateInactivePersonRequestModel', () {
    test('serializes personal fields and address', () {
      const request = UpdateInactivePersonRequestModel(
        fullName: 'Carlos Lima',
        nickname: 'Carlinhos',
        gender: 'MALE',
        birthDate: '1988-01-01',
        phone: '99999-0000',
        email: 'carlos@dev.com',
        address: AddressRequestModel(
          city: 'Fortaleza',
          state: 'CE',
          street: 'Rua A',
          number: '10',
        ),
      );

      expect(request.toJson(), {
        'fullName': 'Carlos Lima',
        'nickname': 'Carlinhos',
        'gender': 'MALE',
        'birthDate': '1988-01-01',
        'phone': '99999-0000',
        'email': 'carlos@dev.com',
        'address': {
          'zip': null,
          'country': null,
          'state': 'CE',
          'city': 'Fortaleza',
          'neighborhood': null,
          'street': 'Rua A',
          'number': '10',
          'complement': null,
          'reference': null,
        },
      });
    });
  });

  group('MemberProfileApi.updateInactivePerson', () {
    late _MockDio dio;
    late MemberProfileApi api;

    setUp(() {
      dio = _MockDio();
      api = MemberProfileApi(dio);
    });

    test('executes PUT with expected payload', () async {
      const request = UpdateInactivePersonRequestModel(
        fullName: 'Carlos Lima',
        gender: 'MALE',
        birthDate: '1988-01-01',
      );

      when(
        () => dio.put<void>(
          '/v1/core/inactive-people/person-1',
          data: request.toJson(),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(path: '/v1/core/inactive-people/person-1'),
        ),
      );

      await api.updateInactivePerson('person-1', request);

      verify(
        () => dio.put<void>(
          '/v1/core/inactive-people/person-1',
          data: request.toJson(),
        ),
      ).called(1);
    });
  });

  group('MemberProfileRepositoryImpl.updateInactivePerson', () {
    late _MockMemberProfileApi api;
    late MemberProfileRepositoryImpl repository;
    const request = UpdateInactivePersonRequestModel(
      fullName: 'Carlos Lima',
      gender: 'MALE',
      birthDate: '1988-01-01',
    );

    setUp(() {
      api = _MockMemberProfileApi();
      repository = MemberProfileRepositoryImpl(api);
    });

    test('returns success when api call succeeds', () async {
      when(() => api.updateInactivePerson('person-1', request)).thenAnswer(
        (_) async {},
      );

      final result = await repository.updateInactivePerson(
        personId: 'person-1',
        request: request,
      );

      expect(result.isRight(), isTrue);
    });

    test('maps 404 into NotFoundFailure', () async {
      when(() => api.updateInactivePerson('missing', request)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/core/inactive-people/missing'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/core/inactive-people/missing'),
            statusCode: 404,
          ),
        ),
      );

      final result = await repository.updateInactivePerson(
        personId: 'missing',
        request: request,
      );

      result.match(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('expected failure'),
      );
    });

    test('maps validation response into ValidationFailure', () async {
      when(() => api.updateInactivePerson('person-1', request)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/core/inactive-people/person-1'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/core/inactive-people/person-1'),
            statusCode: 422,
            data: {'message': 'Campo invalido'},
          ),
        ),
      );

      final result = await repository.updateInactivePerson(
        personId: 'person-1',
        request: request,
      );

      result.match(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, 'Campo invalido');
        },
        (_) => fail('expected failure'),
      );
    });

    test('maps network errors into NetworkFailure', () async {
      when(() => api.updateInactivePerson('person-1', request)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/core/inactive-people/person-1'),
          message: 'timeout',
        ),
      );

      final result = await repository.updateInactivePerson(
        personId: 'person-1',
        request: request,
      );

      result.match(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'timeout');
        },
        (_) => fail('expected failure'),
      );
    });
  });
}
