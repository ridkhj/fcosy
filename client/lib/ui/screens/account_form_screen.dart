import 'package:client/data/models/account_summary_model.dart';
import 'package:client/state/account_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountFormScreen extends StatefulWidget {
  const AccountFormScreen({
    super.key,
    this.accountId,
    this.initialAccount,
    AccountNotifier? notifier,
  }) : _notifier = notifier;

  final int? accountId;
  final AccountSummaryModel? initialAccount;
  final AccountNotifier? _notifier;

  bool get isEditing => accountId != null;

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  late final AccountNotifier _notifier = widget._notifier ?? AccountNotifier();

  String? _selectedType;
  bool _isLoading = false;
  bool _didPrefill = false;

  @override
  void initState() {
    super.initState();
    _prefillFromAvailableData();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.isEditing &&
          !_didPrefill &&
          widget.accountId != null &&
          widget.initialAccount == null) {
        await _notifier.fetchAccountDetail(widget.accountId!);
        if (mounted) {
          _prefillFromAvailableData();
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _prefillFromAvailableData() {
    if (_didPrefill) {
      return;
    }

    final initial =
        widget.initialAccount ??
        _notifier.selectedAccount ??
        (_notifier.accountDetail != null
            ? AccountSummaryModel(
                id: _notifier.accountDetail!.id,
                nome: _notifier.accountDetail!.nome,
                tipo: _notifier.accountDetail!.tipo,
                saldo: _notifier.accountDetail!.saldo,
              )
            : null);

    if (initial != null) {
      _nameController.text = initial.nome;
      _selectedType = initial.tipo;
      _balanceController.text = initial.saldo.toStringAsFixed(2);
      _didPrefill = true;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final saldoText = _balanceController.text.trim();
    final parsedSaldo = saldoText.isEmpty
        ? null
        : double.tryParse(saldoText.replaceAll(',', '.'));

    if (saldoText.isNotEmpty && parsedSaldo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um saldo valido.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.isEditing) {
        await _notifier.updateAccount(
          id: widget.accountId!,
          nome: _nameController.text.trim(),
          tipo: _selectedType!,
          saldo: parsedSaldo ?? 0,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conta atualizada com sucesso.')),
          );
          context.pop();
        }
      } else {
        final created = await _notifier.createAccount(
          nome: _nameController.text.trim(),
          tipo: _selectedType!,
          saldo: parsedSaldo,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conta criada com sucesso.')),
          );
          context.go('/accounts/${created.id}');
        }
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

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Editar conta' : 'Nova conta';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Nome da conta',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome da conta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Tipo da conta',
                  icon: Icons.category_outlined,
                ),
                items: const [
                  DropdownMenuItem(value: 'corrente', child: Text('Corrente')),
                  DropdownMenuItem(value: 'poupanca', child: Text('Poupanca')),
                  DropdownMenuItem(
                    value: 'investimento',
                    child: Text('Investimento'),
                  ),
                  DropdownMenuItem(value: 'credito', child: Text('Credito')),
                ],
                onChanged: (value) => setState(() => _selectedType = value),
                validator: (value) =>
                    value == null ? 'Selecione o tipo da conta' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                style: const TextStyle(color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(
                  label: 'Saldo inicial (opcional)',
                  icon: Icons.attach_money_outlined,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.isEditing ? 'Salvar alteracoes' : 'Criar conta',
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
    );
  }
}
