import 'package:client/features/membership/data/models/membership_model.dart';
import 'package:client/features/membership/data/models/pending_membership_model.dart';
import 'package:dio/dio.dart';

class MembershipApi {
  MembershipApi(this._dio);

  final Dio _dio;

  Future<List<MembershipModel>> getMyMemberships() async {
    final response = await _dio.get<dynamic>('/v1/core/church/units');
    return _readList(response.data)
        .map(_readMembershipMap)
        .where((item) => item.isNotEmpty)
        .map(MembershipModel.fromJson)
        .toList();
  }

  Future<List<PendingMembershipModel>> getMyPendingMemberships() async {
    final response = await _dio.get<dynamic>(
      '/v1/core/church/unit/memberships/pending',
    );
    return _readList(response.data)
        .map(_readMap)
        .where((item) => item.isNotEmpty)
        .map(PendingMembershipModel.fromJson)
        .toList();
  }

  List<dynamic> _readList(Object? data) {
    if (data is List) return data;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in const ['content', 'items', 'data', 'memberships']) {
        final value = map[key];
        if (value is List) return value;
      }
    }

    return <dynamic>[];
  }

  Map<String, dynamic> _readMembershipMap(Object? value) {
    final map = _readMap(value);
    if (map.isEmpty) return map;

    if (map['unit'] is! Map) {
      return map;
    }

    final unit = Map<String, dynamic>.from(map['unit'] as Map);
    final normalized = Map<String, dynamic>.from(map);
    final unitId = _readOptionalString(unit, 'id');
    final unitName = _readOptionalString(unit, 'name');
    final unitLogoUrl = _readOptionalString(unit, 'logoUrl');
    final unitProfileImageId = _readOptionalString(unit, 'profileImageId');

    if (normalized['unitId'] == null && unitId != null) {
      normalized['unitId'] = unitId;
    }
    if (unitName != null) {
      normalized['unitName'] = unitName;
    }
    if (unitLogoUrl != null) {
      normalized['unitLogoUrl'] = unitLogoUrl;
    }
    if (unitProfileImageId != null) {
      normalized['unitProfileImageId'] = unitProfileImageId;
    }

    return normalized;
  }

  Map<String, dynamic> _readMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);

    if (value is List) {
      for (final item in value) {
        final map = _readMap(item);
        if (map.isNotEmpty) return map;
      }
    }

    return const <String, dynamic>{};
  }

  String? _readOptionalString(Map<String, dynamic> map, String key) {
    final value = map[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }
}
