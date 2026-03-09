class TransactionModel {
  final int? id;
  final String tipo;
  final double valor;
  final String descricao;
  final DateTime data;

  TransactionModel({
    this.id,
    required this.tipo,
    required this.valor,
    required this.descricao,
    required this.data,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int?,
      tipo: json['tipo'] as String,
      valor: double.parse(json['valor'].toString()),
      descricao: json['descricao'] as String? ?? '',
      data: DateTime.parse(json['data'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'valor': valor.toStringAsFixed(2),
      'descricao': descricao,
      'data':
          '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}',
    };
  }
}
