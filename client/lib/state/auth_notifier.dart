import 'package:client/data/models/auth_user_model.dart';
import 'package:client/data/repositories/auth_repository.dart';
import 'package:client/state/account_notifier.dart';
import 'package:client/state/transaction_notifier.dart';
import 'package:flutter/foundation.dart';

class AuthNotifier extends ChangeNotifier {
  static final AuthNotifier _instance = AuthNotifier._internal();

  factory AuthNotifier() => _instance;

  AuthNotifier._internal({AuthRepository? repository})
    : _repository = repository;

  AuthNotifier.forTest({AuthRepository? repository}) : _repository = repository;

  AuthRepository? _repository;
  String? _accessToken;
  String? _refreshToken;
  AuthUserModel? _currentUser;
  bool _isBootstrapping = false;
  String? _sessionError;

  AuthRepository get _authRepository {
    return _repository ??= AuthRepository(authNotifier: this);
  }

  bool get isAuthenticated => _accessToken != null;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  AuthUserModel? get currentUser => _currentUser;
  bool get isBootstrapping => _isBootstrapping;
  String? get sessionError => _sessionError;

  void setTokens(String access, String refresh) {
    _accessToken = access;
    _refreshToken = refresh;
    _sessionError = null;
    notifyListeners();
  }

  void setCurrentUser(AuthUserModel? user) {
    _currentUser = user;
    _sessionError = null;
    notifyListeners();
  }

  Future<void> bootstrapSession() async {
    if (!isAuthenticated || _isBootstrapping) {
      return;
    }

    _isBootstrapping = true;
    _sessionError = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.getCurrentUser();
      _sessionError = null;
    } catch (error) {
      _currentUser = null;
      _sessionError = error.toString();

      if (!isAuthenticated) {
        _refreshToken = null;
      }
    } finally {
      _isBootstrapping = false;
      notifyListeners();
    }
  }

  void logout() {
    AccountNotifier().clear();
    TransactionNotifier().clear();
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    _sessionError = null;
    _isBootstrapping = false;
    notifyListeners();
  }
}
