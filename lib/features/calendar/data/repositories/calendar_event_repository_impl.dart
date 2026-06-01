import 'package:client/core/errors/failure.dart';
import 'package:client/features/calendar/data/datasources/calendar_events_api.dart';
import 'package:client/features/calendar/data/models/calendar_event_read_model.dart';
import 'package:client/features/calendar/data/models/calendar_event_request_model.dart';
import 'package:client/features/scale/data/models/calendar_event_scale_read_model.dart';
import 'package:client/features/scale/data/models/calendar_event_scale_request_model.dart';
import 'package:client/features/calendar/data/models/event_collaboration_read_model.dart';
import 'package:client/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
import 'package:client/features/calendar/domain/entities/event_collaboration_entity.dart';
import 'package:client/features/calendar/domain/repositories/calendar_event_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

class CalendarEventRepositoryImpl implements CalendarEventRepository {
  CalendarEventRepositoryImpl(this._api);

  final CalendarEventsApi _api;

  @override
  Future<Either<Failure, List<CalendarEventEntity>>> getUnitEvents(
    String unitId,
    DateTime start,
    DateTime end,
  ) {
    return _getEvents(
      () => _api.getUnitEvents(unitId, start, end),
      fallbackMessage: 'Erro ao carregar eventos da unidade.',
    );
  }

  @override
  Future<Either<Failure, List<CalendarEventEntity>>> getDepartmentEvents(
    String departmentId,
    DateTime start,
    DateTime end,
  ) {
    return _getEvents(
      () => _api.getDepartmentEvents(departmentId, start, end),
      fallbackMessage: 'Erro ao carregar eventos do departamento.',
    );
  }

  @override
  Future<Either<Failure, CalendarEventEntity>> createUnitEvent(
    String unitId,
    CalendarEventRequestModel request,
  ) {
    return _writeEvent(
      () => _api.createUnitEvent(unitId, request.toJson()),
      fallbackMessage: 'Erro ao criar evento da unidade.',
    );
  }

  @override
  Future<Either<Failure, CalendarEventEntity>> createDepartmentEvent(
    String departmentId,
    CalendarEventRequestModel request,
  ) {
    return _writeEvent(
      () => _api.createDepartmentEvent(departmentId, request.toJson()),
      fallbackMessage: 'Erro ao criar evento do departamento.',
    );
  }

  @override
  Future<Either<Failure, CalendarEventEntity>> getEventById(String eventId) {
    return _writeEvent(
      () => _api.getEventById(eventId),
      fallbackMessage: 'Erro ao carregar evento.',
    );
  }

  @override
  Future<Either<Failure, CalendarEventEntity>> updateEvent(
    String eventId,
    CalendarEventRequestModel request,
  ) {
    return _writeEvent(() async {
      final json = await _api.updateEvent(eventId, request.toJson());
      return json.isEmpty ? _api.getEventById(eventId) : json;
    }, fallbackMessage: 'Erro ao atualizar evento.');
  }

