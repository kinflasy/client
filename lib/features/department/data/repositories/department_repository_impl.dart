import 'package:client/core/errors/failure.dart';
import 'package:client/core/domain/enums/integration_type.dart';
import 'package:client/features/church/data/models/church_read_models.dart';
import 'package:client/features/department/data/datasources/department_api.dart';
import 'package:client/features/department/data/models/department_request_model.dart';
import 'package:client/features/department/data/models/integration_request_model.dart';
import 'package:client/features/department/data/models/lineup_item_request_model.dart';
import 'package:client/features/department/data/models/lineup_request_model.dart';
import 'package:client/features/department/data/models/role_request_model.dart';
import 'package:client/features/department/domain/entities/department_detail_entity.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/domain/entities/department_participant_entity.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

class DepartmentRepositoryImpl implements DepartmentRepository {
  DepartmentRepositoryImpl(this._api);

  final DepartmentApi _api;

  @override
  Future<Either<Failure, List<DepartmentEntity>>> getDepartmentsByUnitId(
    String unitId,
  ) async {
    try {
      final jsonList = await _api.getDepartmentsByUnitId(unitId);
      final departments = jsonList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(DepartmentReadModel.fromJson)
          .where((model) => model.id.isNotEmpty)
          .map(_mapModelToEntity)
          .toList();
      return Right(departments);
    } on DioException catch (e) {
      return Left(
        NetworkFailure(e.message ?? 'Erro ao carregar departamentos.'),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DepartmentEntity>> createDepartment(
    String unitId,
    DepartmentRequestModel request,
  ) async {
    try {
      final json = await _api.createDepartment(unitId, request.toJson());
      final model = DepartmentReadModel.fromJson(json);
      return Right(_mapModelToEntity(model));
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400 || statusCode == 409) {
        final message =
            e.response?.data?['message'] as String? ??
            'Dados invalidos. Verifique as informacoes e tente novamente.';
        return Left(ValidationFailure(message));
      }
      return Left(NetworkFailure(e.message ?? 'Erro ao criar departamento.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DepartmentDetailEntity>> getDepartmentById(
    String departmentId,
  ) async {
    try {
      final json = await _api.getDepartmentById(departmentId);
      final department = _mapDetailJsonToEntity(json);
      return Right(department);
    } on DioException catch (e) {
      return Left(
        NetworkFailure(e.message ?? 'Erro ao carregar departamento.'),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DepartmentParticipantEntity>>> getParticipants(
    String departmentId,
  ) async {
    try {
      final jsonList = await _api.getParticipants(departmentId);
      final participants = jsonList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_mapParticipantJsonToEntity)
          .where((participant) => participant.personId.isNotEmpty)
          .toList();

      return Right(participants);
    } on DioException catch (e) {
      return Left(
        NetworkFailure(e.message ?? 'Erro ao carregar participantes.'),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addParticipant(
    String departmentId,
    IntegrationRequestModel request,
  ) async {
    try {
      await _api.addParticipant(departmentId, request.toJson());
      return const Right(unit);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400 || statusCode == 403 || statusCode == 409) {
        final message =
            _readMap(e.response?.data)['message'] as String? ??
            'Não foi possível adicionar este participante.';
        return Left(ValidationFailure(message));
      }
      return Left(
        NetworkFailure(e.message ?? 'Erro ao adicionar participante.'),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateParticipantRole(
    String departmentId,
    IntegrationRequestModel request,
  ) async {
    try {
      await _api.updateParticipantRole(departmentId, request.toJson());
      return const Right(unit);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400 || statusCode == 403 || statusCode == 409) {
        return Left(
          ValidationFailure(
            _readMessage(e.response?.data) ??
                'Não foi possível alterar o papel deste participante.',
          ),
        );
      }
      if (statusCode == 404) {
        return Left(
          NotFoundFailure(
            _readMessage(e.response?.data) ??
                'Participante não encontrado neste ministério.',
          ),
        );
      }
      return Left(
        NetworkFailure(e.message ?? 'Erro ao alterar papel do participante.'),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeParticipant(
    String departmentId,
    IntegrationRequestModel request,
  ) async {
    try {
      await _api.removeParticipant(departmentId, request.toJson());
      return const Right(unit);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400 || statusCode == 403 || statusCode == 409) {
        return Left(
          ValidationFailure(
            _readMessage(e.response?.data) ??
                'Não foi possível retirar este participante.',
          ),
        );
      }
      if (statusCode == 404) {
        return Left(
          NotFoundFailure(
            _readMessage(e.response?.data) ??
                'Participante não encontrado neste ministério.',
          ),
        );
      }
      return Left(NetworkFailure(e.message ?? 'Erro ao retirar participante.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RoleEntity>>> getRoles() async {
    try {
      final jsonList = await _api.getRoles();
      final roles = jsonList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_mapRoleJsonToEntity)
          .where((role) => role.id.isNotEmpty)
          .toList();
      return Right(roles);
    } on DioException catch (e) {
      return Left(_mapDioFailure(e, 'Erro ao carregar papéis.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoleEntity>> createRole(
    RoleRequestModel request,
  ) async {
    try {
      final json = await _api.createRole(request.toJson());
      return Right(_mapRoleJsonToEntity(json));
    } on DioException catch (e) {
      return Left(_mapDioFailure(e, 'Erro ao criar papel.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LineupEntity>>> getDepartmentLineups(
    String departmentId,
  ) async {
    try {
      final jsonList = await _api.getDepartmentLineups(departmentId);
      final lineups = jsonList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_mapLineupJsonToEntity)
          .where((lineup) => lineup.id.isNotEmpty)
          .toList();
      return Right(lineups);
    } on DioException catch (e) {
      return Left(_mapDioFailure(e, 'Erro ao carregar formações.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LineupEntity>> createDepartmentLineup(
    String departmentId,
    LineupRequestModel request,
  ) async {
    try {
      final json = await _api.createDepartmentLineup(
        departmentId,
        request.toJson(),
      );
      return Right(_mapLineupJsonToEntity(json));
    } on DioException catch (e) {
      return Left(_mapDioFailure(e, 'Erro ao criar formação.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LineupEntity>> getLineupById(String lineupId) async {
    try {
      final json = await _api.getLineupById(lineupId);
      return Right(_mapLineupJsonToEntity(json));
    } on DioException catch (e) {
      return Left(
        _mapDioFailure(
          e,
          'Erro ao carregar formação.',
          notFoundMessage: 'Formação não encontrada.',
        ),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LineupEntity>> getLineupWithItems(
    String lineupId,
  ) async {
    try {
      final json = await _api.getLineupWithItems(lineupId);
      return Right(_mapLineupJsonToEntity(json));
    } on DioException catch (e) {
      return Left(
        _mapDioFailure(
          e,
          'Erro ao carregar formação.',
          notFoundMessage: 'Formação não encontrada.',
        ),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LineupEntity>> updateLineup(
    String lineupId,
    LineupRequestModel request,
  ) async {
    try {
      final json = await _api.updateLineup(lineupId, request.toJson());
      final lineupJson = json.isEmpty
          ? await _api.getLineupById(lineupId)
          : json;
      return Right(_mapLineupJsonToEntity(lineupJson));
    } on DioException catch (e) {
      return Left(
        _mapDioFailure(
          e,
          'Erro ao atualizar formação.',
          notFoundMessage: 'Formação não encontrada.',
        ),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteLineup(String lineupId) async {
    try {
      await _api.deleteLineup(lineupId);
      return const Right(unit);
    } on DioException catch (e) {
      return Left(
        _mapDioFailure(
          e,
          'Erro ao remover formação.',
          notFoundMessage: 'Formação não encontrada.',
        ),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LineupItemEntity>>> getLineupItems(
    String lineupId,
  ) async {
    try {
      final jsonList = await _api.getLineupItems(lineupId);
      final items = jsonList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_mapLineupItemJsonToEntity)
          .where(_isValidLineupItem)
          .toList();
      return Right(items);
    } on DioException catch (e) {
      return Left(
        _mapDioFailure(
          e,
          'Erro ao carregar itens da formação.',
          notFoundMessage: 'Formação não encontrada.',
        ),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LineupItemEntity>> createLineupItem(
    String lineupId,
    LineupItemRequestModel request,
  ) async {
    try {
      final json = await _api.createLineupItem(lineupId, request.toJson());
      return Right(_mapLineupItemJsonToEntity(json));
    } on DioException catch (e) {
      return Left(
        _mapDioFailure(
          e,
          'Erro ao criar item da formação.',
          notFoundMessage: 'Formação não encontrada.',
        ),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LineupItemEntity>> updateLineupItem(
    String itemId,
    LineupItemUpdateRequestModel request,
  ) async {
    try {
      final json = await _api.updateLineupItem(itemId, request.toJson());
      return Right(_mapLineupItemJsonToEntity(json));
    } on DioException catch (e) {
      return Left(
        _mapDioFailure(
          e,
          'Erro ao atualizar item da formação.',
          notFoundMessage: 'Item da formação não encontrado.',
        ),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteLineupItem(String itemId) async {
    try {
      await _api.deleteLineupItem(itemId);
      return const Right(unit);
    } on DioException catch (e) {
      return Left(
        _mapDioFailure(
          e,
          'Erro ao remover item da formação.',
          notFoundMessage: 'Item da formação não encontrado.',
        ),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  DepartmentEntity _mapModelToEntity(DepartmentReadModel model) {
    return DepartmentEntity(
      id: model.id,
      name: model.name,
      slug: model.slug,
      type: model.type,
    );
  }

  RoleEntity _mapRoleJsonToEntity(Map<String, dynamic> json) {
    return RoleEntity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }

  LineupEntity _mapLineupJsonToEntity(Map<String, dynamic> json) {
    final lineupJson = _unwrapLineupJson(json);
    final items = _readList(lineupJson['items'])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(_mapLineupItemJsonToEntity)
        .where(_isValidLineupItem)
        .toList();

    return LineupEntity(
      id: _readString(lineupJson, const ['id', 'lineupId', 'uuid']),
      name: lineupJson['name'] as String? ?? '',
      items: lineupJson.containsKey('items') ? items : null,
    );
  }

  LineupItemEntity _mapLineupItemJsonToEntity(Map<String, dynamic> json) {
    final roleMap = _readMap(json['role']);
    final role = roleMap.isEmpty ? null : _mapRoleJsonToEntity(roleMap);
    final roleId = json['roleId'] as String? ?? role?.id ?? '';

    return LineupItemEntity(
      id: json['id'] as String? ?? '',
      lineupId: json['lineupId'] as String? ?? '',
      roleId: roleId,
      description: json['description'] as String? ?? '',
      role: role,
    );
  }

  DepartmentDetailEntity _mapDetailJsonToEntity(Map<String, dynamic> json) {
    return DepartmentDetailEntity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      type: json['type'] as String?,
    );
  }

  DepartmentParticipantEntity _mapParticipantJsonToEntity(
    Map<String, dynamic> json,
  ) {
    final membership = _readMap(json['membership']);
    final person = _readMap(membership['person']);

    return DepartmentParticipantEntity(
      personId: person['id'] as String? ?? '',
      membershipId: membership['id'] as String? ?? '',
      integrationType: IntegrationType.fromString(
        json['type'] as String? ?? '',
      ),
      nickname: person['nickname'] as String?,
      username: person['username'] as String?,
      phone: membership['phone'] as String? ?? person['phone'] as String?,
      profileImageId: person['profileImageId'] as String?,
      affiliation: membership['affiliation'] as String? ?? '',
      gender: person['gender'] as String? ?? '',
      birthDate: _parseDate(person['birthDate']),
      age: _parseInt(person['age']),
    );
  }

  DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Map<String, dynamic> _readMap(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _unwrapLineupJson(Map<String, dynamic> json) {
    if (_readString(json, const ['id', 'lineupId', 'uuid']).isNotEmpty) {
      return json;
    }

    for (final key in const [
      'lineup',
      'departmentLineup',
      'unitLineup',
      'data',
      'content',
    ]) {
      final nested = _readMap(json[key]);
      if (nested.isNotEmpty) return _unwrapLineupJson(nested);
    }

    return json;
  }

  String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return '';
  }

  List<dynamic> _readList(Object? value) {
    if (value is List) return value;
    return const <dynamic>[];
  }

  String? _readMessage(Object? value) => _readMap(value)['message'] as String?;

  bool _isValidLineupItem(LineupItemEntity item) {
    return item.id.isNotEmpty && item.roleId.isNotEmpty;
  }

  Failure _mapDioFailure(
    DioException error,
    String fallbackMessage, {
    String? notFoundMessage,
  }) {
    final statusCode = error.response?.statusCode;
    final message = _extractErrorMessage(error, fallbackMessage);

    if (statusCode == 400 || statusCode == 403 || statusCode == 409) {
      return ValidationFailure(message);
    }

    if (statusCode == 404 && notFoundMessage != null) {
      return NotFoundFailure(_extractErrorMessage(error, notFoundMessage));
    }

    return NetworkFailure(message);
  }

  String _extractErrorMessage(DioException error, String fallbackMessage) {
    final data = error.response?.data;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = map['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;

      final errorText = map['error']?.toString().trim();
      if (errorText != null && errorText.isNotEmpty) return errorText;
    }

    if (data is String) {
      final text = data.trim();
      if (text.isNotEmpty) return text;
    }

    return error.message ?? fallbackMessage;
  }

  int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
