import 'package:client/core/utils/api_format.dart';

class AccountSummaryModel {
  final int id;
  final String nome;
  final String tipo;
  final double saldo;

  const AccountSummaryModel({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.saldo,
  });

  factory AccountSummaryModel.fromJson(Map<String, dynamic> json) {
    return AccountSummaryModel(
      id: json['id'] as int,
      nome: json['nome'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      saldo: ApiFormat.parseDecimal(json['saldo']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo,
      'saldo': ApiFormat.formatDecimal(saldo),
    };
  }
}
