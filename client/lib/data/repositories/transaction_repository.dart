import 'package:client/core/network/dio_client.dart';
import 'package:client/core/network/api_exception.dart';
import 'package:client/core/utils/api_error_formatter.dart';
import 'package:client/data/models/transaction_model.dart';
import 'package:dio/dio.dart';

class TransactionRepository {
  TransactionRepository({Dio? dio}) : _dio = dio ?? DioClient.dio;

  final Dio _dio;

  Future<List<TransactionModel>> getTransactions({
    String? dataInicio,
    String? dataFim,
    int? conta,
    String? tipo,
  }) async {
    try {
      final response = await _dio.get(
        '/api/transacoes/',
        queryParameters: {
          if (dataInicio != null) 'data_inicio': dataInicio,
          if (dataFim != null) 'data_fim': dataFim,
          if (conta != null) 'conta': conta,
          if (tipo != null) 'tipo': tipo,
        },
      );

      final data = response.data as List<dynamic>;
      return data
          .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        ApiErrorFormatter.format(
          e.response?.data,
          fallbackMessage: 'Erro ao carregar transacoes',
        ),
      );
    }
  }

  Future<TransactionModel> getTransaction(int id) async {
    try {
      final response = await _dio.get('/api/transacoes/$id/');
      return TransactionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        ApiErrorFormatter.format(
          e.response?.data,
          fallbackMessage: 'Erro ao carregar transacao',
        ),
      );
    }
  }

  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    try {
      final response = await _dio.post(
        '/api/transacoes/',
        data: transaction.toJson(),
      );

      return TransactionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        ApiErrorFormatter.format(
          e.response?.data,
          fallbackMessage: 'Erro ao criar transacao',
        ),
      );
    }
  }

  Future<TransactionModel> updateTransaction(
    int id,
    TransactionModel transaction,
  ) async {
    try {
      final response = await _dio.put(
        '/api/transacoes/$id/',
        data: transaction.toJson(),
      );

      return TransactionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        ApiErrorFormatter.format(
          e.response?.data,
          fallbackMessage: 'Erro ao atualizar transacao',
        ),
      );
    }
  }

  Future<TransactionModel> patchTransaction(
    int id,
    Map<String, dynamic> partialData,
  ) async {
    try {
      final response = await _dio.patch(
        '/api/transacoes/$id/',
        data: partialData,
      );

      return TransactionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        ApiErrorFormatter.format(
          e.response?.data,
          fallbackMessage: 'Erro ao atualizar transacao',
        ),
      );
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await _dio.delete('/api/transacoes/$id/');
    } on DioException catch (e) {
      throw ApiException(
        ApiErrorFormatter.format(
          e.response?.data,
          fallbackMessage: 'Erro ao excluir transacao',
        ),
      );
    }
  }
}
