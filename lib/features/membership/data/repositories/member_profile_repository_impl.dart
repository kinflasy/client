import 'package:client/core/errors/failure.dart';
import 'package:client/features/membership/data/datasources/member_profile_api.dart';
import 'package:client/features/membership/data/models/address_model.dart';
import 'package:client/features/membership/data/models/integration_model.dart';
import 'package:client/features/membership/data/models/membership_model.dart';
import 'package:client/features/membership/data/models/person_profile_model.dart';
import 'package:client/features/membership/data/models/update_inactive_person_request_model.dart';
import 'package:client/features/membership/domain/entities/integration_entity.dart';
import 'package:client/features/membership/domain/repositories/member_profile_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

class MemberProfileRepositoryImpl implements MemberProfileRepository {
  MemberProfileRepositoryImpl(this._api);

  final MemberProfileApi _api;

  @override
  Future<Either<Failure, PersonProfileModel>> getPersonProfile(
    String personId,
  ) async {
    try {
      final json = await _api.getPersonProfile(personId);
      return Right(PersonProfileModel.fromJson(json));
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 404) {
        return const Left(NotFoundFailure('Pessoa nao encontrada.'));
      }
      return Left(
        NetworkFailure(error.message ?? 'Erro ao carregar dados da pessoa.'),
      );
    } on FormatException {
      return const Left(
        ServerFailure('Resposta inesperada ao carregar dados da pessoa.'),
      );
    } catch (_) {
      return const Left(
        UnknownFailure('Nao foi possivel carregar os dados da pessoa.'),
      );
    }
  }

  @override
  Future<Either<Failure, AddressModel>> getAddress(String addressId) async {
    try {
      final json = await _api.getAddress(addressId);
      return Right(AddressModel.fromJson(json));
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 404) {
        return const Left(NotFoundFailure('Endereco nao encontrado.'));
      }
      return Left(
        NetworkFailure(error.message ?? 'Erro ao carregar endereco.'),
      );
    } catch (_) {
      return const Left(
        UnknownFailure('Nao foi possivel carregar o endereco.'),
      );
    }
  }

  @override
  Future<Either<Failure, ActiveMembershipModel>> getActiveMembership({
    required String unitId,
    required String personId,
  }) async {
    try {
      final membership = await _api.getActiveMembership(
        unitId: unitId,
        personId: personId,
      );
      if (membership.id.isEmpty) {
        return const Left(
          ServerFailure('Resposta inesperada ao carregar a membresia.'),
        );
      }
      return Right(membership);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 404) {
        return const Left(
          NotFoundFailure('Pessoa sem membresia ativa na unidade atual.'),
        );
      }
      return Left(
        NetworkFailure(error.message ?? 'Erro ao carregar a membresia.'),
      );
    } on FormatException {
      return const Left(
        ServerFailure('Resposta inesperada ao carregar a membresia.'),
      );
    } catch (_) {
      return const Left(
        UnknownFailure('Nao foi possivel carregar a membresia ativa.'),
      );
    }
  }

  @override
  Future<Either<Failure, List<IntegrationEntity>>> getIntegrations(
    String membershipId,
  ) async {
    try {
      final data = await _api.getIntegrations(membershipId);
      final integrations = data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(IntegrationModel.fromJson)
          .map((model) => model.toEntity())
          .toList();
      return Right(integrations);
    } on DioException catch (error) {
      return Left(
        NetworkFailure(error.message ?? 'Erro ao carregar integracoes.'),
      );
    } catch (_) {
      return const Left(
        UnknownFailure('Nao foi possivel carregar as integracoes.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> updateInactivePerson({
    required String personId,
    required UpdateInactivePersonRequestModel request,
  }) async {
    try {
      await _api.updateInactivePerson(personId, request);
      return const Right(null);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 404) {
        return const Left(NotFoundFailure('Pessoa inativa nao encontrada.'));
      }
      if (statusCode == 400 || statusCode == 422) {
        final message = error.response?.data is Map<String, dynamic>
            ? (error.response?.data as Map<String, dynamic>)['message']
                  ?.toString()
            : null;
        return Left(
          ValidationFailure(
            message ?? 'Nao foi possivel validar os dados informados.',
          ),
        );
      }
      return Left(
        NetworkFailure(error.message ?? 'Erro ao atualizar a pessoa inativa.'),
      );
    } on FormatException {
      return const Left(
        ServerFailure('Resposta inesperada ao atualizar a pessoa inativa.'),
      );
    } catch (_) {
      return const Left(
        UnknownFailure('Nao foi possivel atualizar a pessoa inativa.'),
      );
    }
  }
}
