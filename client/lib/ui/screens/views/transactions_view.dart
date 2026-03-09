import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:client/state/transaction_notifier.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  final TransactionNotifier _notifier = TransactionNotifier();

  @override
  void initState() {
    super.initState();
    // Fetch after the first frame so context/build is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier.fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-transaction'),
        tooltip: 'Nova transação',
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: _notifier,
        builder: (context, _) {
          if (_notifier.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_notifier.transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhuma transação encontrada',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toque no botão + para adicionar',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: _notifier.transactions.length,
            itemBuilder: (context, index) {
              final t = _notifier.transactions[index];
              final isGanho = t.tipo == 'ganho';
              final color = isGanho ? Colors.greenAccent : Colors.redAccent;
              final sign = isGanho ? '+' : '-';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: const Color(0xFF1E1E1E),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(
                      isGanho ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    t.descricao.isNotEmpty ? t.descricao : '(sem descrição)',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy').format(t.data),
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: Text(
                    '$sign R\$ ${t.valor.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
