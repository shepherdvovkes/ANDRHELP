class AppConfig {
  /// OpenAI API Key для детекции вопросов и генерации ответов
  static const openAiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  /// Google Cloud Service Account JSON (для Speech-to-Text)
  /// Можно передать через dart-define или загрузить из assets
  static const googleCredentialsJson = String.fromEnvironment(
    'GOOGLE_CREDENTIALS_JSON',
    defaultValue: '',
  );
}

