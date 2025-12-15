import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/app_settings.dart';
import '../models/message.dart';
import '../providers/settings_provider.dart';
import '../services/audio_service.dart';
import '../services/speech_to_text_service.dart';
import '../services/openai_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  AudioService? _audioService;
  SpeechToTextService? _speechService;
  OpenAIService? _openAIService;
  Stream<Uint8List>? _audioStream;
  
  String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  bool _micReady = false;
  bool _isMuted = false;
  bool _speechConnected = false;
  double _micLevel = 0.0;
  StreamSubscription<double>? _levelSub;
  Timer? _questionCheckTimer;
  String _currentPartialTranscript = ''; // Текущий промежуточный транскрипт
  int? _lastPartialMessageIndex; // Индекс последнего сообщения с partial транскриптом

  @override
  void initState() {
    super.initState();
    _initStreaming();
  }

  Future<void> _initStreaming() async {
    // Инициализируем OpenAI сервис
    _openAIService = OpenAIService(
      apiKey: AppConfig.openAiApiKey,
    );

    // Инициализируем Speech-to-Text сервис
    final credentialsJson = AppConfig.googleCredentialsJson;
    if (credentialsJson.isEmpty) {
      print('ChatScreen: Google credentials not provided');
      if (mounted) {
        setState(() {
          _micReady = false;
        });
      }
      return;
    }

    _speechService = SpeechToTextService(
      credentialsJson: credentialsJson,
      onTranscript: ({required String text, required bool isFinal}) {
        if (!mounted) return;
        
        if (text.isNotEmpty) {
          if (isFinal) {
            // Финальный транскрипт - добавляем как обычное сообщение
            _addTranscriptMessage(text, isFinal: true);
            _processTranscript(text);
          } else {
            // Промежуточный транскрипт - обновляем текущее сообщение
            _updatePartialTranscript(text);
          }
        }
      },
    );

    // Инициализируем аудио сервис
    _audioService = AudioService();

    final ok = await _audioService!.initAndStart();
    if (ok) {
      _levelSub = _audioService!.levelStream.listen((level) {
        if (!mounted) return;
        setState(() {
          _micLevel = level;
        });
      });

      // Получаем аудио стрим
      _audioStream = _audioService!.audioStream;
    }

    if (!mounted) return;
    setState(() {
      _micReady = ok;
    });

    // Запускаем Speech-to-Text стриминг
    if (ok && _audioStream != null && credentialsJson.isNotEmpty) {
      final initialized = await _speechService!.initialize();
      if (initialized) {
        _speechService!.startStreaming(_audioStream!);
        if (mounted) {
          setState(() {
            _speechConnected = true;
          });
        }
      }
    }
  }

  void _addTranscriptMessage(String text, {required bool isFinal}) {
    if (_isMuted) return;
    
    setState(() {
      if (isFinal) {
        // Удаляем предыдущий partial транскрипт если был
        if (_lastPartialMessageIndex != null && 
            _lastPartialMessageIndex! < _messages.length &&
            _messages[_lastPartialMessageIndex!].isPartial) {
          _messages.removeAt(_lastPartialMessageIndex!);
          _lastPartialMessageIndex = null;
        }
        
        // Добавляем финальный транскрипт
        _messages.add(
          ChatMessage(
            role: MessageRole.transcript,
            question: '',
            content: text,
            timestamp: DateTime.now(),
            isPartial: false,
          ),
        );
        _currentPartialTranscript = '';
      }
      
      const maxMessages = 200;
      if (_messages.length > maxMessages) {
        _messages.removeRange(0, _messages.length - maxMessages);
        // Обновляем индекс если нужно
        if (_lastPartialMessageIndex != null) {
          _lastPartialMessageIndex = _lastPartialMessageIndex! - 
              (_messages.length - 200);
        }
      }
    });
    _autoScroll();
  }

  void _updatePartialTranscript(String text) {
    if (_isMuted) return;
    
    setState(() {
      _currentPartialTranscript = text;
      
      if (_lastPartialMessageIndex != null && 
          _lastPartialMessageIndex! < _messages.length &&
          _messages[_lastPartialMessageIndex!].isPartial) {
        // Обновляем существующее partial сообщение
        _messages[_lastPartialMessageIndex!] = ChatMessage(
          role: MessageRole.transcript,
          question: '',
          content: text,
          timestamp: DateTime.now(),
          isPartial: true,
        );
      } else {
        // Добавляем новое partial сообщение
        _messages.add(
          ChatMessage(
            role: MessageRole.transcript,
            question: '',
            content: text,
            timestamp: DateTime.now(),
            isPartial: true,
          ),
        );
        _lastPartialMessageIndex = _messages.length - 1;
      }
    });
    _autoScroll();
  }

  void _processTranscript(String text) {
    if (_isMuted) return; // Игнорируем если микрофон выключен
    // Проверяем наличие вопроса в тексте
    final context = _speechService!.getBufferedText();
    _checkForQuestion(context);
  }

  Future<void> _checkForQuestion(String context) async {
    if (context.trim().isEmpty) return;
    if (_openAIService == null) return;

    // Простая эвристика: проверяем наличие маркеров вопроса
    final hasQuestionMarkers = context.contains('?') ||
        context.toLowerCase().contains('что') ||
        context.toLowerCase().contains('как') ||
        context.toLowerCase().contains('почему') ||
        context.toLowerCase().contains('где') ||
        context.toLowerCase().contains('объясни');

    if (!hasQuestionMarkers) return;

    try {
      final question = await _openAIService!.detectQuestion(context);
      if (question != null && question.isNotEmpty) {
        // Найден вопрос - генерируем ответ
        final answer = await _openAIService!.answerQuestion(question, context);
        if (answer != null && answer.isNotEmpty) {
          addAssistantMessage(
            question: question,
            answerMarkdown: answer,
            timestamp: DateTime.now(),
          );
        }
      }
    } catch (e) {
      print('ChatScreen: Error processing question: $e');
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    // Mute только останавливает обработку, но не останавливает стриминг
    // чтобы не терять соединение с Google API
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _levelSub?.cancel();
    _questionCheckTimer?.cancel();
    _audioService?.stop();
    _speechService?.dispose();
    super.dispose();
  }

  void addAssistantMessage({
    required String question,
    required String answerMarkdown,
    required DateTime timestamp,
  }) {
    setState(() {
      _messages.add(
        ChatMessage(
          role: MessageRole.assistantAnswer,
          question: question,
          content: answerMarkdown,
          timestamp: timestamp,
        ),
      );
      const maxMessages = 200;
      if (_messages.length > maxMessages) {
        _messages.removeRange(0, _messages.length - maxMessages);
      }
    });
    _autoScroll();
  }

  void _autoScroll() {
    final settings = context.read<SettingsProvider>().settings;
    if (!settings.autoScrollEnabled) return;
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isNearBottom =
        position.maxScrollExtent - position.pixels < 200.0;
    if (!isNearBottom) return;

    final duration = Duration(
      milliseconds: (300 ~/ settings.autoScrollSpeed),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: duration,
        curve: Curves.easeOut,
      );
    });
  }

  double _fontSizeFor(AppSettings settings) {
    switch (settings.fontSizeLevel) {
      case 1:
        return 12;
      case 2:
        return 14;
      case 4:
        return 18;
      case 5:
        return 20;
      case 3:
      default:
        return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final baseFontSize = _fontSizeFor(settings);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ANDRHELPER'),
        actions: [
          IconButton(
            icon: Icon(
              _isMuted ? Icons.mic_off : Icons.mic,
              color: _isMuted ? Colors.redAccent : null,
            ),
            onPressed: _micReady ? _toggleMute : null,
            tooltip: _isMuted ? 'Включить микрофон' : 'Выключить микрофон',
          ),
          if (!_micReady)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.mic_off, color: Colors.redAccent),
            ),
          if (_micReady)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 40,
                child: LinearProgressIndicator(
                  value: _micLevel,
                  backgroundColor: Colors.black26,
                  color: Colors.greenAccent,
                  minHeight: 4,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              _speechConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _speechConnected ? Colors.greenAccent : Colors.orangeAccent,
            ),
          ),
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[index];
          
          // Определяем цвет карточки в зависимости от типа сообщения
          Color? cardColor;
          if (msg.role == MessageRole.transcript) {
            cardColor = msg.isPartial 
                ? Colors.blue.shade50 
                : Colors.grey.shade100;
          } else if (msg.role == MessageRole.assistantAnswer) {
            cardColor = Colors.green.shade50;
          }
          
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок в зависимости от типа сообщения
                    if (msg.role == MessageRole.transcript)
                      Row(
                        children: [
                          Icon(
                            msg.isPartial ? Icons.mic : Icons.text_fields,
                            size: 16,
                            color: msg.isPartial 
                                ? Colors.blue 
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            msg.isPartial ? 'Распознавание...' : 'Распознано:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: baseFontSize * 0.9,
                              color: msg.isPartial 
                                  ? Colors.blue 
                                  : Colors.grey.shade700,
                              fontStyle: msg.isPartial 
                                  ? FontStyle.italic 
                                  : FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    if (msg.role == MessageRole.assistantAnswer && msg.question.isNotEmpty)
                      Text(
                        'Вопрос: ${msg.question}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: baseFontSize,
                        ),
                      ),
                    if (msg.role == MessageRole.assistantAnswer && msg.question.isNotEmpty)
                      const SizedBox(height: 8),
                    // Контент
                    if (msg.role == MessageRole.transcript)
                      Text(
                        msg.content,
                        style: TextStyle(
                          fontSize: baseFontSize,
                          fontStyle: msg.isPartial 
                              ? FontStyle.italic 
                              : FontStyle.normal,
                          color: msg.isPartial 
                              ? Colors.blue.shade700 
                              : Colors.black87,
                        ),
                      )
                    else
                      _MarkdownWithMath(
                        data: msg.content,
                        baseFontSize: baseFontSize,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      msg.timestamp.toLocal().toIso8601String(),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: baseFontSize * 0.7),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Simple markdown renderer with math blocks support.
class _MarkdownWithMath extends StatelessWidget {
  final String data;
  final double baseFontSize;

  const _MarkdownWithMath({
    required this.data,
    required this.baseFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: TextStyle(fontSize: baseFontSize),
        code: TextStyle(
          fontSize: baseFontSize * 0.9,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
