import 'package:client/data/models/account_detail_model.dart';
import 'package:client/data/models/account_summary_model.dart';
import 'package:client/data/models/paginated_response.dart';
import 'package:client/data/models/transaction_model.dart';
import 'package:client/data/repositories/account_repository.dart';
import 'package:client/data/repositories/transaction_repository.dart';
import 'package:client/state/account_notifier.dart';
import 'package:client/state/transaction_notifier.dart';
import 'package:client/ui/screens/transaction_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTransactionDetailAccountRepository extends AccountRepository {
  @override
  Future<PaginatedResponse<AccountSummaryModel>> getAccounts({
    int? page,
    int? pageSize,
    String? ordering,
    String? tipo,
    String? nome,
  }) async {
    return const PaginatedResponse<AccountSummaryModel>(
      count: 1,
      next: null,
      previous: null,
      results: [
        AccountSummaryModel(
          id: 1,
          nome: 'Conta Corrente',
          tipo: 'corrente',
          saldo: 560,
        ),
      ],
    );
  }

  @override
  Future<AccountDetailModel> getAccountDetail(int id, {String? mes}) async {
    return const AccountDetailModel(
      id: 1,
      usuario: 1,
      nome: 'Conta Corrente',
      tipo: 'corrente',
      saldo: 560,
      mesReferencia: '2026-03',
      saldoMes: 60,
      transacoesMes: [],
    );
  }
}

class FakeTransactionDetailRepository extends TransactionRepository {
  int patchCalls = 0;

  @override
  Future<TransactionModel> patchTransaction(
    int id,
    Map<String, dynamic> partialData,
  ) async {
    patchCalls++;
    return TransactionModel(
      id: id,
      conta: 1,
      tipo: 'despesa',
      status: partialData['status'] as String?,
      valor: 40,
      descricao: 'Mercado',
      dataTransacao: DateTime(2026, 3, 15),
    );
  }

  @override
  Future<List<TransactionModel>> getTransactions({
    String? dataInicio,
    String? dataFim,
    int? conta,
    String? tipo,
  }) async {
    return const [];
  }
}

void main() {
  testWidgets('TransactionDetailScreen toggles transaction status', (
    tester,
  ) async {
    final accountNotifier = AccountNotifier.forTest(
      repository: FakeTransactionDetailAccountRepository(),
    );
    final repository = FakeTransactionDetailRepository();
    final transactionNotifier = TransactionNotifier.forTest(
      repository: repository,
      accountNotifier: accountNotifier,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TransactionDetailScreen(
          transactionId: 1,
          initialTransaction: TransactionModel(
            id: 1,
            conta: 1,
            tipo: 'despesa',
            status: 'pendente',
            valor: 40,
            descricao: 'Mercado',
            dataTransacao: DateTime(2026, 3, 15),
          ),
          notifier: transactionNotifier,
          accountNotifier: accountNotifier,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar como realizada'));
    await tester.pumpAndSettle();

    expect(repository.patchCalls, 1);
    expect(find.text('Realizada'), findsWidgets);
    expect(find.text('Afeta o saldo da conta'), findsOneWidget);
  });
}
