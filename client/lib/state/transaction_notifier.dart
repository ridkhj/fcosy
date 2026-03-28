import 'package:client/data/models/transaction_model.dart';
import 'package:client/data/repositories/transaction_repository.dart';
import 'package:client/state/account_notifier.dart';
import 'package:flutter/foundation.dart';

class TransactionFilters {
  final String? dataInicio;
  final String? dataFim;
  final int? conta;
  final String? tipo;

  const TransactionFilters({
    this.dataInicio,
    this.dataFim,
    this.conta,
    this.tipo,
  });

  TransactionFilters copyWith({
    String? dataInicio,
    String? dataFim,
    int? conta,
    String? tipo,
    bool clearDataInicio = false,
    bool clearDataFim = false,
    bool clearConta = false,
    bool clearTipo = false,
  }) {
    return TransactionFilters(
      dataInicio: clearDataInicio ? null : (dataInicio ?? this.dataInicio),
      dataFim: clearDataFim ? null : (dataFim ?? this.dataFim),
      conta: clearConta ? null : (conta ?? this.conta),
      tipo: clearTipo ? null : (tipo ?? this.tipo),
    );
  }
}

class TransactionNotifier extends ChangeNotifier {
  static final TransactionNotifier _instance = TransactionNotifier._internal();

  factory TransactionNotifier() => _instance;

  TransactionNotifier._internal({
    TransactionRepository? repository,
    AccountNotifier? accountNotifier,
  }) : _repository = repository ?? TransactionRepository(),
       _accountNotifier = accountNotifier ?? AccountNotifier();

  TransactionNotifier.forTest({
    required TransactionRepository repository,
    AccountNotifier? accountNotifier,
  }) : _repository = repository,
       _accountNotifier = accountNotifier ?? AccountNotifier.forTest();

  final TransactionRepository _repository;
  final AccountNotifier _accountNotifier;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  TransactionFilters _selectedFilters = const TransactionFilters();
  String? _lastError;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  TransactionFilters get selectedFilters => _selectedFilters;
  String? get lastError => _lastError;

  Future<TransactionModel> getTransaction(int id) async {
    return _repository.getTransaction(id);
  }

  Future<void> fetchTransactions({
    TransactionFilters? filters,
    bool replaceFilters = true,
  }) async {
    if (filters != null) {
      _selectedFilters = replaceFilters
          ? filters
          : _selectedFilters.copyWith(
              dataInicio: filters.dataInicio,
              dataFim: filters.dataFim,
              conta: filters.conta,
              tipo: filters.tipo,
              clearDataInicio: filters.dataInicio == null,
              clearDataFim: filters.dataFim == null,
              clearConta: filters.conta == null,
              clearTipo: filters.tipo == null,
            );
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      _transactions = await _repository.getTransactions(
        dataInicio: _selectedFilters.dataInicio,
        dataFim: _selectedFilters.dataFim,
        conta: _selectedFilters.conta,
        tipo: _selectedFilters.tipo,
      );
    } catch (error) {
      _transactions = [];
      _lastError = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final created = await _repository.addTransaction(transaction);
    await fetchTransactions(filters: _selectedFilters);
    await _refreshSelectedAccountDetail(preferredAccountId: created.conta);
    return created;
  }

  Future<TransactionModel> updateTransaction(
    int id,
    TransactionModel transaction,
  ) async {
    final updated = await _repository.updateTransaction(id, transaction);
    await fetchTransactions(filters: _selectedFilters);
    await _refreshSelectedAccountDetail(preferredAccountId: updated.conta);
    return updated;
  }

  Future<TransactionModel> patchTransaction(
    int id,
    Map<String, dynamic> partialData,
  ) async {
    final updated = await _repository.patchTransaction(id, partialData);
    await fetchTransactions(filters: _selectedFilters);
    await _refreshSelectedAccountDetail(preferredAccountId: updated.conta);
    return updated;
  }

  Future<void> deleteTransaction(int id) async {
    await _repository.deleteTransaction(id);
    await fetchTransactions(filters: _selectedFilters);
    await _refreshSelectedAccountDetail();
  }

  Future<void> _refreshSelectedAccountDetail({int? preferredAccountId}) async {
    final selectedAccount = _accountNotifier.selectedAccount;

    if (selectedAccount != null) {
      await _accountNotifier.refreshSelectedAccountDetail();
      return;
    }

    if (preferredAccountId == null) {
      return;
    }

    await _accountNotifier.fetchAccountDetail(preferredAccountId);
  }

  void clear() {
    _transactions = [];
    _isLoading = false;
    _selectedFilters = const TransactionFilters();
    _lastError = null;
    notifyListeners();
  }
}
