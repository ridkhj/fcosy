import 'package:client/core/network/api_exception.dart';
import 'package:client/data/repositories/auth_repository.dart';
import 'package:client/state/auth_notifier.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_dio.dart';

void main() {
  group('AuthRepository', () {
    late RequestOptions capturedRequest;

    setUp(() {
      AuthNotifier().logout();
    });

    test('login sends correct payload and stores tokens', () async {
      final dio = createMockDio((request) {
        capturedRequest = request;
        return mockResponse(
          request,
          data: {
            'access': 'access-token',
            'refresh': 'refresh-token',
          },
        );
      });

      final repository = AuthRepository(dio: dio);

      await repository.login('ricardo123', 'senhaSegura');

      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.path, '/api/login/');
      expect(capturedRequest.data, {
        'username': 'ricardo123',
        'password': 'senhaSegura',
      });
      expect(AuthNotifier().accessToken, 'access-token');
      expect(AuthNotifier().refreshToken, 'refresh-token');
    });

    test('register sends current API payload', () async {
      final dio = createMockDio((request) {
        capturedRequest = request;
        return mockResponse(request, statusCode: 201, data: {
          'id': 1,
        });
      });

      final repository = AuthRepository(dio: dio);
      final data = {
        'username': 'ricardo123',
        'email': 'ricardo@email.com',
        'senha': 'minhaSenhaSegura',
        'primeiro_nome': 'Ricardo',
        'sobrenome': 'Silva',
        'idade': 25,
        'numero': '+5511987654321',
      };

      await repository.register(data);

      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.path, '/api/registro/');
      expect(capturedRequest.data, data);
    });

    test('getCurrentUser fetches authenticated user', () async {
      final dio = createMockDio((request) {
        capturedRequest = request;
        return mockResponse(
          request,
          data: {
            'id': 1,
            'username': 'ricardo123',
            'email': 'ricardo@email.com',
            'perfil': {
              'primeiro_nome': 'Ricardo',
              'sobrenome': 'Silva',
              'idade': 25,
            },
          },
        );
      });

      final repository = AuthRepository(dio: dio);
      final user = await repository.getCurrentUser();

      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.path, '/api/users/me/');
      expect(user.username, 'ricardo123');
      expect(user.perfil.primeiroNome, 'Ricardo');
    });

    test('refreshSession sends refresh payload and parses rotated tokens', () async {
      final dio = createMockDio((request) {
        capturedRequest = request;
        return mockResponse(
          request,
          data: {
            'access': 'novo-access',
            'refresh': 'novo-refresh',
          },
        );
      });

      final repository = AuthRepository(dio: dio);
      final response = await repository.refreshSession('refresh-antigo');

      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.path, '/api/refresh/');
      expect(capturedRequest.data, {
        'refresh': 'refresh-antigo',
      });
      expect(response.access, 'novo-access');
      expect(response.refresh, 'novo-refresh');
    });

    test('formats backend validation errors usefully', () async {
      final dio = createMockDio((request) {
        throw mockBadResponse(
          request,
          data: {
            'username': ['Este campo ja existe.'],
            'email': ['Informe um email valido.'],
          },
        );
      });

      final repository = AuthRepository(dio: dio);

      expect(
        () => repository.register({
          'username': 'ricardo123',
        }),
        throwsA(
          isA<ApiException>().having(
            (error) => error.toString(),
            'message',
            'username: Este campo ja existe.\nemail: Informe um email valido.',
          ),
        ),
      );
    });
  });
}
