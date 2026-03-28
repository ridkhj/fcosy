import 'package:client/data/models/auth_user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthUserModel', () {
    test('parses authenticated user payload', () {
      final model = AuthUserModel.fromJson({
        'id': 1,
        'username': 'ricardo123',
        'email': 'ricardo@email.com',
        'perfil': {
          'primeiro_nome': 'Ricardo',
          'sobrenome': 'Silva',
          'idade': 25,
        },
      });

      expect(model.id, 1);
      expect(model.username, 'ricardo123');
      expect(model.email, 'ricardo@email.com');
      expect(model.perfil.primeiroNome, 'Ricardo');
      expect(model.perfil.sobrenome, 'Silva');
      expect(model.perfil.idade, 25);
    });

    test('serializes authenticated user payload', () {
      const model = AuthUserModel(
        id: 2,
        username: 'maria',
        email: 'maria@email.com',
        perfil: UserProfileModel(
          primeiroNome: 'Maria',
          sobrenome: 'Oliveira',
          idade: 31,
        ),
      );

      expect(model.toJson(), {
        'id': 2,
        'username': 'maria',
        'email': 'maria@email.com',
        'perfil': {
          'primeiro_nome': 'Maria',
          'sobrenome': 'Oliveira',
          'idade': 31,
        },
      });
    });
  });
}
