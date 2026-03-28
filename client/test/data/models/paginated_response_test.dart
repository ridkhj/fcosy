import 'package:client/data/models/account_summary_model.dart';
import 'package:client/data/models/paginated_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaginatedResponse', () {
    test('parses paginated payload with mapped results', () {
      final response = PaginatedResponse<AccountSummaryModel>.fromJson({
        'count': 2,
        'next': 'http://localhost:8000/api/contas/?page=2',
        'previous': null,
        'results': [
          {
            'id': 1,
            'nome': 'Conta Corrente',
            'tipo': 'corrente',
            'saldo': '560.00',
          },
          {
            'id': 2,
            'nome': 'Reserva',
            'tipo': 'poupanca',
            'saldo': '150.00',
          },
        ],
      }, AccountSummaryModel.fromJson);

      expect(response.count, 2);
      expect(response.next, 'http://localhost:8000/api/contas/?page=2');
      expect(response.previous, isNull);
      expect(response.results, hasLength(2));
      expect(response.results.first.nome, 'Conta Corrente');
      expect(response.results.last.saldo, 150.00);
    });

    test('serializes paginated payload with mapped results', () {
      const response = PaginatedResponse<AccountSummaryModel>(
        count: 1,
        next: null,
        previous: null,
        results: [
          AccountSummaryModel(
            id: 3,
            nome: 'Investimentos',
            tipo: 'investimento',
            saldo: 900.0,
          ),
        ],
      );

      expect(
        response.toJson((item) => item.toJson()),
        {
          'count': 1,
          'next': null,
          'previous': null,
          'results': [
            {
              'id': 3,
              'nome': 'Investimentos',
              'tipo': 'investimento',
              'saldo': '900.00',
            },
          ],
        },
      );
    });
  });
}
