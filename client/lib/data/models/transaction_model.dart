import 'package:client/core/utils/api_format.dart';

class TransactionModel {
  final int? id;
  final int? conta;
  final String tipo;
  final String? status;
  final double valor;
  final String descricao;
  final DateTime dataTransacao;
  final DateTime? criadoEm;

  TransactionModel({
    this.id,
    this.conta,
    required this.tipo,
    this.status,
    required this.valor,
    required this.descricao,
    required this.dataTransacao,
    this.criadoEm,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int?,
      conta: json['conta'] as int?,
      tipo: json['tipo'] as String,
      status: json['status'] as String?,
      valor: ApiFormat.parseDecimal(json['valor'].toString()),
      descricao: json['descricao'] as String? ?? '',
      dataTransacao: DateTime.parse(json['data_transacao'] as String),
      criadoEm: json['criado_em'] != null
          ? DateTime.parse(json['criado_em'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'tipo': tipo,
      if (status != null) 'status': status,
      'valor': ApiFormat.formatDecimal(valor),
      'descricao': descricao,
      'data_transacao': ApiFormat.formatDate(dataTransacao),
    };

    if (conta != null) {
      json['conta'] = conta;
    }

    return json;
  }
}
