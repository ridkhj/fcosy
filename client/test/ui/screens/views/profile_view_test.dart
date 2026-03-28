import 'package:client/data/models/auth_user_model.dart';
import 'package:client/state/auth_notifier.dart';
import 'package:client/ui/screens/views/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ProfileView renders authenticated user data', (tester) async {
    final authNotifier = AuthNotifier();
    authNotifier.setTokens('access', 'refresh');
    authNotifier.setCurrentUser(
      const AuthUserModel(
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

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF121212),
          body: ProfileView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ola, Ricardo'), findsOneWidget);
    expect(find.text('Ricardo Silva'), findsOneWidget);
    expect(find.text('@ricardo123'), findsOneWidget);
    expect(find.text('ricardo@email.com'), findsOneWidget);
    expect(find.text('Idade: 25'), findsOneWidget);

    authNotifier.logout();
  });
}
