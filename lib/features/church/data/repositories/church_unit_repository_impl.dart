import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/church_unit_entity.dart';
import '../../domain/repositories/church_unit_repository.dart';
import '../datasources/church_unit_api.dart';
import '../models/church_read_models.dart';

class ChurchUnitRepositoryImpl implements ChurchUnitRepository {
  ChurchUnitRepositoryImpl(this._api);

  final ChurchUnitApi _api;

  @override
  Future<Either<Failure, ChurchUnitEntity>> getUnitById(String id) async {
    try {
      final json = await _api.getUnitById(id);
      final model = ChurchUnitReadModel.fromJson(json);
      return Right(_mapModelToEntity(model));
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 404) {
        return const Left(NotFoundFailure('Unidade nÃ£o encontrada.'));
      }
      return Left(NetworkFailure(e.message ?? 'Erro ao buscar a unidade.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChurchUnitEntity>>> getUnitsByChurchId(
    String churchId,
  ) async {
    try {
      final jsonList = await _api.getUnitsByChurchId(churchId);
      final units = jsonList
          .map(ChurchUnitReadModel.fromJson)
          .map(_mapModelToEntity)
          .toList();
      return Right(units);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 404) {
        return const Left(NotFoundFailure('Igreja nÃ£o encontrada.'));
      }
      return Left(
        NetworkFailure(e.message ?? 'Erro ao buscar unidades da igreja.'),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  ChurchUnitEntity _mapModelToEntity(ChurchUnitReadModel model) {
    return ChurchUnitEntity(
      id: model.id,
      churchId: model.churchId,
      name: model.name,
      slug: model.slug,
      type: model.type,
      address: model.address,
      phone: model.phone,
      email: model.email,
      logoUrl: model.logoUrl,
      coverUrl: model.coverUrl,
    );
  }
}
