import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'statistics_service.dart';

typedef TranscriptCallback = void Function({
  required String text,
  required bool isFinal,
});

/// Сервис для прямой работы с Google Speech-to-Text Streaming API
class SpeechToTextService {
  final TranscriptCallback onTranscript;
  final String? credentialsJson;
  
  AutoRefreshingAuthClient? _authClient;
  StreamSubscription<Uint8List>? _audioSubscription;
  final List<String> _transcriptBuffer = [];
  Timer? _reconnectTimer;
  bool _isStreaming = false;
  http.StreamedRequest? _currentRequest;
  
  final String languageCode;
  final List<String> alternativeLanguageCodes;
  
  SpeechToTextService({
    required this.onTranscript,
    this.credentialsJson,
    this.languageCode = 'ru-RU',
    this.alternativeLanguageCodes = const ['en-US'],
  });

  Future<bool> initialize() async {
    try {
      if (credentialsJson == null || credentialsJson!.isEmpty) {
        print('SpeechToTextService: No credentials provided');
        return false;
      }

      final credentials = json.decode(credentialsJson!) as Map<String, dynamic>;
      final accountCredentials = ServiceAccountCredentials.fromJson(credentials);
      final scopes = ['https://www.googleapis.com/auth/cloud-platform'];
      
      _authClient = await clientViaServiceAccount(
        accountCredentials,
        scopes,
      );

      return true;
    } catch (e) {
      print('SpeechToTextService: Initialization error: $e');
      return false;
    }
  }

  Future<void> startStreaming(Stream<Uint8List> audioStream) async {
    if (_authClient == null) {
      final initialized = await initialize();
      if (!initialized) {
        print('SpeechToTextService: Failed to initialize');
        return;
      }
    }

    if (_isStreaming) {
      print('SpeechToTextService: Already streaming');
      return;
    }

    _isStreaming = true;
    _transcriptBuffer.clear();

    try {
      // URL для Streaming Recognize API
      final url = Uri.parse(
        'https://speech.googleapis.com/v1p1beta1/speech:streamingRecognize'
      );

      // Создаём стрим контроллер для запросов
      final requestController = StreamController<List<int>>();
      
      // Отправляем начальную конфигурацию
      final config = {
        'streamingConfig': {
          'config': {
            'encoding': 'LINEAR16',
            'sampleRateHertz': 16000,
            'languageCode': languageCode,
            'alternativeLanguageCodes': alternativeLanguageCodes,
            'enableAutomaticPunctuation': true,
          },
          'interimResults': true,
        },
      };
      
      requestController.add(utf8.encode(json.encode(config) + '\n'));

      // Подписываемся на аудио поток
      _audioSubscription = audioStream.listen(
        (audioChunk) {
          if (requestController.isClosed) return;
          
          final audioRequest = {
            'audioContent': base64Encode(audioChunk),
          };
          requestController.add(utf8.encode(json.encode(audioRequest) + '\n'));
        },
        onError: (error) {
          print('SpeechToTextService: Audio stream error: $error');
        },
        onDone: () {
          if (!requestController.isClosed) {
            requestController.close();
          }
        },
      );

      // Создаём HTTP запрос
      _currentRequest = http.StreamedRequest('POST', url);
      _currentRequest!.headers['Authorization'] = 
          'Bearer ${_authClient!.credentials.accessToken.data}';
      _currentRequest!.headers['Content-Type'] = 'application/json';
      
      // Подключаем стрим запросов к HTTP запросу
      requestController.stream.listen(
        (data) {
          try {
            _currentRequest!.sink.add(data);
            // Отслеживаем отправленные данные
            StatisticsService().addSpeechToTextSent(data.length);
          } catch (e) {
            // Sink уже закрыт
          }
        },
        onDone: () {
          try {
            _currentRequest!.sink.close();
          } catch (e) {
            // Sink уже закрыт
          }
        },
        onError: (error) {
          print('SpeechToTextService: Request stream error: $error');
        },
      );

      // Отправляем запрос
      final response = await _authClient!.send(_currentRequest!);

      // Читаем ответы
      response.stream.listen(
        (chunk) {
          try {
            // Отслеживаем полученные данные
            StatisticsService().addSpeechToTextReceived(chunk.length);
            
            final lines = utf8.decode(chunk).split('\n');
            for (final line in lines) {
              if (line.trim().isEmpty) continue;
              
              final responseData = json.decode(line) as Map<String, dynamic>;
              final results = responseData['results'] as List<dynamic>?;
              
              if (results != null) {
                for (final result in results) {
                  final alternatives = result['alternatives'] as List<dynamic>?;
                  if (alternatives != null && alternatives.isNotEmpty) {
                    final transcript = alternatives[0]['transcript'] as String?;
                    final isFinal = result['isFinal'] as bool? ?? false;
                    
                    if (transcript != null && transcript.isNotEmpty) {
                      if (isFinal) {
                        _transcriptBuffer.add(transcript);
                      }
                      onTranscript(text: transcript, isFinal: isFinal);
                    }
                  }
                }
              }
            }
          } catch (e) {
            print('SpeechToTextService: Error parsing response: $e');
          }
        },
        onError: (error) {
          print('SpeechToTextService: Response stream error: $error');
          _isStreaming = false;
          _scheduleReconnect(audioStream);
        },
        onDone: () {
          print('SpeechToTextService: Response stream done');
          _isStreaming = false;
        },
      );
    } catch (e) {
      print('SpeechToTextService: Start streaming error: $e');
      _isStreaming = false;
      _scheduleReconnect(audioStream);
    }
  }

  void _scheduleReconnect(Stream<Uint8List> audioStream) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      if (!_isStreaming) {
        startStreaming(audioStream);
      }
    });
  }

  String getBufferedText({int lastChars = 1000}) {
    final full = _transcriptBuffer.join(' ');
    if (full.length <= lastChars) return full;
    return full.substring(full.length - lastChars);
  }

  Future<void> stop() async {
    _isStreaming = false;
    _reconnectTimer?.cancel();
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    _currentRequest?.sink.close();
  }

  void dispose() {
    stop();
    _authClient?.close();
    _transcriptBuffer.clear();
  }
}
