import 'package:dio/dio.dart';
import 'package:client/features/membership/data/models/join_membership_request_model.dart';

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
}
