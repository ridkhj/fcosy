import 'package:client/data/models/account_detail_model.dart';
import 'package:client/data/models/account_summary_model.dart';
import 'package:client/data/models/paginated_response.dart';
import 'package:client/data/repositories/account_repository.dart';
import 'package:client/state/account_notifier.dart';
import 'package:client/ui/screens/accounts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAccountsScreenRepository extends AccountRepository {
  FakeAccountsScreenRepository({required this.response});

  final PaginatedResponse<AccountSummaryModel> response;

  @override
  Future<PaginatedResponse<AccountSummaryModel>> getAccounts({
    int? page,
    int? pageSize,
    String? ordering,
    String? tipo,
    String? nome,
  }) async {
    return response;
  }

  @override
  Future<AccountDetailModel> getAccountDetail(int id, {String? mes}) async {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('AccountsScreen renders real accounts from notifier', (
    tester,
  ) async {
    final notifier = AccountNotifier.forTest(
      repository: FakeAccountsScreenRepository(
        response: const PaginatedResponse<AccountSummaryModel>(
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
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: AccountsScreen(notifier: notifier),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Conta Corrente'), findsOneWidget);
    expect(find.text('Reserva'), findsOneWidget);
    expect(find.text('Conta corrente'), findsOneWidget);
    expect(find.text('Poupanca'), findsOneWidget);
    expect(find.text('R\$ 560.00'), findsOneWidget);
    expect(find.text('R\$ 150.00'), findsOneWidget);
  });

  testWidgets('AccountsScreen renders empty state', (tester) async {
    final notifier = AccountNotifier.forTest(
      repository: FakeAccountsScreenRepository(
        response: const PaginatedResponse<AccountSummaryModel>(
          count: 0,
          next: null,
          previous: null,
          results: [],
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: AccountsScreen(notifier: notifier),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Nenhuma conta encontrada'), findsOneWidget);
  });
}
