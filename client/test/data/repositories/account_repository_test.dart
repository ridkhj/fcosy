import 'package:client/core/network/api_exception.dart';
import 'package:client/data/repositories/account_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_dio.dart';

void main() {
  group('AccountRepository', () {
    late RequestOptions capturedRequest;

    test('getAccounts sends correct query params and parses pagination', () async {
      final dio = createMockDio((request) {
        capturedRequest = request;
        return mockResponse(
          request,
          data: {
            'count': 1,
            'next': null,
            'previous': null,
            'results': [
              {
                'id': 1,
                'nome': 'Conta Corrente',
                'tipo': 'corrente',
                'saldo': '560.00',
              },
            ],
          },
        );
      });

      final repository = AccountRepository(dio: dio);
      final response = await repository.getAccounts(
        page: 2,
        pageSize: 5,
        ordering: '-nome',
        tipo: 'corrente',
        nome: 'principal',
      );

      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.path, '/api/contas/');
      expect(capturedRequest.queryParameters, {
        'page': 2,
        'page_size': 5,
        'ordering': '-nome',
        'tipo': 'corrente',
        'nome': 'principal',
      });
      expect(response.count, 1);
      expect(response.results.first.nome, 'Conta Corrente');
    });

    test('getAccountDetail sends mes query param', () async {
      final dio = createMockDio((request) {
        capturedRequest = request;
        return mockResponse(
          request,
          data: {
            'id': 1,
            'usuario': 1,
            'nome': 'Conta Corrente',
            'tipo': 'corrente',
            'saldo': '560.00',
            'mes_referencia': '2026-03',
            'saldo_mes': '60.00',
            'transacoes_mes': [],
          },
        );
      });

      final repository = AccountRepository(dio: dio);
      final account = await repository.getAccountDetail(1, mes: '2026-03');

      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.path, '/api/contas/1/');
      expect(capturedRequest.queryParameters, {
        'mes': '2026-03',
      });
      expect(account.mesReferencia, '2026-03');
    });

    test('createAccount sends current API payload', () async {
      final dio = createMockDio((request) {
        capturedRequest = request;
        return mockResponse(
          request,
          statusCode: 201,
          data: {
            'id': 1,
            'nome': 'Conta Corrente',
            'tipo': 'corrente',
            'saldo': '0.00',
          },
        );
      });

      final repository = AccountRepository(dio: dio);
      final account = await repository.createAccount(
        nome: 'Conta Corrente',
        tipo: 'corrente',
        saldo: 0,
      );

      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.path, '/api/contas/');
      expect(capturedRequest.data, {
        'nome': 'Conta Corrente',
        'tipo': 'corrente',
        'saldo': '0.00',
      });
      expect(account.id, 1);
    });

    test('updateAccount sends full PUT payload', () async {
      final dio = createMockDio((request) {
        capturedRequest = request;
        return mockResponse(
          request,
          data: {
            'id': 1,
            'nome': 'Conta Principal',
            'tipo': 'corrente',
            'saldo': '560.00',
          },
        );
      });

      final repository = AccountRepository(dio: dio);
      final account = await repository.updateAccount(
        id: 1,
        nome: 'Conta Principal',
        tipo: 'corrente',
        saldo: 560,
      );

      expect(capturedRequest.method, 'PUT');
      expect(capturedRequest.path, '/api/contas/1/');
      expect(capturedRequest.data, {
        'nome': 'Conta Principal',
        'tipo': 'corrente',
        'saldo': '560.00',
      });
      expect(account.nome, 'Conta Principal');
    });

    test('patchAccount sends partial PATCH payload', () async {
      final dio = createMockDio((request) {
        capturedRequest = request;
        return mockResponse(
          request,
          data: {
            'id': 1,
            'nome': 'Conta Reserva',
            'tipo': 'corrente',
            'saldo': '560.00',
          },
        );
      });

      final repository = AccountRepository(dio: dio);
      final account = await repository.patchAccount(
        1,
        nome: 'Conta Reserva',
      );

      expect(capturedRequest.method, 'PATCH');
      expect(capturedRequest.path, '/api/contas/1/');
      expect(capturedRequest.data, {
        'nome': 'Conta Reserva',
      });
      expect(account.nome, 'Conta Reserva');
    });

    test('deleteAccount sends DELETE request', () async {
      final dio = createMockDio((request) {
        capturedRequest = request;
        return mockResponse(request, statusCode: 204);
      });

      final repository = AccountRepository(dio: dio);

      await repository.deleteAccount(1);

      expect(capturedRequest.method, 'DELETE');
      expect(capturedRequest.path, '/api/contas/1/');
    });

    test('formats backend account errors usefully', () async {
      final dio = createMockDio((request) {
        throw mockBadResponse(
          request,
          data: {
            'tipo': ['"carteira" nao e uma escolha valida.'],
          },
        );
      });

      final repository = AccountRepository(dio: dio);

      expect(
        () => repository.createAccount(nome: 'Nova', tipo: 'carteira'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.toString(),
            'message',
            'tipo: "carteira" nao e uma escolha valida.',
          ),
        ),
      );
    });
  });
}
