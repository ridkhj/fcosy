import 'package:flutter/foundation.dart';

/// Centraliza configurações de ambiente do app.
///
/// Observação sobre localhost:
/// - Android emulator: usar 10.0.2.2 para acessar a máquina host.
/// - iOS simulator: normalmente 127.0.0.1 funciona.
/// - Windows/macOS/Linux desktop e Web: geralmente 127.0.0.1 (ou IP da máquina).
class Env {
  Env._();

  static const String _apiPort = '8000';

  /// Host do backend para cada plataforma.
  ///
  /// Se você estiver testando em dispositivo físico, troque para o IP da máquina
  /// na rede local (ex: 192.168.0.10).
  static String get apiHost {
    if (kIsWeb) return '127.0.0.1';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '10.0.2.2';
      default:
        return '127.0.0.1';
    }
  }

  /// Base URL usada pelo Dio.
  static String get apiBaseUrl => 'http://$apiHost:$_apiPort';
}