  @override
  Future<Either<Failure, List<EventCollaborationEntity>>> getCollaborators(
    String eventId,
  ) async {
    try {
      final jsonList = await _api.getCollaborators(eventId);
      final collaborators = jsonList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(EventCollaborationReadModel.fromJson)
          .map((model) => model.toEntity())
          .toList();
      return Right(collaborators);
    } on DioException catch (e) {
      return Left(_mapDioFailure(e, 'Erro ao carregar colaboradores.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EventCollaborationEntity>> addCollaborator(
    String eventId,
    String departmentId,
  ) async {
    try {
      final json = await _api.addCollaborator(eventId, departmentId);
      return Right(EventCollaborationReadModel.fromJson(json).toEntity());
    } on DioException catch (e) {
      return Left(_mapDioFailure(e, 'Erro ao adicionar colaborador.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeCollaborator(
    String eventId,
    String departmentId,
  ) {
    return _delete(
      () => _api.removeCollaborator(eventId, departmentId),
      fallbackMessage: 'Erro ao remover colaborador.',
    );
  }

  @override
  Future<Either<Failure, List<CalendarEventScaleEntity>>> getEventScales(
    String eventId,
  ) async {
    try {
      final jsonList = await _api.getEventScales(eventId);
      final scales = jsonList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(CalendarEventScaleReadModel.fromJson)
          .map((model) => model.toEntity())
          .toList();
      return Right(scales);
    } on DioException catch (e) {
      return Left(_mapDioFailure(e, 'Erro ao carregar escalas do evento.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CalendarEventScaleEntity>> createEventScale(
    String eventId,
    CalendarEventScaleRequestModel request,
  ) async {
    try {
      final json = await _api.createEventScale(eventId, request.toJson());
      return Right(CalendarEventScaleReadModel.fromJson(json).toEntity());
    } on DioException catch (e) {
      return Left(_mapDioFailure(e, 'Erro ao criar escala do evento.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CalendarEventScaleEntity>> getScaleById(
    String scaleId,
  ) async {
    try {
      final json = await _api.getScaleById(scaleId);
      return Right(CalendarEventScaleReadModel.fromJson(json).toEntity());
    } on DioException catch (e) {
      return Left(_mapDioFailure(e, 'Erro ao carregar escala.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DepartmentCalendarEventScaleEntity>>>
  getDepartmentScales(String departmentId, DateTime start, DateTime end) async {
    try {
      final jsonList = await _api.getDepartmentScales(departmentId, start, end);
      final scales = jsonList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(DepartmentCalendarEventScaleReadModel.fromJson)
          .map((model) => model.toEntity())
          .toList();
      return Right(scales);
    } on DioException catch (e) {
      return Left(
        _mapDioFailure(e, 'Erro ao carregar escalas do departamento.'),
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CalendarEventEntity>> updateCardImage(
    String eventId,
    String filePath,
  ) async {
    try {
      final file = await MultipartFile.fromFile(filePath);
      final json = await _api.updateCardImage(eventId, file);
      final eventJson = json.isEmpty ? await _api.getEventById(eventId) : json;
      return Right(CalendarEventReadModel.fromJson(eventJson).toEntity());
    } on DioException catch (e) {
      return Left(_mapDioFailure(e, 'Erro ao atualizar imagem do evento.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCardImage(String eventId) {
    return _delete(
      () => _api.deleteCardImage(eventId),
      fallbackMessage: 'Erro ao remover imagem do evento.',
    );
  }

  @override
  Future<Either<Failure, void>> deleteEvent(String eventId) {
    return _delete(
      () => _api.deleteEvent(eventId),
      fallbackMessage: 'Erro ao remover evento.',
    );
  }

  Future<Either<Failure, List<CalendarEventEntity>>> _getEvents(
    Future<List<dynamic>> Function() action, {
    required String fallbackMessage,
  }) async {
    try {
      final jsonList = await action();
      final events = jsonList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(CalendarEventReadModel.fromJson)
          .map((model) => model.toEntity())
          .toList();
      return Right(events);
    } on DioException catch (e) {
      return Left(_mapDioFailure(e, fallbackMessage));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<Either<Failure, CalendarEventEntity>> _writeEvent(
    Future<Map<String, dynamic>> Function() action, {
    required String fallbackMessage,
  }) async {
    try {
      final json = await action();
      return Right(CalendarEventReadModel.fromJson(json).toEntity());
    } on DioException catch (e) {
      return Left(_mapDioFailure(e, fallbackMessage));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> _delete(
    Future<void> Function() action, {
    required String fallbackMessage,
  }) async {
    try {
      await action();
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioFailure(e, fallbackMessage));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Failure _mapDioFailure(DioException error, String fallbackMessage) {
    final statusCode = error.response?.statusCode;
    final message = _extractErrorMessage(error, fallbackMessage);

    if (statusCode == 400 || statusCode == 403 || statusCode == 409) {
      return ValidationFailure(message);
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
}
