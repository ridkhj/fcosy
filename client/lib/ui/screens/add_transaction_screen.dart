import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:client/data/models/transaction_model.dart';
import 'package:client/state/transaction_notifier.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();

  String? _tipo;
  DateTime _dataSelecionada = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
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
          content: Text('Informe um valor positivo válido.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final transaction = TransactionModel(
        tipo: _tipo!,
        valor: valor,
        descricao: _descricaoController.text.trim(),
        data: _dataSelecionada,
      );

      await TransactionNotifier().createTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transação adicionada com sucesso!'),
            backgroundColor: Colors.green,
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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Nova Transação',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tipo
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ganho', child: Text('Ganho')),
                  DropdownMenuItem(value: 'despesa', child: Text('Despesa')),
                ],
                onChanged: (value) => setState(() => _tipo = value),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Selecione o tipo'
                    : null,
              ),
              const SizedBox(height: 16),

              // Valor
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
                  if (v == null) return 'Valor inválido';
                  if (v <= 0) return 'O valor deve ser positivo';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descrição
              TextFormField(
                controller: _descricaoController,
                maxLength: 255,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Informe a descrição'
                    : null,
              ),
              const SizedBox(height: 8),

              // Data
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
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

              // Salvar
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
                    : const Text(
                        'Salvar',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
