class AppConfig {
  /// WebSocket URI backend-сервера.
  ///
  /// По умолчанию нацелено на прод-сервер awe.s0me.uk по HTTPS (wss, порт 443),
  /// проксируемый через nginx на backend-контейнер ANDRHELP.
  ///
  /// Для локальной разработки можно переопределить, например:
  ///   flutter run --dart-define=WS_URI=ws://10.0.2.2:3100
  static const wsUri = String.fromEnvironment(
    'WS_URI',
    // Прод-конфиг: защищённый WebSocket через nginx на 443
    defaultValue: 'wss://awe.s0me.uk/andrhelp-ws',
  );
}

