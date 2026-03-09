import 'package:flutter/material.dart';
import 'package:client/state/auth_notifier.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFF6C63FF),
              child: Icon(Icons.person, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Meu Perfil',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bem-vindo ao FCosyApp!',
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => AuthNotifier().logout(),
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  'Sair',
                  style: TextStyle(color: Colors.redAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
