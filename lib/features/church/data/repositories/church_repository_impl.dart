import 'package:fpdart/fpdart.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/church_entity.dart';
import '../../domain/repositories/church_repository.dart';
import '../datasources/church_api.dart';
import '../models/church_request_model.dart';

class ChurchRepositoryImpl implements ChurchRepository {
  final ChurchApi _api;

  ChurchRepositoryImpl(this._api);

  @override
  Future<Either<Failure, ChurchEntity>> createChurch(
    ChurchStarterRequestModel request,
  ) async {
    try {
      final model = await _api.createChurch(request.toJson());
      return Right(
        ChurchEntity(
          id: model.id,
          name: model.name,
          slug: model.slug,
          acronym: model.acronym,
          phone: model.phone,
          email: model.email,
        ),
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400 || statusCode == 409) {
        final message =
            e.response?.data?['message'] as String? ??
            'Dados inválidos. Verifique as informações e tente novamente.';
        return Left(ValidationFailure(message));
      }
      return Left(
        NetworkFailure(e.message ?? 'Erro de rede. Tente novamente.'),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChurchEntity>> getChurchById(String id) async {
    try {
      final model = await _api.getChurchById(id);
      return Right(
        ChurchEntity(
          id: model.id,
          name: model.name,
          slug: model.slug,
          acronym: model.acronym,
          phone: model.phone,
          email: model.email,
          coverUrl: model.coverUrl,
          logoUrl: model.logoUrl,
          address: model.address,
          website: model.website,
          instagramUrl: model.instagramUrl,
          youtubeUrl: model.youtubeUrl,
          spotifyUrl: model.spotifyUrl,
          whatsappNumber: model.whatsappNumber,
          isHeadquarters: model.isHeadquarters,
          parentChurchId: model.parentChurchId,
          parentChurchAcronym: model.parentChurchAcronym,
        ),
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 404) {
        return const Left(NotFoundFailure('Igreja não encontrada.'));
      }
      return Left(
        NetworkFailure(e.message ?? 'Erro ao buscar os dados da igreja.'),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
