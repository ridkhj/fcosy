import 'package:client/data/models/account_detail_model.dart';
import 'package:client/data/models/account_summary_model.dart';
import 'package:client/data/models/paginated_response.dart';
import 'package:client/data/models/transaction_model.dart';
import 'package:client/data/repositories/account_repository.dart';
import 'package:client/state/account_notifier.dart';
import 'package:client/ui/screens/account_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAccountDetailRepository extends AccountRepository {
  final List<String?> requestedMonths = [];

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
    requestedMonths.add(mes);

    final month = mes ?? '2026-03';

    return AccountDetailModel(
      id: 1,
      usuario: 1,
      nome: 'Conta Corrente',
      tipo: 'corrente',
      saldo: 560,
      mesReferencia: month,
      saldoMes: month == '2026-04' ? -20 : 60,
      transacoesMes: [
        TransactionModel(
          id: 1,
          tipo: 'despesa',
          status: 'pendente',
          valor: 40,
          descricao: 'Mercado',
          dataTransacao: DateTime.parse('$month-10'),
        ),
      ],
    );
  }
}

void main() {
  testWidgets(
    'AccountDetailScreen shows a back button and returns to previous screen',
    (tester) async {
      final repository = FakeAccountDetailRepository();
      final notifier = AccountNotifier.forTest(repository: repository);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AccountDetailScreen(
                            accountId: 1,
                            notifier: notifier,
                          ),
                        ),
                      );
                    },
                    child: const Text('Abrir detalhe'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Abrir detalhe'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Retornar'), findsOneWidget);

      await tester.tap(find.byTooltip('Retornar'));
      await tester.pumpAndSettle();

      expect(find.text('Abrir detalhe'), findsOneWidget);
    },
  );

  testWidgets(
    'AccountDetailScreen shows balance cards and monthly transactions',
    (tester) async {
      final repository = FakeAccountDetailRepository();
      final notifier = AccountNotifier.forTest(repository: repository);

      await tester.pumpWidget(
        MaterialApp(
          home: AccountDetailScreen(accountId: 1, notifier: notifier),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Saldo total'), findsOneWidget);
      expect(find.text('Saldo do mes'), findsOneWidget);
      expect(find.text('2026-03'), findsOneWidget);
      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Pendente'), findsOneWidget);
      expect(find.text('R\$ 560.00'), findsOneWidget);
      expect(find.text('R\$ 60.00'), findsOneWidget);
    },
  );

  testWidgets('AccountDetailScreen allows changing the requested month', (
    tester,
  ) async {
    final repository = FakeAccountDetailRepository();
    final notifier = AccountNotifier.forTest(repository: repository);

    await tester.pumpWidget(
      MaterialApp(home: AccountDetailScreen(accountId: 1, notifier: notifier)),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(repository.requestedMonths, contains('2026-04'));
    expect(find.text('2026-04'), findsOneWidget);
    expect(find.text('R\$ -20.00'), findsOneWidget);
  });
}
