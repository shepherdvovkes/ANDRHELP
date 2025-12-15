import 'dart:async';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';

typedef AudioChunkCallback = void Function(Uint8List bytes);

/// Stubbed audio service: запрашивает разрешение, но не пишет звук.
/// Это позволяет приложению собираться и запускаться,
/// но фактическая передача аудио на backend пока не реализована.
class AudioService {
  final AudioChunkCallback onChunk;
  Timer? _timer;

  AudioService({required this.onChunk});

  Future<bool> initAndStart() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return false;
    }

    // TODO: интегрировать плагин записи аудио (например, record)
    // и вызывать onChunk с PCM16 16kHz.
    return false;
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }
}

