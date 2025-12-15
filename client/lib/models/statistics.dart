class Statistics {
  final int id;
  final int speechToTextSentBytes;
  final int speechToTextReceivedBytes;
  final int openAiSentBytes;
  final int openAiReceivedBytes;
  final int questionsDetected;
  final int sentencesRecognized;
  final DateTime lastUpdated;

  Statistics({
    required this.id,
    required this.speechToTextSentBytes,
    required this.speechToTextReceivedBytes,
    required this.openAiSentBytes,
    required this.openAiReceivedBytes,
    required this.questionsDetected,
    required this.sentencesRecognized,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'speech_to_text_sent_bytes': speechToTextSentBytes,
      'speech_to_text_received_bytes': speechToTextReceivedBytes,
      'openai_sent_bytes': openAiSentBytes,
      'openai_received_bytes': openAiReceivedBytes,
      'questions_detected': questionsDetected,
      'sentences_recognized': sentencesRecognized,
      'last_updated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory Statistics.fromMap(Map<String, dynamic> map) {
    return Statistics(
      id: map['id'] as int,
      speechToTextSentBytes: map['speech_to_text_sent_bytes'] as int,
      speechToTextReceivedBytes: map['speech_to_text_received_bytes'] as int,
      openAiSentBytes: map['openai_sent_bytes'] as int,
      openAiReceivedBytes: map['openai_received_bytes'] as int,
      questionsDetected: map['questions_detected'] as int,
      sentencesRecognized: map['sentences_recognized'] as int,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['last_updated'] as int),
    );
  }

  Statistics copyWith({
    int? id,
    int? speechToTextSentBytes,
    int? speechToTextReceivedBytes,
    int? openAiSentBytes,
    int? openAiReceivedBytes,
    int? questionsDetected,
    int? sentencesRecognized,
    DateTime? lastUpdated,
  }) {
    return Statistics(
      id: id ?? this.id,
      speechToTextSentBytes: speechToTextSentBytes ?? this.speechToTextSentBytes,
      speechToTextReceivedBytes: speechToTextReceivedBytes ?? this.speechToTextReceivedBytes,
      openAiSentBytes: openAiSentBytes ?? this.openAiSentBytes,
      openAiReceivedBytes: openAiReceivedBytes ?? this.openAiReceivedBytes,
      questionsDetected: questionsDetected ?? this.questionsDetected,
      sentencesRecognized: sentencesRecognized ?? this.sentencesRecognized,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  static Statistics empty() {
    return Statistics(
      id: 1,
      speechToTextSentBytes: 0,
      speechToTextReceivedBytes: 0,
      openAiSentBytes: 0,
      openAiReceivedBytes: 0,
      questionsDetected: 0,
      sentencesRecognized: 0,
      lastUpdated: DateTime.now(),
    );
  }
}

