import 'package:client/data/models/account_detail_model.dart';
import 'package:client/data/models/account_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountSummaryModel', () {
    test('parses account summary payload', () {
      final model = AccountSummaryModel.fromJson({
        'id': 1,
        'nome': 'Conta Corrente',
        'tipo': 'corrente',
        'saldo': '560.00',
      });

      expect(model.id, 1);
      expect(model.nome, 'Conta Corrente');
      expect(model.tipo, 'corrente');
      expect(model.saldo, 560.00);
    });

    test('serializes account summary payload', () {
      const model = AccountSummaryModel(
        id: 2,
        nome: 'Reserva',
        tipo: 'poupanca',
        saldo: 150.0,
      );

      expect(model.toJson(), {
        'id': 2,
        'nome': 'Reserva',
        'tipo': 'poupanca',
        'saldo': '150.00',
      });
    });
  });

  group('AccountDetailModel', () {
    test('parses account detail payload with monthly transactions', () {
      final model = AccountDetailModel.fromJson({
        'id': 1,
        'usuario': 99,
        'nome': 'Conta Corrente',
        'tipo': 'corrente',
        'saldo': '560.00',
        'mes_referencia': '2026-03',
        'saldo_mes': '60',
        'transacoes_mes': [
          {
            'id': 10,
            'tipo': 'despesa',
            'status': 'pendente',
            'valor': '40.00',
            'descricao': 'Mercado',
            'data_transacao': '2026-03-15',
            'criado_em': '2026-03-15T12:00:00Z',
          },
        ],
      });

      expect(model.id, 1);
      expect(model.usuario, 99);
      expect(model.nome, 'Conta Corrente');
      expect(model.tipo, 'corrente');
      expect(model.saldo, 560.00);
      expect(model.mesReferencia, '2026-03');
      expect(model.saldoMes, 60.00);
      expect(model.transacoesMes, hasLength(1));
      expect(model.transacoesMes.first.tipo, 'despesa');
      expect(model.transacoesMes.first.status, 'pendente');
    });

    test('serializes account detail payload', () {
      final model = AccountDetailModel.fromJson({
        'id': 1,
        'usuario': 99,
        'nome': 'Conta Corrente',
        'tipo': 'corrente',
        'saldo': '560.00',
        'mes_referencia': '2026-03',
        'saldo_mes': '60',
        'transacoes_mes': [
          {
            'id': 10,
            'tipo': 'despesa',
            'status': 'pendente',
            'valor': '40.00',
            'descricao': 'Mercado',
            'data_transacao': '2026-03-15',
            'criado_em': '2026-03-15T12:00:00Z',
          },
        ],
      });

      expect(model.toJson(), {
        'id': 1,
        'usuario': 99,
        'nome': 'Conta Corrente',
        'tipo': 'corrente',
        'saldo': '560.00',
        'mes_referencia': '2026-03',
        'saldo_mes': '60.00',
        'transacoes_mes': [
          {
            'tipo': 'despesa',
            'status': 'pendente',
            'valor': '40.00',
            'descricao': 'Mercado',
            'data_transacao': '2026-03-15',
          },
        ],
      });
    });
  });
}
