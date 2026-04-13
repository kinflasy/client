import 'package:dio/dio.dart';

class FgaAuthInterceptor extends Interceptor {
  static const _token = 'your-api-token-123456';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.headers['Authorization'] = 'Bearer $_token';
    handler.next(options);
  }
}
