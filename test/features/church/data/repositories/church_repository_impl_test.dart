import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/data/datasources/church_api.dart';
import 'package:client/features/church/data/models/church_request_model.dart';
import 'package:client/features/church/data/repositories/church_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChurchApi extends Mock implements ChurchApi {}

void main() {
  late ChurchRepositoryImpl repository;
  late _MockChurchApi api;

  setUp(() {
    api = _MockChurchApi();
    repository = ChurchRepositoryImpl(api);
  });

  group('ChurchRepositoryImpl.getChurchById', () {
    test('returns church entity on success', () async {
      when(() => api.getChurchById('church-1')).thenAnswer(
        (_) async => {
          'id': 'church-1',
          'name': 'Igreja Central',
          'slug': 'igreja-central',
          'email': 'contato@igreja.dev',
          'phone': '9999-0000',
        },
      );

      final result = await repository.getChurchById('church-1');

      expect(result.isRight(), isTrue);
      result.match(
        (_) => fail('expected success'),
        (church) {
          expect(church.id, 'church-1');
          expect(church.name, 'Igreja Central');
          expect(church.slug, 'igreja-central');
          expect(church.email, 'contato@igreja.dev');
        },
      );
    });

    test('maps 404 into NotFoundFailure', () async {
      when(() => api.getChurchById('missing')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/core/churches/missing'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/core/churches/missing'),
            statusCode: 404,
          ),
        ),
      );

      final result = await repository.getChurchById('missing');

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('expected failure'),
      );
    });
  });

  group('ChurchRepositoryImpl.createChurch', () {
    test('maps validation failures from api', () async {
      final request = ChurchStarterRequestModel(
        name: 'Igreja',
        slug: 'igreja',
        email: 'contato@igreja.dev',
        unit: const UnitRequestModel(
          name: 'Sede',
          slug: 'sede',
          phone: '1111',
          email: 'sede@igreja.dev',
          address: AddressRequestModel(),
        ),
      );

      when(() => api.createChurch(request)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/core/churches'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/core/churches'),
            statusCode: 409,
            data: {'message': 'Slug já usado'},
          ),
        ),
      );

      final result = await repository.createChurch(request);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, 'Slug já usado');
        },
        (_) => fail('expected failure'),
      );
    });
  });
}
