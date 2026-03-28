import 'package:client/data/models/auth_user_model.dart';
import 'package:client/state/auth_notifier.dart';
import 'package:flutter/material.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthNotifier _authNotifier = AuthNotifier();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_authNotifier.isAuthenticated &&
          _authNotifier.currentUser == null &&
          !_authNotifier.isBootstrapping) {
        _authNotifier.bootstrapSession();
      }
    });
  }

  void _logout() {
    AuthNotifier().logout();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authNotifier,
      builder: (context, _) {
        final user = _authNotifier.currentUser;

        if (_authNotifier.isBootstrapping && user == null) {
          return const Center(child: CircularProgressIndicator());
        }

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
                const SizedBox(height: 12),
                _ProfileInfo(user: user, sessionError: _authNotifier.sessionError),
                const SizedBox(height: 24),
                if (_authNotifier.sessionError != null && user == null)
                  TextButton(
                    onPressed: () => _authNotifier.bootstrapSession(),
                    child: const Text('Tentar novamente'),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
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
      },
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo({
    required this.user,
    required this.sessionError,
  });

  final AuthUserModel? user;
  final String? sessionError;

  @override
  Widget build(BuildContext context) {
    final nomeCompleto = [
      user?.perfil.primeiroNome ?? '',
      user?.perfil.sobrenome ?? '',
    ].where((value) => value.isNotEmpty).join(' ');
    final saudacaoBase = user?.perfil.primeiroNome.isNotEmpty == true
        ? user!.perfil.primeiroNome
        : user?.username.isNotEmpty == true
        ? user!.username
        : 'por aqui';

    return Column(
      children: [
        Text(
          'Ola, $saudacaoBase',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          nomeCompleto.isNotEmpty ? nomeCompleto : 'Nome nao informado',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          user?.username.isNotEmpty == true
              ? '@${user!.username}'
              : 'Username indisponivel',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          user?.email.isNotEmpty == true
              ? user!.email
              : 'Email indisponivel',
          style: const TextStyle(color: Colors.white54, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          user != null ? 'Idade: ${user!.perfil.idade}' : 'Idade indisponivel',
          style: const TextStyle(color: Colors.white54, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        if (sessionError != null) ...[
          const SizedBox(height: 12),
          Text(
            sessionError!,
            style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
