import 'package:dio/dio.dart';
import 'package:client/state/auth_notifier.dart';

class DioClient {
  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: 'http://127.0.0.1:8000',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              final token = AuthNotifier().accessToken;
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
            onError: (DioException error, handler) {
              if (error.response?.statusCode == 401) {
                AuthNotifier().logout();
              }
              handler.next(error);
            },
          ),
        );
}
