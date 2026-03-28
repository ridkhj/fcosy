import 'package:client/data/models/auth_user_model.dart';
import 'package:client/data/repositories/auth_repository.dart';
import 'package:client/data/models/account_summary_model.dart';
import 'package:client/state/account_notifier.dart';
import 'package:client/state/auth_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({
    this.currentUser,
    this.error,
  });

  final AuthUserModel? currentUser;
  final Object? error;
  int getCurrentUserCalls = 0;

  @override
  Future<AuthUserModel> getCurrentUser() async {
    getCurrentUserCalls++;

    if (error != null) {
      throw error!;
    }

    return currentUser!;
  }
}

void main() {
  group('AuthNotifier', () {
    test('bootstrapSession loads current user when authenticated', () async {
      final repository = FakeAuthRepository(
        currentUser: const AuthUserModel(
          id: 1,
          username: 'ricardo123',
          email: 'ricardo@email.com',
          perfil: UserProfileModel(
            primeiroNome: 'Ricardo',
            sobrenome: 'Silva',
            idade: 25,
          ),
        ),
      );
      final notifier = AuthNotifier.forTest(repository: repository);

      notifier.setTokens('access', 'refresh');
      await notifier.bootstrapSession();

      expect(repository.getCurrentUserCalls, 1);
      expect(notifier.currentUser?.username, 'ricardo123');
      expect(notifier.sessionError, isNull);
      expect(notifier.isBootstrapping, isFalse);
    });

    test('bootstrapSession stores session error on failure', () async {
      final repository = FakeAuthRepository(error: Exception('Falha ao carregar'));
      final notifier = AuthNotifier.forTest(repository: repository);

      notifier.setTokens('access', 'refresh');
      await notifier.bootstrapSession();

      expect(notifier.currentUser, isNull);
      expect(notifier.sessionError, 'Exception: Falha ao carregar');
      expect(notifier.isAuthenticated, isTrue);
    });

    test('logout clears user, tokens and session state', () async {
      final notifier = AuthNotifier.forTest();
      final accountNotifier = AccountNotifier();

      notifier.setTokens('access', 'refresh');
      notifier.setCurrentUser(
        const AuthUserModel(
          id: 2,
          username: 'maria',
          email: 'maria@email.com',
          perfil: UserProfileModel(
            primeiroNome: 'Maria',
            sobrenome: 'Oliveira',
            idade: 31,
          ),
        ),
      );
      accountNotifier.selectAccount(
        const AccountSummaryModel(
          id: 1,
          nome: 'Conta Corrente',
          tipo: 'corrente',
          saldo: 560,
        ),
      );

      notifier.logout();

      expect(notifier.accessToken, isNull);
      expect(notifier.refreshToken, isNull);
      expect(notifier.currentUser, isNull);
      expect(notifier.sessionError, isNull);
      expect(notifier.isAuthenticated, isFalse);
      expect(accountNotifier.selectedAccount, isNull);
    });
  });
}
