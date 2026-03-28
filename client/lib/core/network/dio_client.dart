import 'package:client/core/config/env.dart';
import 'package:client/data/repositories/auth_repository.dart';
import 'package:client/state/auth_notifier.dart';
import 'package:dio/dio.dart';

class DioClient {
  DioClient._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static Dio get dio {
    _initialized;
    return _dio;
  }

  // Lock para evitar "refresh storm": várias requisições 401 compartilham o mesmo refresh.
  static Future<String?>? _refreshFuture;
  static Dio Function()? _refreshDioFactory;

  static Dio _buildRefreshDio() {
    final customFactory = _refreshDioFactory;
    if (customFactory != null) {
      return customFactory();
    }

    return Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  static bool _isRefreshRequest(RequestOptions options) {
    final path = options.path;
    // Pode vir relativo ou absoluto; checar por sufixo evita problemas.
    return path.endsWith('/api/refresh/') || path.endsWith('/refresh/');
  }

  static Future<String?> _refreshAccessToken() {
    final existing = _refreshFuture;
    if (existing != null) return existing;

    _refreshFuture = () async {
      final refresh = AuthNotifier().refreshToken;
      if (refresh == null) return null;

      try {
        final response = await AuthRepository(
          dio: _buildRefreshDio(),
          authNotifier: AuthNotifier(),
        ).refreshSession(refresh);

        AuthNotifier().setTokens(
          response.access,
          response.refresh ?? refresh,
        );

        return response.access;
      } catch (_) {
        return null;
      } finally {
        _refreshFuture = null;
      }
    }();

    return _refreshFuture!;
  }

  static Future<Response<dynamic>> _retry(RequestOptions requestOptions) {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      followRedirects: requestOptions.followRedirects,
      receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
      extra: requestOptions.extra,
      validateStatus: requestOptions.validateStatus,
      receiveTimeout: requestOptions.receiveTimeout,
      sendTimeout: requestOptions.sendTimeout,
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
      cancelToken: requestOptions.cancelToken,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
    );
  }

  static void _setupInterceptors() {
    _dio.interceptors.clear();

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = AuthNotifier().accessToken;

          // Não anexar Authorization no refresh (não precisa e evita edge cases).
          if (token != null && !_isRefreshRequest(options)) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onError: (DioException error, handler) async {
          final statusCode = error.response?.statusCode;

          // Se estourou 401 numa rota normal, tentar refresh e repetir a request original.
          if (statusCode == 401 && !_isRefreshRequest(error.requestOptions)) {
            final refresh = AuthNotifier().refreshToken;
            if (refresh == null) {
              AuthNotifier().logout();
              return handler.next(error);
            }

            final newAccess = await _refreshAccessToken();
            if (newAccess == null) {
              AuthNotifier().logout();
              return handler.next(error);
            }

            // Atualiza header e repete a request original.
            error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';

            try {
              final response = await _retry(error.requestOptions);
              return handler.resolve(response);
            } on DioException catch (e) {
              return handler.next(e);
            } catch (_) {
              return handler.next(error);
            }
          }

          // Se o 401 foi no refresh, não loopar: logout.
          if (statusCode == 401 && _isRefreshRequest(error.requestOptions)) {
            AuthNotifier().logout();
          }

          handler.next(error);
        },
      ),
    );
  }

  // Inicializa interceptors uma vez.
  static final bool _initialized = (() {
    _setupInterceptors();
    return true;
  })();

  static void setRefreshDioFactoryForTest(Dio Function()? factory) {
    _refreshDioFactory = factory;
  }
}
