import 'package:dio/dio.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/state/auth_notifier.dart';

class AuthRepository {
  Future<void> login(String username, String password) async {
    try {
      final response = await DioClient.dio.post(
        '/api/login/',
        data: {'username': username, 'password': password},
      );
      final access = response.data['access'] as String;
      final refresh = response.data['refresh'] as String;
      AuthNotifier().setTokens(access, refresh);
    } on DioException catch (e) {
      final message = e.response?.data?.toString() ?? 'Erro ao fazer login';
      throw Exception(message);
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    try {
      await DioClient.dio.post('/api/registro/', data: data);
    } on DioException catch (e) {
      final message = e.response?.data?.toString() ?? 'Erro ao registrar';
      throw Exception(message);
    }
  }
}
