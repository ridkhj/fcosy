import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:client/ui/screens/accounts_screen.dart';
import 'package:client/ui/screens/views/transactions_view.dart';
import 'package:client/ui/screens/views/profile_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  static const List<Widget> _views = [
    AccountsScreen(),
    TransactionsView(),
    ProfileView(),
  ];

  static const List<String> _titles = ['Contas', 'Transações', 'Perfil'];
  static const List<String> _routes = ['/', '/transactions', '/profile'];

  @override
  Widget build(BuildContext context) {
    final currentIndex = initialIndex.clamp(0, _views.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          _titles[currentIndex],
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: IndexedStack(index: currentIndex, children: _views),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index != currentIndex) {
            context.go(_routes[index]);
          }
        },
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Contas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transações',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
