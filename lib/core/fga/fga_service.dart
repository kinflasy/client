import 'package:client/core/errors/failure.dart';
import 'package:client/core/fga/fga_config.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FgaService {
  FgaService(this._dio, this._getCurrentUserId);

  final Dio _dio;
  final Future<String?> Function() _getCurrentUserId;

  Future<bool> check({
    required String object,
    required String relation,
    Map<String, dynamic>? context,
  }) async {
    final userId = await _getCurrentUserId();
    if (userId == null || userId.isEmpty) return false;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        FgaConfig.checkUrl,
        data: {
          'authorization_model_id': FgaConfig.modelId,
          'tuple_key': {
            'user': 'user:$userId',
            'relation': relation,
            'object': object,
          },
          if (context != null && context.isNotEmpty) 'context': context,
        },
      );

      return response.data?['allowed'] == true;
    } on DioException catch (error) {
      throw NetworkFailure(
        'Nao foi possivel verificar permissoes no FGA: ${error.message}',
      );
    } catch (_) {
      throw const UnknownFailure(
        'Nao foi possivel verificar permissoes no FGA.',
      );
    }
  }
}

final fgaDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );
});

final fgaServiceProvider = Provider<FgaService>((ref) {
  return FgaService(
    ref.watch(fgaDioProvider),
    () async => (await ref.read(authProvider.future))?.id,
  );
});
