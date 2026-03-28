import 'package:client/core/network/dio_client.dart';
import 'package:client/state/auth_notifier.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_http_client_adapter.dart';

void main() {
  group('DioClient', () {
    setUp(() {
      AuthNotifier().logout();
      DioClient.setRefreshDioFactoryForTest(null);
    });

    test('retries request after refresh and accepts rotated refresh token', () async {
      var protectedCalls = 0;
      String? retriedAuthorizationHeader;

      DioClient.dio.httpClientAdapter = MockHttpClientAdapter((request) {
        if (request.path == '/api/protected/') {
          protectedCalls++;

          if (protectedCalls == 1) {
            return jsonResponseBody(
              {'detail': 'Token expired'},
              statusCode: 401,
            );
          }

          retriedAuthorizationHeader =
              request.headers['Authorization']?.toString();
          return jsonResponseBody({'ok': true}, statusCode: 200);
        }

        return jsonResponseBody({'detail': 'Not found'}, statusCode: 404);
      });

      DioClient.setRefreshDioFactoryForTest(() {
        final dio = Dio(
          BaseOptions(
            baseUrl: 'http://localhost:8000',
            headers: {'Content-Type': 'application/json'},
          ),
        );

        dio.httpClientAdapter = MockHttpClientAdapter((request) {
          expect(request.path, '/api/refresh/');
          return jsonResponseBody(
            {
              'access': 'new-access-token',
              'refresh': 'new-refresh-token',
            },
            statusCode: 200,
          );
        });

        return dio;
      });

      AuthNotifier().setTokens('expired-access', 'current-refresh');

      final response = await DioClient.dio.get('/api/protected/');

      expect(response.statusCode, 200);
      expect(response.data['ok'], true);
      expect(protectedCalls, 2);
      expect(retriedAuthorizationHeader, 'Bearer new-access-token');
      expect(AuthNotifier().accessToken, 'new-access-token');
      expect(AuthNotifier().refreshToken, 'new-refresh-token');
    });
  });
}
