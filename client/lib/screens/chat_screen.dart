import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math_fork.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/app_settings.dart';
import '../models/message.dart';
import '../providers/settings_provider.dart';
import '../services/audio_service.dart';
import '../services/websocket_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  AudioService? _audioService;
  WebSocketService? _wsService;
  String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  int _chunkId = 0;
  bool _micReady = false;
  bool _wsConnected = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initStreaming();
  }

  Future<void> _initStreaming() async {
    _wsService = WebSocketService(
      serverUri: Uri.parse(AppConfig.wsUri),
      onAnswer: ({
        required String question,
        required String answerMarkdown,
        required DateTime timestamp,
      }) {
        addAssistantMessage(
          question: question,
          answerMarkdown: answerMarkdown,
          timestamp: timestamp,
        );
      },
      onStatusChanged: (connected) {
        if (!mounted) return;
        setState(() {
          _wsConnected = connected;
        });
      },
    );
    _wsService!.connect();

    _audioService = AudioService(
      onChunk: (bytes) {
        if (_isMuted) return;
        final ws = _wsService;
        if (ws == null) return;
        _chunkId += 1;
        ws.sendAudioChunk(
          sessionId: _sessionId,
          chunkId: _chunkId,
          bytes: bytes,
        );
      },
    );

    final ok = await _audioService!.initAndStart();
    if (!mounted) return;
    setState(() {
      _micReady = ok;
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioService?.stop();
    unawaited(_wsService?.dispose());
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
      // ограничиваем историю до последних 200 сообщений
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              _wsConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _wsConnected ? Colors.greenAccent : Colors.orangeAccent,
            ),
          ),
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.question.isNotEmpty)
                      Text(
                        'Вопрос: ${msg.question}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: baseFontSize,
                        ),
                      ),
                    const SizedBox(height: 8),
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
    // Very basic: render markdown, and let math be inline via flutter_math_fork
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
      builders: {
        'math': MathBuilder(baseFontSize: baseFontSize),
      },
    );
  }
}

class MathBuilder extends MarkdownElementBuilder {
  final double baseFontSize;

  MathBuilder({required this.baseFontSize});

  @override
  Widget visitText(md.Text text, TextStyle? preferredStyle) {
    final content = text.text;
    return Math.tex(
      content,
      textStyle: TextStyle(fontSize: baseFontSize),
    );
  }
}


