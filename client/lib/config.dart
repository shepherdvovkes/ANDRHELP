class AppConfig {
  /// WebSocket URI backend'а.
  ///
  /// Для dev по умолчанию используется localhost backend через Android-эмулятор.
  /// Для prod можно переопределить через:
  ///   --dart-define=WS_URI=wss://mail.s0me.uk
  static const wsUri = String.fromEnvironment(
    'WS_URI',
    defaultValue: 'ws://10.0.2.2:3100',
  );
}

class AppConfig {
  /// WebSocket URI backend-сервера.
  ///
  /// По умолчанию нацелено на прод-сервер mail.s0me.uk:4000, но может быть
  /// переопределено через:
  ///
  /// flutter run --dart-define=WS_URI=ws://10.0.2.2:4000
  static const wsUri = String.fromEnvironment(
    'WS_URI',
    defaultValue: 'ws://mail.s0me.uk:4000',
  );
}


