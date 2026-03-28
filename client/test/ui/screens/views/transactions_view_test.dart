import 'package:client/data/models/account_detail_model.dart';
import 'package:client/data/models/account_summary_model.dart';
import 'package:client/data/models/paginated_response.dart';
import 'package:client/data/models/transaction_model.dart';
import 'package:client/data/repositories/account_repository.dart';
import 'package:client/data/repositories/transaction_repository.dart';
import 'package:client/state/account_notifier.dart';
import 'package:client/state/transaction_notifier.dart';
import 'package:client/ui/screens/views/transactions_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTransactionsViewAccountRepository extends AccountRepository {
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
    throw UnimplementedError();
  }
}

class FakeTransactionsViewRepository extends TransactionRepository {
  @override
  Future<List<TransactionModel>> getTransactions({
    String? dataInicio,
    String? dataFim,
    int? conta,
    String? tipo,
  }) async {
    return [
      TransactionModel(
        id: 1,
        conta: 1,
        tipo: 'despesa',
        status: 'pendente',
        valor: 40,
        descricao: 'Mercado',
        dataTransacao: DateTime(2026, 3, 15),
      ),
    ];
  }
}

void main() {
  testWidgets('TransactionsView shows status and account when list is global', (
    tester,
  ) async {
    final accountNotifier = AccountNotifier.forTest(
      repository: FakeTransactionsViewAccountRepository(),
    );
    final transactionNotifier = TransactionNotifier.forTest(
      repository: FakeTransactionsViewRepository(),
      accountNotifier: accountNotifier,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: TransactionsView(
            accountNotifier: accountNotifier,
            transactionNotifier: transactionNotifier,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
    expect(find.text('Conta Corrente'), findsOneWidget);
  });
}
