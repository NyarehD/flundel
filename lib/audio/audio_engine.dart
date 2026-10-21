import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flundel/audio/audio_analysis.dart';
import 'package:flundel/audio/audio_engine_impl.dart';

abstract interface class AudioEngine {
  Future<void> initialize();

  Future<void> start(SoundscapeConfig config, {int sessionSeed = 42});

  Future<void> updateConfig(SoundscapeConfig config);

  Future<void> setFocusDepth(double value);

  Future<void> pause();

  Future<void> resume();

  /// Plays the app's optional completion tone while playback is still active.
  Future<void> playCompletionCue();

  /// Captures actual post-mixer output as a 48 kHz stereo PCM WAV preview.
  Future<Uint8List> captureOutputPreview(Duration duration);

  void setMasterVolume(double value);

  void setLayerMuted(String layer, bool muted);

  void setLayerSolo(String layer, bool solo);

  void setFilterCutoff(double value);

  void setReverbMix(double value);

  void setExternalPlaybackHandlers({
    required Future<void> Function() onPause,
    required Future<void> Function() onResume,
  });

  Future<void> stop();

  Stream<AudioAnalysis> get analysisStream;

  Stream<AudioEngineState> get stateStream;

  Map<String, dynamic> getDiagnostics();
}

final audioEngineProvider = Provider<AudioEngine>((ref) {
  final engine = AudioEngineImpl();
  ref.onDispose(() => engine.dispose());
  return engine;
});
