import 'dart:async';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

typedef AudioChunkCallback = void Function(Uint8List bytes);

/// Реальный аудио-сервис: пишет поток PCM16 16kHz
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioChunkCallback? onChunk;
  StreamSubscription<Uint8List>? _sub;
  StreamSubscription<Amplitude>? _ampSub;

  final _levelController = StreamController<double>.broadcast();
  final _audioStreamController = StreamController<Uint8List>.broadcast();
  
  Stream<double> get levelStream => _levelController.stream;
  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  AudioService({this.onChunk});

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

    // 3) Запускаем поток PCM16 16kHz mono
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _sub = stream.listen((data) {
      if (data.isEmpty) return;
      final bytes = Uint8List.fromList(data);
      _audioStreamController.add(bytes);
      onChunk?.call(bytes);
    });

    // 4) Подписываемся на амплитуду, чтобы показывать индикатор микрофона
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

    // Останавливаем запись и поток
    await _recorder.stop();
  }
}

