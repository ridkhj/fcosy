import 'package:client/data/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionModel', () {
    test('parses full transaction payload from API', () {
      final model = TransactionModel.fromJson({
        'id': 1,
        'conta': 2,
        'tipo': 'ganho',
        'status': 'realizada',
        'valor': '1000.50',
        'descricao': 'Salario',
        'data_transacao': '2026-03-08',
        'criado_em': '2026-03-08T12:00:00Z',
      });

      expect(model.id, 1);
      expect(model.conta, 2);
      expect(model.tipo, 'ganho');
      expect(model.status, 'realizada');
      expect(model.valor, 1000.50);
      expect(model.descricao, 'Salario');
      expect(model.dataTransacao, DateTime.parse('2026-03-08'));
      expect(model.criadoEm, DateTime.parse('2026-03-08T12:00:00Z'));
    });

    test('parses monthly account transaction payload without conta', () {
      final model = TransactionModel.fromJson({
        'id': 10,
        'tipo': 'despesa',
        'status': 'pendente',
        'valor': '40.00',
        'descricao': 'Mercado',
        'data_transacao': '2026-03-15',
        'criado_em': '2026-03-15T12:00:00Z',
      });

      expect(model.id, 10);
      expect(model.conta, isNull);
      expect(model.status, 'pendente');
      expect(model.tipo, 'despesa');
      expect(model.valor, 40.00);
      expect(model.descricao, 'Mercado');
      expect(model.dataTransacao, DateTime.parse('2026-03-15'));
      expect(model.criadoEm, DateTime.parse('2026-03-15T12:00:00Z'));
    });

    test('serializes transaction payload with current API field names', () {
      final model = TransactionModel(
        conta: 3,
        tipo: 'despesa',
        status: 'pendente',
        valor: 49.9,
        descricao: 'Conta de luz',
        dataTransacao: DateTime(2026, 3, 9),
      );

      expect(model.toJson(), {
        'tipo': 'despesa',
        'status': 'pendente',
        'valor': '49.90',
        'descricao': 'Conta de luz',
        'data_transacao': '2026-03-09',
        'conta': 3,
      });
    });
  });
}
