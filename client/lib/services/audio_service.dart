import 'dart:async';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

typedef AudioChunkCallback = void Function(Uint8List bytes);

class AudioService {
  final Record _record = Record();
  final AudioChunkCallback onChunk;
  Timer? _timer;

  AudioService({required this.onChunk});

  Future<bool> initAndStart() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return false;
    }

    final canRecord = await _record.hasPermission();
    if (!canRecord) return false;

    await _record.start(
      encoder: AudioEncoder.pcm16bits,
      samplingRate: 16000,
      numChannels: 1,
    );

    // Polling-based chunk extraction; in production you may want true streaming.
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      final bytes = await _record.stop();
      if (bytes != null) {
        onChunk(Uint8List.fromList(bytes));
      }
      await _record.start(
        encoder: AudioEncoder.pcm16bits,
        samplingRate: 16000,
        numChannels: 1,
      );
    });

    return true;
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    if (await _record.isRecording()) {
      await _record.stop();
    }
  }
}


