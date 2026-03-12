import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/membership/data/datasources/membership_api.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/domain/repositories/membership_repository.dart';
import 'package:client/features/membership/data/models/membership_model.dart';

class MembershipRepositoryImpl implements MembershipRepository {
  final MembershipApi _api;

  MembershipRepositoryImpl(this._api);

  @override
  Future<Either<Failure, List<MembershipEntity>>> getMyMemberships() async {
    try {
      final models = await _api.getMyMemberships();
      // Converte cada MembershipModel para MembershipEntity
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (_) {
      return Left(NetworkFailure('Erro ao buscar membresias'));
    } catch (_) {
      return Left(UnknownFailure('Erro inesperado'));
    }
  }
}