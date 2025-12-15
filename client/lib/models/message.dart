enum MessageRole {
  userQuestion,
  assistantAnswer,
  transcript, // Распознанный текст
  system,
}

class ChatMessage {
  final MessageRole role;
  final String question;
  final String content;
  final DateTime timestamp;
  final bool isPartial; // Для промежуточных транскриптов

  ChatMessage({
    required this.role,
    required this.question,
    required this.content,
    required this.timestamp,
    this.isPartial = false,
  });
}


