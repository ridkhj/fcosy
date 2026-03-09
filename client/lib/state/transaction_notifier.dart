import 'package:flutter/foundation.dart';
import 'package:client/data/models/transaction_model.dart';
import 'package:client/data/repositories/transaction_repository.dart';

class TransactionNotifier extends ChangeNotifier {
  static final TransactionNotifier _instance = TransactionNotifier._internal();

  factory TransactionNotifier() => _instance;

  TransactionNotifier._internal();

  final TransactionRepository _repository = TransactionRepository();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> fetchTransactions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _transactions = await _repository.getTransactions();
    } catch (e) {
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTransaction(TransactionModel transaction) async {
    await _repository.addTransaction(transaction);
    await fetchTransactions();
  }
}
