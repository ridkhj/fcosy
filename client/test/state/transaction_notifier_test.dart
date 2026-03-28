import 'package:client/data/models/account_detail_model.dart';
import 'package:client/data/models/account_summary_model.dart';
import 'package:client/data/models/paginated_response.dart';
import 'package:client/data/models/transaction_model.dart';
import 'package:client/data/repositories/account_repository.dart';
import 'package:client/data/repositories/transaction_repository.dart';
import 'package:client/state/account_notifier.dart';
import 'package:client/state/transaction_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTransactionRepository extends TransactionRepository {
  FakeTransactionRepository({
    this.transactions = const [],
    this.createdTransaction,
  });

  final List<TransactionModel> transactions;
  final TransactionModel? createdTransaction;
  int getTransactionsCalls = 0;
  int addTransactionCalls = 0;
  int patchTransactionCalls = 0;

  Map<String, dynamic>? lastPatchPayload;

  @override
  Future<List<TransactionModel>> getTransactions({
    String? dataInicio,
    String? dataFim,
    int? conta,
    String? tipo,
  }) async {
    getTransactionsCalls++;
    return transactions;
  }

  @override
  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    addTransactionCalls++;
    return createdTransaction ?? transaction;
  }

  @override
  Future<TransactionModel> patchTransaction(
    int id,
    Map<String, dynamic> partialData,
  ) async {
    patchTransactionCalls++;
    lastPatchPayload = partialData;

    return createdTransaction ??
        TransactionModel(
          id: id,
          conta: partialData['conta'] as int? ?? 1,
          tipo: 'despesa',
          status: partialData['status'] as String? ?? 'realizada',
          valor: 40,
          descricao: 'Conta de luz',
          dataTransacao: DateTime(2026, 3, 9),
        );
  }
}

class FakeAccountRepositoryForTransactions extends AccountRepository {
  int getAccountDetailCalls = 0;

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
    getAccountDetailCalls++;
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

void main() {
  group('TransactionNotifier', () {
    test('fetchTransactions stores filters and transactions', () async {
      final notifier = TransactionNotifier.forTest(
        repository: FakeTransactionRepository(
          transactions: [
            TransactionModel(
              id: 1,
              conta: 1,
              tipo: 'ganho',
              status: 'realizada',
              valor: 1000,
              descricao: 'Salario',
              dataTransacao: DateTime(2026, 3, 8),
            ),
          ],
        ),
      );

      await notifier.fetchTransactions(
        filters: const TransactionFilters(
          conta: 1,
          tipo: 'ganho',
          dataInicio: '2026-03-01',
          dataFim: '2026-03-31',
        ),
      );

      expect(notifier.transactions, hasLength(1));
      expect(notifier.selectedFilters.conta, 1);
      expect(notifier.selectedFilters.tipo, 'ganho');
      expect(notifier.lastError, isNull);
    });

    test('createTransaction refreshes transactions and selected account detail', () async {
      final accountRepository = FakeAccountRepositoryForTransactions();
      final accountNotifier = AccountNotifier.forTest(repository: accountRepository);
      await accountNotifier.fetchAccountDetail(1, mes: '2026-03');

      final repository = FakeTransactionRepository(
        transactions: [
          TransactionModel(
            id: 1,
            conta: 1,
            tipo: 'ganho',
            status: 'realizada',
            valor: 1000,
            descricao: 'Salario',
            dataTransacao: DateTime(2026, 3, 8),
          ),
        ],
        createdTransaction: TransactionModel(
          id: 2,
          conta: 1,
          tipo: 'despesa',
          status: 'pendente',
          valor: 40,
          descricao: 'Conta de luz',
          dataTransacao: DateTime(2026, 3, 9),
        ),
      );
      final notifier = TransactionNotifier.forTest(
        repository: repository,
        accountNotifier: accountNotifier,
      );

      await notifier.createTransaction(
        TransactionModel(
          conta: 1,
          tipo: 'despesa',
          status: 'pendente',
          valor: 40,
          descricao: 'Conta de luz',
          dataTransacao: DateTime(2026, 3, 9),
        ),
      );

      expect(repository.addTransactionCalls, 1);
      expect(repository.getTransactionsCalls, 1);
      expect(accountRepository.getAccountDetailCalls, 2);
    });

    test('patchTransaction refreshes data and preserves last patch payload', () async {
      final repository = FakeTransactionRepository();
      final notifier = TransactionNotifier.forTest(repository: repository);

      await notifier.patchTransaction(1, {'status': 'realizada'});

      expect(repository.patchTransactionCalls, 1);
      expect(repository.lastPatchPayload, {'status': 'realizada'});
      expect(repository.getTransactionsCalls, 1);
    });

    test('clear resets transaction state', () async {
      final notifier = TransactionNotifier.forTest(
        repository: FakeTransactionRepository(
          transactions: [
            TransactionModel(
              id: 1,
              conta: 1,
              tipo: 'ganho',
              status: 'realizada',
              valor: 1000,
              descricao: 'Salario',
              dataTransacao: DateTime(2026, 3, 8),
            ),
          ],
        ),
      );

      await notifier.fetchTransactions(
        filters: const TransactionFilters(conta: 1),
      );
      notifier.clear();

      expect(notifier.transactions, isEmpty);
      expect(notifier.selectedFilters.conta, isNull);
      expect(notifier.lastError, isNull);
      expect(notifier.isLoading, isFalse);
    });
  });
}
