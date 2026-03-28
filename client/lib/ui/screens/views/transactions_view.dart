import 'package:client/data/models/account_summary_model.dart';
import 'package:client/data/models/transaction_model.dart';
import 'package:client/state/account_notifier.dart';
import 'package:client/state/transaction_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({
    super.key,
    TransactionNotifier? transactionNotifier,
    AccountNotifier? accountNotifier,
  }) : _transactionNotifier = transactionNotifier,
       _accountNotifier = accountNotifier;

  final TransactionNotifier? _transactionNotifier;
  final AccountNotifier? _accountNotifier;

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  late final TransactionNotifier _transactionNotifier =
      widget._transactionNotifier ?? TransactionNotifier();
  late final AccountNotifier _accountNotifier =
      widget._accountNotifier ?? AccountNotifier();

  DateTime? _dataInicio;
  DateTime? _dataFim;
  int? _selectedContaId;
  String? _selectedTipo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureAccountsLoaded();
      _syncFromNotifier();
      await _transactionNotifier.fetchTransactions();
    });
  }

  Future<void> _ensureAccountsLoaded() async {
    if (_accountNotifier.accounts.isEmpty) {
      await _accountNotifier.fetchAccounts();
    }
  }

  void _syncFromNotifier() {
    final filters = _transactionNotifier.selectedFilters;
    _selectedContaId = filters.conta;
    _selectedTipo = filters.tipo;
    _dataInicio = _parseDate(filters.dataInicio);
    _dataFim = _parseDate(filters.dataFim);
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  String? _formatDate(DateTime? value) {
    if (value == null) {
      return null;
    }

    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _pickDate({
    required bool isStart,
  }) async {
    final initialDate = isStart
        ? (_dataInicio ?? DateTime.now())
        : (_dataFim ?? _dataInicio ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _dataInicio = picked;
        } else {
          _dataFim = picked;
        }
      });
    }
  }

  Future<void> _applyFilters() async {
    await _transactionNotifier.fetchTransactions(
      filters: TransactionFilters(
        dataInicio: _formatDate(_dataInicio),
        dataFim: _formatDate(_dataFim),
        conta: _selectedContaId,
        tipo: _selectedTipo,
      ),
    );
  }

  Future<void> _clearFilters() async {
    setState(() {
      _dataInicio = null;
      _dataFim = null;
      _selectedContaId = null;
      _selectedTipo = null;
    });

    await _transactionNotifier.fetchTransactions(
      filters: const TransactionFilters(),
    );
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
    final hasSelectedAccount = _accountNotifier.accounts.any(
      (account) => account.id == _selectedContaId,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/new'),
        tooltip: 'Nova transacao',
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_transactionNotifier, _accountNotifier]),
        builder: (context, _) {
          return Column(
            children: [
              _TransactionFilterPanel(
                accounts: _accountNotifier.accounts,
                selectedContaId: hasSelectedAccount ? _selectedContaId : null,
                selectedTipo: _selectedTipo,
                dataInicio: _dataInicio,
                dataFim: _dataFim,
                onContaChanged: (value) => setState(() => _selectedContaId = value),
                onTipoChanged: (value) => setState(() => _selectedTipo = value),
                onPickStartDate: () => _pickDate(isStart: true),
                onPickEndDate: () => _pickDate(isStart: false),
                onApply: _applyFilters,
                onClear: _clearFilters,
              ),
              Expanded(child: _buildBody()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_transactionNotifier.isLoading && _transactionNotifier.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactionNotifier.lastError != null &&
        _transactionNotifier.transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 56),
              const SizedBox(height: 16),
              Text(
                _transactionNotifier.lastError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _applyFilters,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_transactionNotifier.transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.white38,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhuma transacao encontrada',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Ajuste os filtros ou toque no botao + para adicionar.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _applyFilters,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: _transactionNotifier.transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactionNotifier.transactions[index];
          final isIncome = transaction.tipo == 'ganho';
          final amountColor = isIncome ? Colors.greenAccent : Colors.redAccent;
          final sign = isIncome ? '+' : '-';
          final account = _findAccount(transaction.conta);
          final showAccount = _transactionNotifier.selectedFilters.conta == null;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFF1E1E1E),
            child: ListTile(
              onTap: () => context.push(
                '/transactions/${transaction.id}',
                extra: transaction,
              ),
              leading: CircleAvatar(
                backgroundColor: amountColor.withOpacity(0.15),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: amountColor,
                  size: 20,
                ),
              ),
              title: Text(
                transaction.descricao.isNotEmpty
                    ? transaction.descricao
                    : '(sem descricao)',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(transaction.dataTransacao),
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _TransactionStatusChip(status: transaction.status),
                      if (showAccount)
                        _InlinePill(
                          label: account?.nome ??
                              'Conta #${transaction.conta?.toString() ?? '-'}',
                        ),
                    ],
                  ),
                ],
              ),
              trailing: Text(
                '$sign R\$ ${transaction.valor.toStringAsFixed(2)}',
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TransactionFilterPanel extends StatelessWidget {
  const _TransactionFilterPanel({
    required this.accounts,
    required this.selectedContaId,
    required this.selectedTipo,
    required this.dataInicio,
    required this.dataFim,
    required this.onContaChanged,
    required this.onTipoChanged,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onApply,
    required this.onClear,
  });

  final List<AccountSummaryModel> accounts;
  final int? selectedContaId;
  final String? selectedTipo;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final ValueChanged<int?> onContaChanged;
  final ValueChanged<String?> onTipoChanged;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final Future<void> Function() onApply;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedContaId,
                  dropdownColor: const Color(0xFF1E1E1E),
                  decoration: _decoration('Conta'),
                  items: accounts
                      .map(
                        (account) => DropdownMenuItem<int>(
                          value: account.id,
                          child: Text(account.nome),
                        ),
                      )
                      .toList(),
                  onChanged: onContaChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedTipo,
                  dropdownColor: const Color(0xFF1E1E1E),
                  decoration: _decoration('Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'ganho', child: Text('Ganho')),
                    DropdownMenuItem(value: 'despesa', child: Text('Despesa')),
                  ],
                  onChanged: onTipoChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickStartDate,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    dataInicio == null
                        ? 'Inicio'
                        : DateFormat('dd/MM/yyyy').format(dataInicio!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickEndDate,
                  icon: const Icon(Icons.event),
                  label: Text(
                    dataFim == null
                        ? 'Fim'
                        : DateFormat('dd/MM/yyyy').format(dataFim!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onClear,
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                  ),
                  child: const Text(
                    'Aplicar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
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

    return _InlinePill(
      label: isDone ? 'Realizada' : 'Pendente',
      backgroundColor: isDone
          ? Colors.greenAccent.withOpacity(0.15)
          : Colors.orangeAccent.withOpacity(0.15),
      textColor: isDone ? Colors.greenAccent : Colors.orangeAccent,
    );
  }
}

class _InlinePill extends StatelessWidget {
  const _InlinePill({
    required this.label,
    this.backgroundColor = const Color(0x33212121),
    this.textColor = Colors.white70,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
