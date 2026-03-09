import 'package:flutter/material.dart';
import 'package:client/ui/screens/views/transactions_view.dart';
import 'package:client/ui/screens/views/profile_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _views = const [TransactionsView(), ProfileView()];

  final List<String> _titles = const ['Transações', 'Perfil'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _views[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.white38,
        items: const [
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
