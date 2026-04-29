import 'package:client/core/errors/failure.dart';
import 'package:client/features/membership/data/datasources/membership_api.dart';
import 'package:client/features/membership/data/models/membership_model.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/domain/entities/pending_membership_entity.dart';
import 'package:client/features/membership/domain/repositories/membership_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

class MembershipRepositoryImpl implements MembershipRepository {
  MembershipRepositoryImpl(this._api);

  final MembershipApi _api;

  @override
  Future<Either<Failure, List<MembershipEntity>>> getMyMemberships() async {
    try {
      final models = await _api.getMyMemberships();
      return Right(models.map((model) => model.toEntity()).toList());
    } on DioException catch (_) {
      return Left(NetworkFailure('Erro ao buscar membresias'));
    } catch (_) {
      return Left(UnknownFailure('Erro inesperado'));
    }
  }

  @override
  Future<Either<Failure, List<PendingMembershipEntity>>>
  getMyPendingMemberships() async {
    try {
      final models = await _api.getMyPendingMemberships();
      return Right(models.map((model) => model.toEntity()).toList());
    } on DioException catch (_) {
      return Left(NetworkFailure('Erro ao buscar solicitacoes pendentes'));
    } catch (_) {
      return Left(UnknownFailure('Erro inesperado'));
    }
  }
}
