import 'package:client/core/errors/failure.dart';
import 'package:client/features/membership/data/datasources/unit_member_api.dart';
import 'package:client/features/membership/data/models/register_member_request_model.dart';
import 'package:client/features/membership/domain/repositories/unit_member_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

class UnitMemberRepositoryImpl implements UnitMemberRepository {
  UnitMemberRepositoryImpl(this._api);

  final UnitMemberApi _api;

  @override
  Future<Either<Failure, void>> registerMember(
    String unitId,
    RegisterMemberRequestModel request,
  ) async {
    try {
      await _api.registerMember(unitId, request.toJson());
      return const Right(null);
    } on DioException catch (_) {
      return const Left(NetworkFailure('Erro ao cadastrar membro'));
    } catch (_) {
      return const Left(UnknownFailure('Erro inesperado'));
    }
  }
}
