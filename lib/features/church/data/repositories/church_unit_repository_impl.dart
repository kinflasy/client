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
      return Right(
        ChurchUnitEntity(
          id: model.id,
          churchId: model.churchId,
          name: model.name,
          slug: model.slug,
        ),
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 404) {
        return const Left(NotFoundFailure('Unidade não encontrada.'));
      }
      return Left(NetworkFailure(e.message ?? 'Erro ao buscar a unidade.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
