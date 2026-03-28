import 'package:client/data/models/account_summary_model.dart';
import 'package:client/data/models/transaction_model.dart';
import 'package:client/state/account_notifier.dart';
import 'package:client/state/transaction_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.initialAccount,
    this.initialTransaction,
    AccountNotifier? accountNotifier,
    TransactionNotifier? transactionNotifier,
  }) : _accountNotifier = accountNotifier,
       _transactionNotifier = transactionNotifier;

  final AccountSummaryModel? initialAccount;
  final TransactionModel? initialTransaction;
  final AccountNotifier? _accountNotifier;
  final TransactionNotifier? _transactionNotifier;

  bool get isEditing => initialTransaction?.id != null;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();

  late final AccountNotifier _accountNotifier =
      widget._accountNotifier ?? AccountNotifier();
  late final TransactionNotifier _transactionNotifier =
      widget._transactionNotifier ?? TransactionNotifier();

  int? _selectedAccountId;
  String? _tipo;
  String? _status;
  DateTime _dataSelecionada = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _prefill();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_accountNotifier.accounts.isEmpty) {
        await _accountNotifier.fetchAccounts();
      }

      if (mounted &&
          _selectedAccountId == null &&
          _accountNotifier.selectedAccount != null) {
        setState(() => _selectedAccountId = _accountNotifier.selectedAccount!.id);
      }
    });
  }

  @override
  void dispose() {
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _prefill() {
    final initialTransaction = widget.initialTransaction;
    final initialAccount = widget.initialAccount ?? _accountNotifier.selectedAccount;

    if (initialTransaction != null) {
      _selectedAccountId = initialTransaction.conta;
      _tipo = initialTransaction.tipo;
      _status = initialTransaction.status ?? 'realizada';
      _valorController.text = initialTransaction.valor.toStringAsFixed(2);
      _descricaoController.text = initialTransaction.descricao;
      _dataSelecionada = initialTransaction.dataTransacao;
      return;
    }

    _selectedAccountId = initialAccount?.id;
    _status = 'realizada';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dataSelecionada = picked);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final valor = double.tryParse(_valorController.text.replaceAll(',', '.'));
    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um valor positivo valido.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final transaction = TransactionModel(
        id: widget.initialTransaction?.id,
        conta: _selectedAccountId,
        tipo: _tipo!,
        status: _status,
        valor: valor,
        descricao: _descricaoController.text.trim(),
        dataTransacao: _dataSelecionada,
      );

      final saved = widget.isEditing
          ? await _transactionNotifier.updateTransaction(
              widget.initialTransaction!.id!,
              transaction,
            )
          : await _transactionNotifier.createTransaction(transaction);

      if (mounted) {
        final affectsBalance = saved.status == 'realizada';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              affectsBalance
                  ? 'Transacao salva com status realizada. O saldo foi atualizado.'
                  : 'Transacao salva como pendente. O saldo nao foi alterado.',
            ),
            backgroundColor: affectsBalance ? Colors.green : Colors.orange,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Editar transacao' : 'Nova transacao';
    final hasSelectedAccount = _accountNotifier.accounts.any(
      (account) => account.id == _selectedAccountId,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _accountNotifier,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    value: hasSelectedAccount ? _selectedAccountId : null,
                    dropdownColor: const Color(0xFF1E1E1E),
                    decoration: const InputDecoration(
                      labelText: 'Conta',
                      border: OutlineInputBorder(),
                    ),
                    items: _accountNotifier.accounts
                        .map(
                          (account) => DropdownMenuItem<int>(
                            value: account.id,
                            child: Text(account.nome),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedAccountId = value),
                    validator: (value) =>
                        value == null ? 'Selecione a conta' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _tipo,
                    dropdownColor: const Color(0xFF1E1E1E),
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ganho', child: Text('Ganho')),
                      DropdownMenuItem(value: 'despesa', child: Text('Despesa')),
                    ],
                    onChanged: (value) => setState(() => _tipo = value),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Selecione o tipo' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _status,
                    dropdownColor: const Color(0xFF1E1E1E),
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'realizada',
                        child: Text('Realizada'),
                      ),
                      DropdownMenuItem(
                        value: 'pendente',
                        child: Text('Pendente'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _status = value),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Selecione o status'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status == 'pendente'
                        ? 'Transacoes pendentes nao afetam o saldo da conta.'
                        : 'Transacoes realizadas afetam o saldo da conta.',
                    style: TextStyle(
                      color: _status == 'pendente'
                          ? Colors.orangeAccent
                          : Colors.greenAccent,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _valorController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor (R\$)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe o valor';
                      final v = double.tryParse(value.replaceAll(',', '.'));
                      if (v == null) return 'Valor invalido';
                      if (v <= 0) return 'O valor deve ser positivo';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descricaoController,
                    maxLength: 255,
                    decoration: const InputDecoration(
                      labelText: 'Descricao',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Informe a descricao'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data da transacao',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_dataSelecionada),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.isEditing ? 'Salvar alteracoes' : 'Salvar',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
