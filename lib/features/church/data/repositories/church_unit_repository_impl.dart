import 'package:client/features/membership/data/models/join_membership_request_model.dart';
import 'package:client/features/membership/data/models/pending_unit_membership_model.dart';
import 'package:client/features/membership/domain/entities/pending_unit_membership_entity.dart';
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
      return Left(
        NetworkFailure(_extractErrorMessage(e, 'Erro ao buscar a unidade.')),
      );
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
        NetworkFailure(
          _extractErrorMessage(e, 'Erro ao buscar unidades da igreja.'),
        ),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> joinUnit(
    String unitId,
    String affiliation,
  ) async {
    try {
      await _api.joinUnit(
        unitId,
        JoinMembershipRequestModel(affiliation: affiliation),
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(
        NetworkFailure(
          _extractErrorMessage(e, 'Erro ao solicitar vinculo para a unidade.'),
        ),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PendingUnitMembershipEntity>>> getPendingMembers(
    String unitId,
  ) async {
    try {
      final jsonList = await _api.getPendingMembers(unitId);
      final items = jsonList
          .map(PendingUnitMembershipModel.fromJson)
          .map((model) => model.toEntity())
          .toList();
      return Right(items);
    } on DioException catch (e) {
      return Left(
        NetworkFailure(
          _extractErrorMessage(
            e,
            'Erro ao buscar solicitacoes pendentes da unidade.',
          ),
        ),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> confirmPendingMember(
    String unitId,
    String personId,
  ) async {
    return _runPendingMembershipAction(
      () => _api.confirmPendingMember(unitId, personId),
      fallbackMessage: 'Erro ao aprovar solicitacao de vinculo.',
    );
  }

  @override
  Future<Either<Failure, void>> rejectPendingMember(
    String unitId,
    String personId,
  ) async {
    return _runPendingMembershipAction(
      () => _api.rejectPendingMember(unitId, personId),
      fallbackMessage: 'Erro ao rejeitar solicitacao de vinculo.',
    );
  }

  Future<Either<Failure, void>> _runPendingMembershipAction(
    Future<void> Function() action, {
    required String fallbackMessage,
  }) async {
    try {
      await action();
      return const Right(null);
    } on DioException catch (e) {
      return Left(NetworkFailure(_extractErrorMessage(e, fallbackMessage)));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  String _extractErrorMessage(DioException error, String fallbackMessage) {
    final data = error.response?.data;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = map['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }

      final errorText = map['error']?.toString().trim();
      if (errorText != null && errorText.isNotEmpty) {
        return errorText;
      }
    }

    if (data is String) {
      final text = data.trim();
      if (text.isNotEmpty) {
        return text;
      }
    }

    return error.message ?? fallbackMessage;
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
