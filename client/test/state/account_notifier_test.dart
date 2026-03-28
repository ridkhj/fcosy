import 'package:client/data/models/account_detail_model.dart';
import 'package:client/data/models/account_summary_model.dart';
import 'package:client/data/models/paginated_response.dart';
import 'package:client/data/repositories/account_repository.dart';
import 'package:client/state/account_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAccountRepository extends AccountRepository {
  FakeAccountRepository({
    required this.accountsResponse,
    this.accountDetail,
  });

  PaginatedResponse<AccountSummaryModel> accountsResponse;
  AccountDetailModel? accountDetail;
  int getAccountsCalls = 0;
  int getAccountDetailCalls = 0;
  int createAccountCalls = 0;
  int deleteAccountCalls = 0;

  @override
  Future<PaginatedResponse<AccountSummaryModel>> getAccounts({
    int? page,
    int? pageSize,
    String? ordering,
    String? tipo,
    String? nome,
  }) async {
    getAccountsCalls++;
    return accountsResponse;
  }

  @override
  Future<AccountDetailModel> getAccountDetail(int id, {String? mes}) async {
    getAccountDetailCalls++;
    return accountDetail!;
  }

  @override
  Future<AccountSummaryModel> createAccount({
    required String nome,
    required String tipo,
    double? saldo,
  }) async {
    createAccountCalls++;
    return AccountSummaryModel(
      id: 3,
      nome: nome,
      tipo: tipo,
      saldo: saldo ?? 0,
    );
  }

  @override
  Future<void> deleteAccount(int id) async {
    deleteAccountCalls++;
  }
}

void main() {
  group('AccountNotifier', () {
    late FakeAccountRepository repository;

    setUp(() {
      repository = FakeAccountRepository(
        accountsResponse: const PaginatedResponse<AccountSummaryModel>(
          count: 2,
          next: null,
          previous: null,
          results: [
            AccountSummaryModel(
              id: 1,
              nome: 'Conta Corrente',
              tipo: 'corrente',
              saldo: 560,
            ),
            AccountSummaryModel(
              id: 2,
              nome: 'Reserva',
              tipo: 'poupanca',
              saldo: 150,
            ),
          ],
        ),
        accountDetail: const AccountDetailModel(
          id: 1,
          usuario: 1,
          nome: 'Conta Corrente',
          tipo: 'corrente',
          saldo: 560,
          mesReferencia: '2026-03',
          saldoMes: 60,
          transacoesMes: [],
        ),
      );
    });

    test('fetchAccounts updates accounts, filters and pagination', () async {
      final notifier = AccountNotifier.forTest(repository: repository);

      await notifier.fetchAccounts(
        filters: const AccountFilters(
          ordering: '-nome',
          tipo: 'corrente',
          nome: 'principal',
          page: 2,
          pageSize: 5,
        ),
      );

      expect(repository.getAccountsCalls, 1);
      expect(notifier.accounts, hasLength(2));
      expect(notifier.filters.page, 2);
      expect(notifier.filters.pageSize, 5);
      expect(notifier.pagination.count, 2);
      expect(notifier.lastError, isNull);
    });

    test('fetchAccountDetail populates selected account and month', () async {
      final notifier = AccountNotifier.forTest(repository: repository);

      await notifier.fetchAccountDetail(1, mes: '2026-03');

      expect(repository.getAccountDetailCalls, 1);
      expect(notifier.accountDetail?.id, 1);
      expect(notifier.selectedAccount?.id, 1);
      expect(notifier.selectedMonth, '2026-03');
    });

    test('createAccount refreshes list and selects created account', () async {
      final notifier = AccountNotifier.forTest(repository: repository);

      final created = await notifier.createAccount(
        nome: 'Investimentos',
        tipo: 'investimento',
        saldo: 900,
      );

      expect(repository.createAccountCalls, 1);
      expect(repository.getAccountsCalls, 1);
      expect(created.nome, 'Investimentos');
      expect(notifier.selectedAccount?.id, 3);
    });

    test('deleteAccount clears selected state when removing selected account', () async {
      final notifier = AccountNotifier.forTest(repository: repository);

      await notifier.fetchAccountDetail(1, mes: '2026-03');
      await notifier.deleteAccount(1);

      expect(repository.deleteAccountCalls, 1);
      expect(notifier.selectedAccount, isNull);
      expect(notifier.accountDetail, isNull);
      expect(repository.getAccountsCalls, 1);
    });
  });
}
