import 'package:client/features/membership/data/models/join_membership_request_model.dart';
import 'package:client/features/membership/data/models/pending_unit_membership_model.dart';
import 'package:client/features/membership/data/models/update_pending_membership_request_model.dart';
import 'package:client/features/membership/domain/entities/pending_unit_membership_entity.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/church_link_entity.dart';
import '../../domain/entities/church_unit_entity.dart';
import '../../domain/repositories/church_unit_repository.dart';
import '../datasources/church_unit_api.dart';
import '../models/church_link_models.dart';
import '../models/church_read_models.dart';
import '../models/church_request_model.dart';

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
  Future<Either<Failure, ChurchUnitEntity>> updateUnit(
    String unitId,
    UnitRequestModel request,
  ) async {
    try {
      final json = await _api.updateUnit(unitId, request.toJson());
      final model = ChurchUnitReadModel.fromJson(json);
      return Right(_mapModelToEntity(model));
    } on DioException catch (e) {
      return Left(
        NetworkFailure(_extractErrorMessage(e, 'Erro ao atualizar a unidade.')),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChurchUnitEntity>> updateUnitProfileImage(
    String unitId,
    String filePath,
  ) {
    return _updateUnitImage(
      unitId: unitId,
      filePath: filePath,
      upload: _api.updateUnitProfileImage,
      fallbackMessage: 'Erro ao atualizar a foto da unidade.',
    );
  }

  @override
  Future<Either<Failure, ChurchUnitEntity>> updateUnitCoverImage(
    String unitId,
    String filePath,
  ) {
    return _updateUnitImage(
      unitId: unitId,
      filePath: filePath,
      upload: _api.updateUnitCoverImage,
      fallbackMessage: 'Erro ao atualizar a capa da unidade.',
    );
  }

  @override
  Future<Either<Failure, void>> deleteUnitProfileImage(String unitId) {
    return _deleteUnitImage(
      () => _api.deleteUnitProfileImage(unitId),
      fallbackMessage: 'Erro ao remover a foto da unidade.',
    );
  }

  @override
  Future<Either<Failure, void>> deleteUnitCoverImage(String unitId) {
    return _deleteUnitImage(
      () => _api.deleteUnitCoverImage(unitId),
      fallbackMessage: 'Erro ao remover a capa da unidade.',
    );
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
  Future<Either<Failure, void>> updatePendingMember(
    String unitId,
    String personId,
    String affiliation,
  ) async {
    return _runPendingMembershipAction(
      () => _api.updatePendingMember(
        unitId,
        UpdatePendingMembershipRequestModel(
          personId: personId,
          affiliation: affiliation,
        ),
      ),
      fallbackMessage: 'Erro ao atualizar solicitacao de vinculo.',
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

  @override
  Future<Either<Failure, List<ChurchLinkEntity>>> getUnitLinks(
    String unitId,
  ) async {
    try {
      final jsonList = await _api.getUnitLinks(unitId);
      final links = jsonList
          .map(ChurchLinkReadModel.fromJson)
          .map(_mapLinkModelToEntity)
          .toList();
      return Right(links);
    } on DioException catch (e) {
      return Left(
        NetworkFailure(
          _extractErrorMessage(e, 'Erro ao buscar links da unidade.'),
        ),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChurchLinkEntity>> createUnitLink(
    String unitId,
    ChurchLinkRequestModel request,
  ) async {
    try {
      final json = await _api.createUnitLink(unitId, request.toJson());
      return Right(_mapLinkModelToEntity(ChurchLinkReadModel.fromJson(json)));
    } on DioException catch (e) {
      return Left(
        NetworkFailure(
          _extractErrorMessage(e, 'Erro ao criar link da unidade.'),
        ),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChurchLinkEntity>> updateLink(
    String linkId,
    ChurchLinkRequestModel request,
  ) async {
    try {
      final json = await _api.updateLink(linkId, request.toJson());
      return Right(_mapLinkModelToEntity(ChurchLinkReadModel.fromJson(json)));
    } on DioException catch (e) {
      return Left(
        NetworkFailure(_extractErrorMessage(e, 'Erro ao atualizar link.')),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLink(String linkId) async {
    try {
      await _api.deleteLink(linkId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(
        NetworkFailure(_extractErrorMessage(e, 'Erro ao remover link.')),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
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

  Future<Either<Failure, ChurchUnitEntity>> _updateUnitImage({
    required String unitId,
    required String filePath,
    required Future<Map<String, dynamic>> Function(
      String unitId,
      MultipartFile file,
    )
    upload,
    required String fallbackMessage,
  }) async {
    try {
      final file = await MultipartFile.fromFile(filePath);
      final json = await upload(unitId, file);
      final unitJson = json.isEmpty ? await _api.getUnitById(unitId) : json;
      final model = ChurchUnitReadModel.fromJson(unitJson);
      return Right(_mapModelToEntity(model));
    } on DioException catch (e) {
      return Left(
        NetworkFailure(_extractUploadErrorMessage(e, fallbackMessage)),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> _deleteUnitImage(
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

  String _extractUploadErrorMessage(
    DioException error,
    String fallbackMessage,
  ) {
    if (error.response?.statusCode == 413) {
      return _extractErrorMessage(
        error,
        'Arquivo muito grande. Envie uma imagem de até 2 MB.',
      );
    }

    return _extractErrorMessage(error, fallbackMessage);
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
      addressValue: model.addressValue,
      phone: model.phone,
      email: model.email,
      logoUrl: model.logoUrl,
      coverUrl: model.coverUrl,
      profileImageId: model.profileImageId,
      coverImageId: model.coverImageId,
    );
  }

  ChurchLinkEntity _mapLinkModelToEntity(ChurchLinkReadModel model) {
    return ChurchLinkEntity(id: model.id, label: model.label, url: model.url);
  }
}
