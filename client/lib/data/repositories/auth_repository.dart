import 'package:client/core/network/api_exception.dart';
import 'package:client/core/utils/api_error_formatter.dart';
import 'package:client/data/models/auth_user_model.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:client/state/auth_notifier.dart';

class AuthRepository {
  AuthRepository({
    Dio? dio,
    AuthNotifier? authNotifier,
  }) : _dio = dio ?? DioClient.dio,
       _authNotifier = authNotifier ?? AuthNotifier();

  final Dio _dio;
  final AuthNotifier _authNotifier;

  Future<void> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/api/login/',
        data: {'username': username, 'password': password},
      );
      final access = response.data['access'] as String;
      final refresh = response.data['refresh'] as String;
      _authNotifier.setTokens(access, refresh);
    } on DioException catch (e) {
      throw ApiException(
        ApiErrorFormatter.format(
          e.response?.data,
          fallbackMessage: 'Erro ao fazer login',
        ),
      );
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/registro/', data: data);
    } on DioException catch (e) {
      throw ApiException(
        ApiErrorFormatter.format(
          e.response?.data,
          fallbackMessage: 'Erro ao registrar',
        ),
      );
    }
  }

  Future<({String access, String? refresh})> refreshSession(
    String refreshToken,
  ) async {
    try {
      final response = await _dio.post(
        '/api/refresh/',
        data: {'refresh': refreshToken},
      );

      final access = response.data['access'] as String?;
      if (access == null || access.isEmpty) {
        throw const ApiException('Erro ao renovar sessao');
      }

      return (
        access: access,
        refresh: response.data['refresh'] as String?,
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiErrorFormatter.format(
          e.response?.data,
          fallbackMessage: 'Erro ao renovar sessao',
        ),
      );
    }
  }

  Future<AuthUserModel> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/users/me/');
      return AuthUserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        ApiErrorFormatter.format(
          e.response?.data,
          fallbackMessage: 'Erro ao carregar usuario autenticado',
        ),
      );
    }
  }
}
