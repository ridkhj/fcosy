import 'package:client/core/network/dio_client.dart';
import 'package:client/data/models/transaction_model.dart';

class TransactionRepository {
  Future<List<TransactionModel>> getTransactions() async {
    final response = await DioClient.dio.get('/api/transacoes/');
    final List data = response.data as List;
    return data
        .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await DioClient.dio.post('/api/transacoes/', data: transaction.toJson());
  }
}
