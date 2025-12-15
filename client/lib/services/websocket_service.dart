import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

typedef AnswerCallback = void Function({
  required String question,
  required String answerMarkdown,
  required DateTime timestamp,
});
typedef StatusCallback = void Function(bool connected);

class WebSocketService {
  final Uri serverUri;
  final AnswerCallback onAnswer;
  final StatusCallback? onStatusChanged;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  bool _connected = false;
  int _retryAttempts = 0;
  Timer? _reconnectTimer;

  WebSocketService({
    required this.serverUri,
    required this.onAnswer,
    this.onStatusChanged,
  });

  void connect() {
    _reconnectTimer?.cancel();
    _channel = WebSocketChannel.connect(serverUri);
    _sub = _channel!.stream.listen(
      _handleMessage,
      onError: (error) {
        _setConnected(false);
        _scheduleReconnect();
      },
      onDone: () {
        _setConnected(false);
        _scheduleReconnect();
      },
    );
    _setConnected(true);
  }

  void _handleMessage(dynamic data) {
    try {
      final jsonData = json.decode(data as String) as Map<String, dynamic>;
      final type = jsonData['type'] as String?;
      if (type == 'answer') {
        onAnswer(
          question: jsonData['question'] as String? ?? '',
          answerMarkdown: jsonData['answerMarkdown'] as String? ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            (jsonData['timestamp'] as num?)?.toInt() ?? 0,
          ),
        );
      }
    } catch (_) {
      // ignore malformed messages
    }
  }

  void _setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    onStatusChanged?.call(_connected);
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _retryAttempts += 1;
    final backoffSeconds = (_retryAttempts * 2).clamp(2, 30);
    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      connect();
    });
  }

  void sendAudioChunk({
    required String sessionId,
    required int chunkId,
    required Uint8List bytes,
  }) {
    final payload = <String, dynamic>{
      'type': 'audio_chunk',
      'sessionId': sessionId,
      'chunkId': chunkId,
      'data': base64Encode(bytes),
    };
    _channel?.sink.add(json.encode(payload));
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _channel?.sink.close();
    _reconnectTimer?.cancel();
  }
}


