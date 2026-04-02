import 'package:dio/dio.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/membership/data/datasources/membership_api.dart';
import 'package:client/features/membership/domain/entities/membership_entity.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/membership/domain/repositories/membership_repository.dart';
import 'package:client/features/membership/data/models/membership_model.dart';
import 'package:fpdart/fpdart.dart';

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

  @override
  Future<Either<Failure, MembershipEntity>> getMembershipByUnitAndPerson(
    String unitId,
    String personId,
  ) async {
    try {
      final model = await _api.getMembershipByUnitAndPerson(unitId, personId);
      return Right(model.toEntity());
    } on DioException catch (_) {
      return const Left(
        NetworkFailure('Erro ao buscar membership da unidade.'),
      );
    } catch (_) {
      return const Left(
        UnknownFailure('Erro inesperado ao buscar membership.'),
      );
    }
  }

  @override
  Future<Either<Failure, List<IntegrationEntity>>> getIntegrationsByMembershipId(
    String membershipId,
  ) async {
    try {
      final raw = await _api.getIntegrationsByMembershipId(membershipId);
      final entities = raw.map((model) => model.toEntity()).toList();
      return Right(entities);
    } on DioException catch (_) {
      return const Left(NetworkFailure('Erro ao buscar integrações.'));
    } catch (_) {
      return const Left(
        UnknownFailure('Erro inesperado ao buscar integrações.'),
      );
    }
  }
}
