import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

typedef AudioChunkCallback = void Function(Uint8List bytes);

/// Улучшенный аудио-сервис с нормализацией потока
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioChunkCallback? onChunk;
  StreamSubscription<Uint8List>? _sub;
  StreamSubscription<Amplitude>? _ampSub;

  final _levelController = StreamController<double>.broadcast();
  final _audioStreamController = StreamController<Uint8List>.broadcast();
  
  // Параметры для нормализации
  double _runningMax = 0.0;
  double _targetLevel = 0.7; // Целевой уровень нормализации (70%)
  final int _normalizationWindow = 50; // Окно для расчета максимума
  final List<double> _recentMaxes = [];
  
  Stream<double> get levelStream => _levelController.stream;
  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  AudioService({this.onChunk});

  /// Нормализует аудио чанк PCM16
  Uint8List _normalizeAudio(Uint8List input) {
    if (input.length < 2) return input;
    
    // Конвертируем байты в Int16 samples
    final samples = <int>[];
    for (int i = 0; i < input.length - 1; i += 2) {
      final sample = (input[i] | (input[i + 1] << 8));
      final signedSample = sample > 32767 ? sample - 65536 : sample;
      samples.add(signedSample);
    }
    
    // Находим максимум в текущем чанке
    int maxSample = 0;
    for (final sample in samples) {
      final absSample = sample.abs();
      if (absSample > maxSample) {
        maxSample = absSample;
      }
    }
    
    // Обновляем скользящее окно максимумов
    _recentMaxes.add(maxSample.toDouble());
    if (_recentMaxes.length > _normalizationWindow) {
      _recentMaxes.removeAt(0);
    }
    
    // Вычисляем текущий максимум из окна
    double currentMax = _recentMaxes.reduce(math.max);
    if (currentMax > _runningMax) {
      _runningMax = currentMax;
    } else {
      // Экспоненциальное затухание для адаптации к тишине
      _runningMax = _runningMax * 0.99;
    }
    
    // Вычисляем коэффициент нормализации
    double gain = 1.0;
    if (_runningMax > 0) {
      final targetSample = 32767 * _targetLevel;
      gain = targetSample / _runningMax;
      // Ограничиваем усиление (не более 3x, не менее 0.1x)
      gain = gain.clamp(0.1, 3.0);
    }
    
    // Применяем нормализацию
    final normalized = <int>[];
    for (final sample in samples) {
      final normalizedSample = (sample * gain).round().clamp(-32768, 32767);
      normalized.add(normalizedSample);
    }
    
    // Конвертируем обратно в байты
    final output = Uint8List(normalized.length * 2);
    for (int i = 0; i < normalized.length; i++) {
      final sample = normalized[i];
      output[i * 2] = sample & 0xFF;
      output[i * 2 + 1] = (sample >> 8) & 0xFF;
    }
    
    return output;
  }

  Future<bool> initAndStart() async {
    // 1) Разрешение Android на микрофон
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return false;
    }

    // 2) Разрешение на уровне плагина
    if (!await _recorder.hasPermission()) {
      return false;
    }

    // 3) Запускаем поток PCM16 16kHz mono с улучшенными настройками
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: true, // Включаем автоусиление на уровне плагина
        echoCancel: true, // Эхоподавление
        noiseSuppress: true, // Подавление шума
      ),
    );

    _sub = stream.listen((data) {
      if (data.isEmpty) return;
      final bytes = Uint8List.fromList(data);
      
      // Применяем нормализацию
      final normalized = _normalizeAudio(bytes);
      
      _audioStreamController.add(normalized);
      onChunk?.call(normalized);
    });

    // 4) Подписываемся на амплитуду для визуализации
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 200))
        .listen((amp) {
      // Значения приходят в dBFS (отрицательные). Нормализуем в 0..1.
      final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
      _levelController.add(normalized);
    });

    return true;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await _ampSub?.cancel();
    _ampSub = null;
    await _levelController.close();
    await _audioStreamController.close();
    _recentMaxes.clear();
    _runningMax = 0.0;

    await _recorder.stop();
  }
}
