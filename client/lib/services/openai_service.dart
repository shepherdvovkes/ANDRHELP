import 'dart:convert';
import 'package:http/http.dart' as http;

/// Сервис для работы с OpenAI API (детекция вопросов и генерация ответов)
class OpenAIService {
  final String apiKey;
  final String baseUrl;

  OpenAIService({
    required this.apiKey,
    this.baseUrl = 'https://api.openai.com/v1',
  });

  Future<String?> detectQuestion(String context) async {
    if (apiKey.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'Ты анализируешь последние реплики технического интервьюера. '
                  'Найди и переформулируй явный вопрос (одним предложением). '
                  'Если вопроса нет, верни ровно строку NO_QUESTION.',
            },
            {
              'role': 'user',
              'content': 'Последние реплики интервьюера:\n\n$context\n\nОтветь только вопросом или NO_QUESTION.',
            },
          ],
          'max_tokens': 64,
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final text = data['choices']?[0]?['message']?['content']?.toString().trim() ?? '';
        if (text.isEmpty || text.toUpperCase() == 'NO_QUESTION') {
          return null;
        }
        return text;
      }
    } catch (e) {
      print('OpenAIService: detectQuestion error: $e');
    }
    return null;
  }

  Future<String?> answerQuestion(String question, String context) async {
    if (apiKey.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'Ты ассистент, который помогает кандидату на техническом интервью. '
                  'Отвечай ОЧЕНЬ кратко, по существу, в 1-3 предложения. '
                  'Используй markdown. При необходимости можешь использовать код-блоки, формулы (\$...\$), '
                  'и mermaid-диаграммы (```mermaid ... ```). Если вопрос непонятен, попроси кратко уточнить.',
            },
            {
              'role': 'user',
              'content': context.isNotEmpty 
                  ? 'Контекст предыдущего диалога:\n$context\n\nВопрос интервьюера:\n$question'
                  : 'Вопрос интервьюера:\n$question',
            },
          ],
          'max_tokens': 256,
          'temperature': 0.2,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['choices']?[0]?['message']?['content']?.toString().trim();
      }
    } catch (e) {
      print('OpenAIService: answerQuestion error: $e');
    }
    return null;
  }
}

