import 'package:client/data/models/account_summary_model.dart';
import 'package:client/data/models/transaction_model.dart';
import 'package:client/state/account_notifier.dart';
import 'package:client/state/transaction_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
    this.initialTransaction,
    TransactionNotifier? notifier,
    AccountNotifier? accountNotifier,
  }) : _notifier = notifier,
       _accountNotifier = accountNotifier;

  final int transactionId;
  final TransactionModel? initialTransaction;
  final TransactionNotifier? _notifier;
  final AccountNotifier? _accountNotifier;

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late final TransactionNotifier _notifier =
      widget._notifier ?? TransactionNotifier();
  late final AccountNotifier _accountNotifier =
      widget._accountNotifier ?? AccountNotifier();

  TransactionModel? _transaction;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _transaction = widget.initialTransaction;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureAccountsLoaded();
      if (_transaction == null || _transaction!.status == null) {
        await _loadTransaction();
      }
    });
  }

  Future<void> _ensureAccountsLoaded() async {
    if (_accountNotifier.accounts.isEmpty) {
      await _accountNotifier.fetchAccounts();
    }
  }

  Future<void> _loadTransaction() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final transaction = await _notifier.getTransaction(widget.transactionId);
      if (mounted) {
        setState(() => _transaction = transaction);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleStatus() async {
    final transaction = _transaction;
    if (transaction == null || transaction.id == null) {
      return;
    }

    final nextStatus =
        transaction.status == 'pendente' ? 'realizada' : 'pendente';

    setState(() => _isLoading = true);
    try {
      final updated = await _notifier.patchTransaction(transaction.id!, {
        'status': nextStatus,
      });
      if (mounted) {
        setState(() => _transaction = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nextStatus == 'realizada'
                  ? 'Transacao marcada como realizada. Agora ela afeta o saldo.'
                  : 'Transacao marcada como pendente. Ela nao afeta o saldo.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteTransaction() async {
    final transaction = _transaction;
    if (transaction == null || transaction.id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Excluir transacao',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Tem certeza que deseja excluir esta transacao?',
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
      await _notifier.deleteTransaction(transaction.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transacao excluida com sucesso.')),
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

  AccountSummaryModel? _findAccount(int? id) {
    if (id == null) {
      return null;
    }

    for (final account in _accountNotifier.accounts) {
      if (account.id == id) {
        return account;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final transaction = _transaction;
    final account = _findAccount(transaction?.conta);
    final isIncome = transaction?.tipo == 'ganho';
    final amountColor = isIncome ? Colors.greenAccent : Colors.redAccent;
    final status = transaction?.status;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Detalhe da transacao',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Editar',
            onPressed: transaction == null
                ? null
                : () async {
                    await context.push(
                      '/transactions/${widget.transactionId}/edit',
                      extra: transaction,
                    );
                    if (mounted) {
                      await _loadTransaction();
                    }
                  },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Excluir',
            onPressed: transaction == null ? null : _deleteTransaction,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _isLoading && transaction == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && transaction == null
          ? Center(
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
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadTransaction,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            )
          : transaction == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        transaction.descricao,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${isIncome ? '+' : '-'} R\$ ${transaction.valor.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: amountColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StatusChip(status: status),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _InfoTile(
                  label: 'Conta',
                  value: account?.nome ?? 'Conta #${transaction.conta ?? '-'}',
                ),
                _InfoTile(
                  label: 'Tipo',
                  value: transaction.tipo == 'ganho' ? 'Ganho' : 'Despesa',
                ),
                _InfoTile(
                  label: 'Data',
                  value: DateFormat('dd/MM/yyyy').format(transaction.dataTransacao),
                ),
                _InfoTile(
                  label: 'Impacto no saldo',
                  value: status == 'realizada'
                      ? 'Afeta o saldo da conta'
                      : status == 'pendente'
                      ? 'Nao afeta o saldo da conta'
                      : 'Status indisponivel neste momento',
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _toggleStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.sync_alt, color: Colors.white),
                  label: Text(
                    status == 'pendente'
                        ? 'Marcar como realizada'
                        : status == 'realizada'
                        ? 'Marcar como pendente'
                        : 'Atualizar status',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final isDone = status == 'realizada';
    final isPending = status == 'pendente';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDone
            ? Colors.greenAccent.withOpacity(0.15)
            : isPending
            ? Colors.orangeAccent.withOpacity(0.15)
            : Colors.white10,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isDone ? 'Realizada' : isPending ? 'Pendente' : 'Status indisponivel',
        style: TextStyle(
          color: isDone
              ? Colors.greenAccent
              : isPending
              ? Colors.orangeAccent
              : Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
