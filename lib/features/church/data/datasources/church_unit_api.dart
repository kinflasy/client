import 'package:dio/dio.dart';
import 'package:client/features/membership/data/models/join_membership_request_model.dart';
import 'package:client/features/membership/data/models/update_pending_membership_request_model.dart';

class ChurchUnitApi {
  ChurchUnitApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getUnitById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/core/church/units/$id',
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> getUnitsByChurchId(String churchId) async {
    final response = await _dio.get<List<dynamic>>(
      '/v1/core/churches/$churchId/units',
    );
    final data = response.data ?? <dynamic>[];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> updateUnit(
    String unitId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/v1/core/church/units/$unitId',
      data: body,
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<void> joinUnit(String unitId, JoinMembershipRequestModel body) async {
    await _dio.post<void>(
      '/v1/core/church/units/$unitId/join',
      data: body.toJson(),
    );
  }

  Future<List<Map<String, dynamic>>> getPendingMembers(String unitId) async {
    final response = await _dio.get<List<dynamic>>(
      '/v1/core/church/units/$unitId/members/pending',
    );
    final data = response.data ?? <dynamic>[];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> updatePendingMember(
    String unitId,
    UpdatePendingMembershipRequestModel body,
  ) async {
    await _dio.put<void>(
      '/v1/core/church/units/$unitId/pending-members',
      data: body.toJson(),
    );
  }

  Future<void> confirmPendingMember(String unitId, String personId) async {
    await _dio.post<void>(
      '/v1/core/church/units/$unitId/member/$personId/confirm',
    );
  }

  Future<void> rejectPendingMember(String unitId, String personId) async {
    await _dio.post<void>(
      '/v1/core/church/units/$unitId/member/$personId/reject',
    );
  }

  Future<List<Map<String, dynamic>>> getUnitLinks(String unitId) async {
    final response = await _dio.get<List<dynamic>>(
      '/v1/core/church/units/$unitId/links',
    );
    final data = response.data ?? <dynamic>[];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> createUnitLink(
    String unitId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/core/church/units/$unitId/links',
      data: body,
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateLink(
    String linkId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/v1/core/links/$linkId',
      data: body,
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<void> deleteLink(String linkId) async {
    await _dio.delete<void>('/v1/core/links/$linkId');
  }
}
