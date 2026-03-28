import 'package:client/data/models/account_summary_model.dart';
import 'package:client/state/account_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AccountDetailScreen extends StatefulWidget {
  const AccountDetailScreen({
    super.key,
    required this.accountId,
    AccountNotifier? notifier,
  }) : _notifier = notifier;

  final int accountId;
  final AccountNotifier? _notifier;

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  late final AccountNotifier _notifier = widget._notifier ?? AccountNotifier();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier.fetchAccountDetail(widget.accountId);
    });
  }

  Future<void> _changeMonth(int delta) async {
    final current = _notifier.accountDetail?.mesReferencia;
    if (current == null || current.isEmpty) {
      return;
    }

    final currentDate = DateTime.parse('$current-01');
    final target = DateTime(currentDate.year, currentDate.month + delta, 1);
    final month =
        '${target.year.toString().padLeft(4, '0')}-${target.month.toString().padLeft(2, '0')}';
    await _notifier.fetchAccountDetail(widget.accountId, mes: month);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Excluir conta',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Tem certeza que deseja excluir esta conta?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Excluir',
                style: TextStyle(color: Color(0xFFFF6B6B)),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _notifier.deleteAccount(widget.accountId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta excluida com sucesso.')),
        );
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  AccountSummaryModel? _toSummary() {
    final detail = _notifier.accountDetail;
    if (detail == null) {
      return _notifier.selectedAccount;
    }

    return AccountSummaryModel(
      id: detail.id,
      nome: detail.nome,
      tipo: detail.tipo,
      saldo: detail.saldo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        final detail = _notifier.accountDetail;

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E1E1E),
            leading: IconButton(
              tooltip: 'Retornar',
              onPressed: () {
                final navigator = Navigator.of(context);
                if (navigator.canPop()) {
                  navigator.pop();
                  return;
                }

                GoRouter.maybeOf(context)?.go('/accounts');
              },
              icon: const Icon(Icons.arrow_back),
            ),
            title: Text(
              detail?.nome ?? 'Detalhe da conta',
              style: const TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                tooltip: 'Nova transacao',
                onPressed: detail == null
                    ? null
                    : () async {
                        await context.push(
                          '/transactions/new',
                          extra: _toSummary(),
                        );
                        if (mounted) {
                          await _notifier.refreshSelectedAccountDetail();
                        }
                      },
                icon: const Icon(Icons.add_card_outlined),
              ),
              IconButton(
                tooltip: 'Editar',
                onPressed: detail == null
                    ? null
                    : () => context.push(
                        '/accounts/${widget.accountId}/edit',
                        extra: _toSummary(),
                      ),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Excluir',
                onPressed: detail == null ? null : _deleteAccount,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: _buildBody(detail),
        );
      },
    );
  }

  Widget _buildBody(dynamic detail) {
    if (_notifier.isLoading && detail == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifier.lastError != null && detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFFF6B6B),
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                _notifier.lastError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _notifier.fetchAccountDetail(widget.accountId),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (detail == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: () => _notifier.refreshSelectedAccountDetail(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MonthSwitcher(
            mesReferencia: detail.mesReferencia,
            onPrevious: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BalanceCard(
                  label: 'Saldo total',
                  value: detail.saldo,
                  helper: 'Saldo global atual da conta',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BalanceCard(
                  label: 'Saldo do mes',
                  value: detail.saldoMes,
                  helper: 'Recorte mensal em ${detail.mesReferencia}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Somente transacoes realizadas afetam o saldo total da conta. As pendentes aparecem na lista, mas nao entram nesse calculo.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Text(
            'Transacoes do mes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (detail.transacoesMes.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.white38,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Nenhuma transacao encontrada neste mes.',
                    style: TextStyle(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...detail.transacoesMes.map<Widget>((transaction) {
              final isIncome = transaction.tipo == 'ganho';
              final amountColor = isIncome
                  ? Colors.greenAccent
                  : Colors.redAccent;
              final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;
              final sign = isIncome ? '+' : '-';

              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  onTap: transaction.id == null
                      ? null
                      : () => context.push(
                          '/transactions/${transaction.id}',
                          extra: transaction,
                        ),
                  leading: CircleAvatar(
                    backgroundColor: amountColor.withOpacity(0.15),
                    child: Icon(icon, color: amountColor, size: 18),
                  ),
                  title: Text(
                    transaction.descricao,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'dd/MM/yyyy',
                        ).format(transaction.dataTransacao),
                        style: const TextStyle(color: Colors.white54),
                      ),
                      const SizedBox(height: 6),
                      _TransactionStatusChip(status: transaction.status),
                    ],
                  ),
                  trailing: Text(
                    '$sign R\$ ${transaction.valor.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.mesReferencia,
    required this.onPrevious,
    required this.onNext,
  });

  final String mesReferencia;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Mes de referencia',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  mesReferencia,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.label,
    required this.value,
    required this.helper,
  });

  final String label;
  final double value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    final color = value >= 0 ? Colors.greenAccent : const Color(0xFFFF6B6B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 8),
          Text(
            'R\$ ${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            helper,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TransactionStatusChip extends StatelessWidget {
  const _TransactionStatusChip({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final isDone = status == 'realizada';
    final isPending = status == 'pendente';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDone
            ? Colors.greenAccent.withOpacity(0.15)
            : isPending
            ? Colors.orangeAccent.withOpacity(0.15)
            : Colors.white10,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isDone
            ? 'Realizada'
            : isPending
            ? 'Pendente'
            : 'Status indisponivel',
        style: TextStyle(
          color: isDone
              ? Colors.greenAccent
              : isPending
              ? Colors.orangeAccent
              : Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
