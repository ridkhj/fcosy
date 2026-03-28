import 'package:client/core/network/api_exception.dart';
import 'package:client/data/models/transaction_model.dart';
import 'package:client/data/repositories/transaction_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_dio.dart';

void main() {
  group('TransactionRepository', () {
    late RequestOptions capturedRequest;

    test('getTransactions sends correct filter query params', () async {
      final dio = createMockDio((request) {
        capturedRequest = request;
        return mockResponse(
          request,
          data: [
            {
              'id': 1,
              'conta': 1,
              'tipo': 'ganho',
              'status': 'realizada',
              'valor': '1000.00',
              'descricao': 'Salario',
              'data_transacao': '2026-03-08',
              'criado_em': '2026-03-08T12:00:00Z',
            },
          ],
        );
      });

      final repository = TransactionRepository(dio: dio);
      final transactions = await repository.getTransactions(
        dataInicio: '2026-03-01',
        dataFim: '2026-03-31',
        conta: 1,
        tipo: 'ganho',
      );

      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.path, '/api/transacoes/');
      expect(capturedRequest.queryParameters, {
        'data_inicio': '2026-03-01',
        'data_fim': '2026-03-31',
        'conta': 1,
        'tipo': 'ganho',
      });
      expect(transactions, hasLength(1));
      expect(transactions.first.status, 'realizada');
    });

    test('getTransaction fetches transaction by id', () async {
      final dio = createMockDio((request) {
        capturedRequest = request;
        return mockResponse(
          request,
          data: {
            'id': 7,
            'conta': 1,
            'tipo': 'despesa',
            'status': 'pendente',
            'valor': '40.00',
            'descricao': 'Conta de luz',
            'data_transacao': '2026-03-09',
            'criado_em': '2026-03-09T12:00:00Z',
          },
        );
      });

      final repository = TransactionRepository(dio: dio);
      final transaction = await repository.getTransaction(7);

      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.path, '/api/transacoes/7/');
      expect(transaction.id, 7);
      expect(transaction.status, 'pendente');
    });

    test('addTransaction sends current API payload', () async {
      final dio = createMockDio((request) {
        capturedRequest = request;
        return mockResponse(
          request,
          statusCode: 201,
          data: {
            'id': 1,
            'conta': 1,
            'tipo': 'ganho',
            'status': 'realizada',
            'valor': '1000.00',
            'descricao': 'Salario',
            'data_transacao': '2026-03-08',
            'criado_em': '2026-03-08T12:00:00Z',
          },
        );
      });

      final repository = TransactionRepository(dio: dio);
      final transaction = await repository.addTransaction(
        TransactionModel(
          conta: 1,
          tipo: 'ganho',
          status: 'realizada',
          valor: 1000,
          descricao: 'Salario',
          dataTransacao: DateTime(2026, 3, 8),
        ),
      );

      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.path, '/api/transacoes/');
      expect(capturedRequest.data, {
        'tipo': 'ganho',
        'status': 'realizada',
        'valor': '1000.00',
        'descricao': 'Salario',
        'data_transacao': '2026-03-08',
        'conta': 1,
      });
      expect(transaction.id, 1);
    });

    test('updateTransaction sends full PUT payload', () async {
      final dio = createMockDio((request) {
        capturedRequest = request;
        return mockResponse(
          request,
          data: {
            'id': 1,
            'conta': 1,
            'tipo': 'despesa',
            'status': 'pendente',
            'valor': '40.00',
            'descricao': 'Conta de luz',
            'data_transacao': '2026-03-09',
            'criado_em': '2026-03-09T12:00:00Z',
          },
        );
      });

      final repository = TransactionRepository(dio: dio);
      final transaction = await repository.updateTransaction(
        1,
        TransactionModel(
          conta: 1,
          tipo: 'despesa',
          status: 'pendente',
          valor: 40,
          descricao: 'Conta de luz',
          dataTransacao: DateTime(2026, 3, 9),
        ),
      );

      expect(capturedRequest.method, 'PUT');
      expect(capturedRequest.path, '/api/transacoes/1/');
      expect(capturedRequest.data, {
        'tipo': 'despesa',
        'status': 'pendente',
        'valor': '40.00',
        'descricao': 'Conta de luz',
        'data_transacao': '2026-03-09',
        'conta': 1,
      });
      expect(transaction.tipo, 'despesa');
    });

    test('patchTransaction sends partial PATCH payload', () async {
      final dio = createMockDio((request) {
        capturedRequest = request;
        return mockResponse(
          request,
          data: {
            'id': 1,
            'conta': 1,
            'tipo': 'despesa',
            'status': 'realizada',
            'valor': '40.00',
            'descricao': 'Conta de luz',
            'data_transacao': '2026-03-09',
            'criado_em': '2026-03-09T12:00:00Z',
          },
        );
      });

      final repository = TransactionRepository(dio: dio);
      final transaction = await repository.patchTransaction(1, {
        'status': 'realizada',
      });

      expect(capturedRequest.method, 'PATCH');
      expect(capturedRequest.path, '/api/transacoes/1/');
      expect(capturedRequest.data, {
        'status': 'realizada',
      });
      expect(transaction.status, 'realizada');
    });

    test('deleteTransaction sends DELETE request', () async {
      final dio = createMockDio((request) {
        capturedRequest = request;
        return mockResponse(request, statusCode: 204);
      });

      final repository = TransactionRepository(dio: dio);

      await repository.deleteTransaction(1);

      expect(capturedRequest.method, 'DELETE');
      expect(capturedRequest.path, '/api/transacoes/1/');
    });

    test('formats backend transaction errors usefully', () async {
      final dio = createMockDio((request) {
        throw mockBadResponse(
          request,
          data: {
            'conta': ['Conta invalida para este usuario.'],
            'valor': ['Certifique-se de que este valor seja maior que zero.'],
          },
        );
      });

      final repository = TransactionRepository(dio: dio);

      expect(
        () => repository.addTransaction(
          TransactionModel(
            conta: 999,
            tipo: 'ganho',
            status: 'realizada',
            valor: 100,
            descricao: 'Teste',
            dataTransacao: DateTime(2026, 3, 8),
          ),
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.toString(),
            'message',
            'conta: Conta invalida para este usuario.\nvalor: Certifique-se de que este valor seja maior que zero.',
          ),
        ),
      );
    });
  });
}
