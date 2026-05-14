import 'dart:async';
import 'dart:typed_data';

import 'package:client/features/auth/data/datasources/auth_api.dart';
import 'package:client/features/auth/data/datasources/auth_request_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sends profile image upload as multipart file field', () async {
    final adapter = _CaptureAdapter(
      responseBody: '{"id":"user-1","username":"lisa"}',
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final api = AuthApi(dio);
    final file = MultipartFile.fromBytes([1, 2, 3], filename: 'perfil.png');

    await api.updateLoggedUserProfileImage(file);

    final data = adapter.options?.data;
    expect(adapter.options?.method, 'PUT');
    expect(adapter.options?.path, '/v1/core/people/profile-image');
    expect(data, isA<FormData>());
    final formData = data as FormData;
    expect(formData.files, hasLength(1));
    expect(formData.files.single.key, 'file');
    expect(formData.files.single.value.filename, 'perfil.png');
  });

  test('sends profile image delete to authenticated person endpoint', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = AuthApi(dio);

    await api.deleteLoggedUserProfileImage();

    expect(adapter.options?.method, 'DELETE');
    expect(adapter.options?.path, '/v1/core/people/profile-image');
  });

  test(
    'returns update logged user response payload when backend sends body',
    () async {
      final adapter = _CaptureAdapter(
        responseBody: '{"id":"user-1","username":"lisa","fullName":"Lisa"}',
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final api = AuthApi(dio);

      final response = await api.updateLoggedUser(
        const UpdateLoggedUserRequestModel(
          fullName: 'Lisa',
          gender: 'FEMALE',
          birthDate: '1998-04-09',
        ),
      );

      expect(adapter.options?.method, 'PUT');
      expect(adapter.options?.path, '/v1/core/users');
      expect(response.data?['fullName'], 'Lisa');
    },
  );

  test('returns null update logged user payload for 204 response', () async {
    final adapter = _CaptureAdapter(responseBody: '', statusCode: 204);
    final dio = Dio()..httpClientAdapter = adapter;
    final api = AuthApi(dio);

    final response = await api.updateLoggedUser(
      const UpdateLoggedUserRequestModel(
        fullName: 'Lisa',
        gender: 'FEMALE',
        birthDate: '1998-04-09',
      ),
    );

    expect(adapter.options?.method, 'PUT');
    expect(adapter.options?.path, '/v1/core/users');
    expect(response.data, isNull);
  });
}

class _CaptureAdapter implements HttpClientAdapter {
  _CaptureAdapter({this.responseBody = '{}', this.statusCode = 200});

  final String responseBody;
  final int statusCode;
  RequestOptions? options;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    this.options = options;
    return ResponseBody.fromString(
      responseBody,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
