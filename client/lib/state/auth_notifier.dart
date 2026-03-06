import 'package:flutter/foundation.dart';

class AuthNotifier extends ChangeNotifier {
  static final AuthNotifier _instance = AuthNotifier._internal();

  factory AuthNotifier() => _instance;

  AuthNotifier._internal();

  String? _accessToken;
  String? _refreshToken;
  bool get isAuthenticated => _accessToken != null;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  void setTokens(String access, String refresh) {
    _accessToken = access;
    _refreshToken = refresh;
    notifyListeners();
  }

  void logout() {
    _accessToken = null;
    _refreshToken = null;
    notifyListeners();
  }
}
