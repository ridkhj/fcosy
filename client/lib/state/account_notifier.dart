import 'package:client/data/models/account_detail_model.dart';
import 'package:client/data/models/account_summary_model.dart';
import 'package:client/data/models/paginated_response.dart';
import 'package:client/data/repositories/account_repository.dart';
import 'package:flutter/foundation.dart';

class AccountFilters {
  final String? ordering;
  final String? tipo;
  final String? nome;
  final int page;
  final int pageSize;

  const AccountFilters({
    this.ordering,
    this.tipo,
    this.nome,
    this.page = 1,
    this.pageSize = 10,
  });

  AccountFilters copyWith({
    String? ordering,
    String? tipo,
    String? nome,
    int? page,
    int? pageSize,
  }) {
    return AccountFilters(
      ordering: ordering ?? this.ordering,
      tipo: tipo ?? this.tipo,
      nome: nome ?? this.nome,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class AccountPaginationState {
  final int count;
  final String? next;
  final String? previous;
  final int page;
  final int pageSize;

  const AccountPaginationState({
    this.count = 0,
    this.next,
    this.previous,
    this.page = 1,
    this.pageSize = 10,
  });

  AccountPaginationState copyWith({
    int? count,
    String? next,
    bool clearNext = false,
    String? previous,
    bool clearPrevious = false,
    int? page,
    int? pageSize,
  }) {
    return AccountPaginationState(
      count: count ?? this.count,
      next: clearNext ? null : (next ?? this.next),
      previous: clearPrevious ? null : (previous ?? this.previous),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class AccountNotifier extends ChangeNotifier {
  static final AccountNotifier _instance = AccountNotifier._internal();

  factory AccountNotifier() => _instance;

  AccountNotifier._internal({AccountRepository? repository})
    : _repository = repository ?? AccountRepository();

  AccountNotifier.forTest({AccountRepository? repository})
    : _repository = repository ?? AccountRepository();

  final AccountRepository _repository;

  List<AccountSummaryModel> _accounts = [];
  AccountSummaryModel? _selectedAccount;
  AccountDetailModel? _accountDetail;
  bool _isLoading = false;
  String? _lastError;
  AccountPaginationState _pagination = const AccountPaginationState();
  AccountFilters _filters = const AccountFilters();
  String? _selectedMonth;

  List<AccountSummaryModel> get accounts => _accounts;
  AccountSummaryModel? get selectedAccount => _selectedAccount;
  AccountDetailModel? get accountDetail => _accountDetail;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  AccountPaginationState get pagination => _pagination;
  AccountFilters get filters => _filters;
  String? get selectedMonth => _selectedMonth;

  Future<void> fetchAccounts({AccountFilters? filters}) async {
    if (filters != null) {
      _filters = filters;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await _repository.getAccounts(
        page: _filters.page,
        pageSize: _filters.pageSize,
        ordering: _filters.ordering,
        tipo: _filters.tipo,
        nome: _filters.nome,
      );

      _applyAccountListResponse(response);
    } catch (error) {
      _accounts = [];
      _pagination = _pagination.copyWith(
        count: 0,
        clearNext: true,
        clearPrevious: true,
      );
      _lastError = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAccountDetail(int id, {String? mes}) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final detail = await _repository.getAccountDetail(id, mes: mes);
      _accountDetail = detail;
      _selectedMonth = mes ?? detail.mesReferencia;
      _selectedAccount = _accounts.cast<AccountSummaryModel?>().firstWhere(
        (account) => account?.id == id,
        orElse: () =>
            _selectedAccount ??
            AccountSummaryModel(
              id: detail.id,
              nome: detail.nome,
              tipo: detail.tipo,
              saldo: detail.saldo,
            ),
      );
    } catch (error) {
      _accountDetail = null;
      _lastError = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSelectedAccountDetail() async {
    final selectedId = _selectedAccount?.id ?? _accountDetail?.id;
    if (selectedId == null) {
      return;
    }

    await fetchAccountDetail(selectedId, mes: _selectedMonth);
  }

  void selectAccount(AccountSummaryModel? account) {
    _selectedAccount = account;
    notifyListeners();
  }

  Future<AccountSummaryModel> createAccount({
    required String nome,
    required String tipo,
    double? saldo,
  }) async {
    final created = await _repository.createAccount(
      nome: nome,
      tipo: tipo,
      saldo: saldo,
    );
    _selectedAccount = created;
    await fetchAccounts(filters: _filters);
    return created;
  }

  Future<AccountSummaryModel> updateAccount({
    required int id,
    required String nome,
    required String tipo,
    required double saldo,
  }) async {
    final updated = await _repository.updateAccount(
      id: id,
      nome: nome,
      tipo: tipo,
      saldo: saldo,
    );
    await fetchAccounts(filters: _filters);
    await fetchAccountDetail(id, mes: _selectedMonth);
    return updated;
  }

  Future<AccountSummaryModel> patchAccount(
    int id, {
    String? nome,
    String? tipo,
    double? saldo,
  }) async {
    final updated = await _repository.patchAccount(
      id,
      nome: nome,
      tipo: tipo,
      saldo: saldo,
    );
    await fetchAccounts(filters: _filters);
    await fetchAccountDetail(id, mes: _selectedMonth);
    return updated;
  }

  Future<void> deleteAccount(int id) async {
    await _repository.deleteAccount(id);

    if (_selectedAccount?.id == id) {
      _selectedAccount = null;
      _accountDetail = null;
      _selectedMonth = null;
    }

    await fetchAccounts(filters: _filters);
  }

  void clear() {
    _accounts = [];
    _selectedAccount = null;
    _accountDetail = null;
    _isLoading = false;
    _lastError = null;
    _pagination = const AccountPaginationState();
    _filters = const AccountFilters();
    _selectedMonth = null;
    notifyListeners();
  }

  void _applyAccountListResponse(
    PaginatedResponse<AccountSummaryModel> response,
  ) {
    _accounts = response.results;
    _pagination = AccountPaginationState(
      count: response.count,
      next: response.next,
      previous: response.previous,
      page: _filters.page,
      pageSize: _filters.pageSize,
    );

    if (_selectedAccount != null) {
      _selectedAccount = _accounts.cast<AccountSummaryModel?>().firstWhere(
        (account) => account?.id == _selectedAccount?.id,
        orElse: () => _selectedAccount,
      );
    }
  }
}
