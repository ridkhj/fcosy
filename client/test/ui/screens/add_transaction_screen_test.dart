import 'package:client/data/models/account_detail_model.dart';
import 'package:client/data/models/account_summary_model.dart';
import 'package:client/data/models/paginated_response.dart';
import 'package:client/data/models/transaction_model.dart';
import 'package:client/data/repositories/account_repository.dart';
import 'package:client/data/repositories/transaction_repository.dart';
import 'package:client/state/account_notifier.dart';
import 'package:client/state/transaction_notifier.dart';
import 'package:client/ui/screens/add_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTransactionFormAccountRepository extends AccountRepository {
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

class FakeTransactionFormRepository extends TransactionRepository {
  TransactionModel? createdTransaction;

  @override
  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    createdTransaction = transaction;
    return TransactionModel(
      id: 1,
      conta: transaction.conta,
      tipo: transaction.tipo,
      status: transaction.status,
      valor: transaction.valor,
      descricao: transaction.descricao,
      dataTransacao: transaction.dataTransacao,
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
  testWidgets('AddTransactionScreen submits full transaction payload', (
    tester,
  ) async {
    final accountNotifier = AccountNotifier.forTest(
      repository: FakeTransactionFormAccountRepository(),
    );
    final transactionRepository = FakeTransactionFormRepository();
    final transactionNotifier = TransactionNotifier.forTest(
      repository: transactionRepository,
      accountNotifier: accountNotifier,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AddTransactionScreen(
          initialAccount: const AccountSummaryModel(
            id: 1,
            nome: 'Conta Corrente',
            tipo: 'corrente',
            saldo: 560,
          ),
          accountNotifier: accountNotifier,
          transactionNotifier: transactionNotifier,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Despesa').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pendente').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '45.50');
    await tester.enterText(find.byType(TextFormField).at(1), 'Mercado');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(transactionRepository.createdTransaction, isNotNull);
    expect(transactionRepository.createdTransaction!.conta, 1);
    expect(transactionRepository.createdTransaction!.tipo, 'despesa');
    expect(transactionRepository.createdTransaction!.status, 'pendente');
    expect(transactionRepository.createdTransaction!.valor, 45.50);
    expect(transactionRepository.createdTransaction!.descricao, 'Mercado');
  });
}
