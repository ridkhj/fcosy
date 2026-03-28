import 'package:client/core/utils/api_format.dart';
import 'package:client/data/models/transaction_model.dart';

class AccountDetailModel {
  final int id;
  final int usuario;
  final String nome;
  final String tipo;
  final double saldo;
  final String mesReferencia;
  final double saldoMes;
  final List<TransactionModel> transacoesMes;

  const AccountDetailModel({
    required this.id,
    required this.usuario,
    required this.nome,
    required this.tipo,
    required this.saldo,
    required this.mesReferencia,
    required this.saldoMes,
    required this.transacoesMes,
  });

  factory AccountDetailModel.fromJson(Map<String, dynamic> json) {
    final rawTransactions =
        (json['transacoes_mes'] as List<dynamic>? ?? const <dynamic>[]);

    return AccountDetailModel(
      id: json['id'] as int,
      usuario: json['usuario'] as int,
      nome: json['nome'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      saldo: ApiFormat.parseDecimal(json['saldo']),
      mesReferencia: json['mes_referencia'] as String? ?? '',
      saldoMes: ApiFormat.parseDecimal(json['saldo_mes']),
      transacoesMes: rawTransactions
          .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario': usuario,
      'nome': nome,
      'tipo': tipo,
      'saldo': ApiFormat.formatDecimal(saldo),
      'mes_referencia': mesReferencia,
      'saldo_mes': ApiFormat.formatDecimal(saldoMes),
      'transacoes_mes': transacoesMes.map((item) => item.toJson()).toList(),
    };
  }
}
