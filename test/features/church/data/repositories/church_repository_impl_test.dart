import 'package:client/core/errors/failure.dart';
import 'package:client/core/address/address_request_model.dart';
import 'package:client/features/church/data/datasources/church_api.dart';
import 'package:client/features/church/data/models/church_read_models.dart';
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
        (_) async => ChurchReadModel.fromJson({
          'id': 'church-1',
          'name': 'Igreja Central',
          'slug': 'igreja-central',
          'email': 'contato@igreja.dev',
          'phone': '9999-0000',
        }),
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

  group('ChurchRepositoryImpl.getAllChurches', () {
    test('returns church entities on success', () async {
      when(() => api.getAllChurches()).thenAnswer(
        (_) async => [
          ChurchReadModel.fromJson({
            'id': 'church-1',
            'name': 'Igreja Central',
            'slug': 'igreja-central',
            'email': 'contato@igreja.dev',
            'acronym': 'IC',
          }),
          ChurchReadModel.fromJson({
            'id': 'church-2',
            'name': 'Comunidade Vida',
            'slug': 'comunidade-vida',
            'email': 'vida@igreja.dev',
          }),
        ],
      );

      final result = await repository.getAllChurches();

      expect(result.isRight(), isTrue);
      result.match(
        (_) => fail('expected success'),
        (churches) {
          expect(churches, hasLength(2));
          expect(churches.first.name, 'Igreja Central');
          expect(churches.first.acronym, 'IC');
          expect(churches.last.slug, 'comunidade-vida');
        },
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

      when(() => api.createChurch(request.toJson())).thenThrow(
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
