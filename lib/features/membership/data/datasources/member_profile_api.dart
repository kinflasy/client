import 'package:client/features/membership/data/models/membership_model.dart';
import 'package:client/features/membership/data/models/update_inactive_person_request_model.dart';
import 'package:dio/dio.dart';

class MemberProfileApi {
  MemberProfileApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getPersonProfile(String personId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/core/people/$personId',
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getAddress(String addressId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/core/addresses/$addressId',
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<ActiveMembershipModel> getActiveMembership({
    required String unitId,
    required String personId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/core/church/units/$unitId/membership/$personId',
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Resposta vazia ao carregar membresia.');
    }
    return ActiveMembershipModel.fromJson(data);
  }

  Future<List<dynamic>> getIntegrations(String membershipId) async {
    final response = await _dio.get<List<dynamic>>(
      '/v1/core/church/unit/memberships/$membershipId/integrations',
    );
    return response.data ?? <dynamic>[];
  }

  Future<void> updateInactivePerson(
    String personId,
    UpdateInactivePersonRequestModel request,
  ) async {
    await _dio.put<void>(
      '/v1/core/inactive-people/$personId',
      data: request.toJson(),
    );
  }
}
