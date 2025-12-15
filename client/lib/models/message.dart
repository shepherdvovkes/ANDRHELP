enum MessageRole {
  userQuestion,
  assistantAnswer,
  system,
}

class ChatMessage {
  final MessageRole role;
  final String question;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.question,
    required this.content,
    required this.timestamp,
  });
}


