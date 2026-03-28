import 'package:client/data/models/account_summary_model.dart';
import 'package:client/state/account_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({
    super.key,
    AccountNotifier? notifier,
  }) : _notifier = notifier;

  final AccountNotifier? _notifier;

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late final AccountNotifier _notifier = widget._notifier ?? AccountNotifier();
  final TextEditingController _nameFilterController = TextEditingController();

  String? _selectedType;
  String? _selectedOrdering;
  int _selectedPageSize = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLocalFilters();
      _notifier.fetchAccounts();
    });
  }

  @override
  void dispose() {
    _nameFilterController.dispose();
    super.dispose();
  }

  void _syncLocalFilters() {
    _nameFilterController.text = _notifier.filters.nome ?? '';
    _selectedType = _notifier.filters.tipo;
    _selectedOrdering = _notifier.filters.ordering;
    _selectedPageSize = _notifier.filters.pageSize;
  }

  Future<void> _applyFilters({int page = 1}) async {
    await _notifier.fetchAccounts(
      filters: AccountFilters(
        nome: _nameFilterController.text.trim().isEmpty
            ? null
            : _nameFilterController.text.trim(),
        tipo: _selectedType,
        ordering: _selectedOrdering,
        page: page,
        pageSize: _selectedPageSize,
      ),
    );
  }

  Future<void> _clearFilters() async {
    _nameFilterController.clear();
    setState(() {
      _selectedType = null;
      _selectedOrdering = null;
      _selectedPageSize = 10;
    });

    await _notifier.fetchAccounts(filters: const AccountFilters());
  }

  AccountSummaryModel? _findAccountById(int id) {
    for (final account in _notifier.accounts) {
      if (account.id == id) {
        return account;
      }
    }
    return null;
  }

  Future<void> _openAccountDetail(int id) async {
    _notifier.selectAccount(_findAccountById(id));
    await context.push('/accounts/$id');
    if (mounted) {
      await _notifier.fetchAccounts(filters: _notifier.filters);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/accounts/new'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.account_balance_wallet_outlined),
        label: const Text('Nova conta'),
      ),
      body: ListenableBuilder(
        listenable: _notifier,
        builder: (context, _) {
          return Column(
            children: [
              _AccountsFilterPanel(
                nameController: _nameFilterController,
                selectedType: _selectedType,
                selectedOrdering: _selectedOrdering,
                selectedPageSize: _selectedPageSize,
                onTypeChanged: (value) => setState(() => _selectedType = value),
                onOrderingChanged: (value) =>
                    setState(() => _selectedOrdering = value),
                onPageSizeChanged: (value) =>
                    setState(() => _selectedPageSize = value),
                onApply: _applyFilters,
                onClear: _clearFilters,
              ),
              Expanded(child: _buildBody()),
              _AccountsPaginationBar(
                pagination: _notifier.pagination,
                onPrevious: _notifier.pagination.previous == null
                    ? null
                    : () => _applyFilters(page: _notifier.filters.page - 1),
                onNext: _notifier.pagination.next == null
                    ? null
                    : () => _applyFilters(page: _notifier.filters.page + 1),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_notifier.isLoading && _notifier.accounts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifier.lastError != null && _notifier.accounts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 56),
              const SizedBox(height: 16),
              Text(
                _notifier.lastError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _notifier.fetchAccounts(filters: _notifier.filters),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifier.accounts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: Colors.white38,
              ),
              SizedBox(height: 16),
              Text(
                'Nenhuma conta encontrada',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Crie uma conta para comecar a organizar seu saldo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _notifier.fetchAccounts(filters: _notifier.filters),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        itemCount: _notifier.accounts.length,
        itemBuilder: (context, index) {
          final account = _notifier.accounts[index];
          return Card(
            color: const Color(0xFF1E1E1E),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              onTap: () => _openAccountDetail(account.id),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF6C63FF).withOpacity(0.15),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF6C63FF),
                ),
              ),
              title: Text(
                account.nome,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                _formatAccountType(account.tipo),
                style: const TextStyle(color: Colors.white54),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Saldo',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${account.saldo.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

class _AccountsFilterPanel extends StatelessWidget {
  const _AccountsFilterPanel({
    required this.nameController,
    required this.selectedType,
    required this.selectedOrdering,
    required this.selectedPageSize,
    required this.onTypeChanged,
    required this.onOrderingChanged,
    required this.onPageSizeChanged,
    required this.onApply,
    required this.onClear,
  });

  final TextEditingController nameController;
  final String? selectedType;
  final String? selectedOrdering;
  final int selectedPageSize;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onOrderingChanged;
  final ValueChanged<int> onPageSizeChanged;
  final Future<void> Function({int page}) onApply;
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
          TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Filtrar por nome',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DropdownField<String>(
                  value: selectedType,
                  hint: 'Tipo',
                  items: const [
                    DropdownMenuItem(value: 'corrente', child: Text('Corrente')),
                    DropdownMenuItem(value: 'poupanca', child: Text('Poupanca')),
                    DropdownMenuItem(
                      value: 'investimento',
                      child: Text('Investimento'),
                    ),
                    DropdownMenuItem(value: 'credito', child: Text('Credito')),
                  ],
                  onChanged: onTypeChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DropdownField<String>(
                  value: selectedOrdering,
                  hint: 'Ordenacao',
                  items: const [
                    DropdownMenuItem(value: 'nome', child: Text('Nome A-Z')),
                    DropdownMenuItem(value: '-nome', child: Text('Nome Z-A')),
                    DropdownMenuItem(value: 'saldo', child: Text('Saldo menor')),
                    DropdownMenuItem(value: '-saldo', child: Text('Saldo maior')),
                  ],
                  onChanged: onOrderingChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DropdownField<int>(
                  value: selectedPageSize,
                  hint: 'Page size',
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('5 por pagina')),
                    DropdownMenuItem(value: 10, child: Text('10 por pagina')),
                    DropdownMenuItem(value: 20, child: Text('20 por pagina')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onPageSizeChanged(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onClear,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onApply(page: 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: const Color(0xFF1E1E1E),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _AccountsPaginationBar extends StatelessWidget {
  const _AccountsPaginationBar({
    required this.pagination,
    required this.onPrevious,
    required this.onNext,
  });

  final AccountPaginationState pagination;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
        ),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Anterior'),
            ),
            Expanded(
              child: Text(
                'Pagina ${pagination.page} • ${pagination.count} contas',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Proxima'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatAccountType(String tipo) {
  switch (tipo) {
    case 'corrente':
      return 'Conta corrente';
    case 'poupanca':
      return 'Poupanca';
    case 'investimento':
      return 'Investimento';
    case 'credito':
      return 'Credito';
    default:
      return tipo;
  }
}
