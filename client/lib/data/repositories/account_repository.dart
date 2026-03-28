import 'package:client/core/network/api_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/utils/api_error_formatter.dart';
import 'package:client/core/utils/api_format.dart';
import 'package:client/data/models/account_detail_model.dart';
import 'package:client/data/models/account_summary_model.dart';
import 'package:client/data/models/paginated_response.dart';
import 'package:dio/dio.dart';

class AccountRepository {
  AccountRepository({Dio? dio}) : _dio = dio ?? DioClient.dio;

  final Dio _dio;

  Future<PaginatedResponse<AccountSummaryModel>> getAccounts({
    int? page,
    int? pageSize,
    String? ordering,
    String? tipo,
    String? nome,
  }) async {
    try {
      final response = await _dio.get(
        '/api/contas/',
        queryParameters: {
          if (page != null) 'page': page,
          if (pageSize != null) 'page_size': pageSize,
          if (ordering != null) 'ordering': ordering,
          if (tipo != null) 'tipo': tipo,
          if (nome != null) 'nome': nome,
        },
      );

      return PaginatedResponse<AccountSummaryModel>.fromJson(
        response.data as Map<String, dynamic>,
        AccountSummaryModel.fromJson,
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiErrorFormatter.format(
          e.response?.data,
          fallbackMessage: 'Erro ao carregar contas',
        ),
      );
    }
  }

  Future<AccountDetailModel> getAccountDetail(int id, {String? mes}) async {
    try {
      final response = await _dio.get(
        '/api/contas/$id/',
        queryParameters: {
          if (mes != null) 'mes': mes,
        },
      );

      return AccountDetailModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        ApiErrorFormatter.format(
          e.response?.data,
          fallbackMessage: 'Erro ao carregar conta',
        ),
      );
    }
  }

  Future<AccountSummaryModel> createAccount({
    required String nome,
    required String tipo,
    double? saldo,
  }) async {
    try {
      final response = await _dio.post(
        '/api/contas/',
        data: {
          'nome': nome,
          'tipo': tipo,
          if (saldo != null) 'saldo': ApiFormat.formatDecimal(saldo),
        },
      );

      return AccountSummaryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        ApiErrorFormatter.format(
          e.response?.data,
          fallbackMessage: 'Erro ao criar conta',
        ),
      );
    }
  }

  Future<AccountSummaryModel> updateAccount({
    required int id,
    required String nome,
    required String tipo,
    required double saldo,
  }) async {
    try {
      final response = await _dio.put(
        '/api/contas/$id/',
        data: {
          'nome': nome,
          'tipo': tipo,
          'saldo': ApiFormat.formatDecimal(saldo),
        },
      );

      return AccountSummaryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        ApiErrorFormatter.format(
          e.response?.data,
          fallbackMessage: 'Erro ao atualizar conta',
        ),
      );
    }
  }

  Future<AccountSummaryModel> patchAccount(
    int id, {
    String? nome,
    String? tipo,
    double? saldo,
  }) async {
    try {
      final response = await _dio.patch(
        '/api/contas/$id/',
        data: {
          if (nome != null) 'nome': nome,
          if (tipo != null) 'tipo': tipo,
          if (saldo != null) 'saldo': ApiFormat.formatDecimal(saldo),
        },
      );

      return AccountSummaryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        ApiErrorFormatter.format(
          e.response?.data,
          fallbackMessage: 'Erro ao atualizar conta',
        ),
      );
    }
  }

  Future<void> deleteAccount(int id) async {
    try {
      await _dio.delete('/api/contas/$id/');
    } on DioException catch (e) {
      throw ApiException(
        ApiErrorFormatter.format(
          e.response?.data,
          fallbackMessage: 'Erro ao excluir conta',
        ),
      );
    }
  }
}
