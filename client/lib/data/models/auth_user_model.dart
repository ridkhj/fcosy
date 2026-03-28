class UserProfileModel {
  final String primeiroNome;
  final String sobrenome;
  final int idade;

  const UserProfileModel({
    required this.primeiroNome,
    required this.sobrenome,
    required this.idade,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      primeiroNome: json['primeiro_nome'] as String? ?? '',
      sobrenome: json['sobrenome'] as String? ?? '',
      idade: json['idade'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primeiro_nome': primeiroNome,
      'sobrenome': sobrenome,
      'idade': idade,
    };
  }
}

class AuthUserModel {
  final int id;
  final String username;
  final String email;
  final UserProfileModel perfil;

  const AuthUserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.perfil,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      perfil: UserProfileModel.fromJson(
        (json['perfil'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'perfil': perfil.toJson(),
    };
  }
}
