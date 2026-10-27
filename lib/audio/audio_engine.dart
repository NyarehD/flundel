import 'dart:async';
import 'dart:typed_data';

import 'package:flundel/audio/audio_analysis.dart';
import 'package:flundel/audio/audio_engine_impl.dart';
import 'package:flundel/audio/audio_session_context.dart';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class AudioEngine {
  Future<void> initialize();

  Future<void> start(
    SoundscapeConfig config, {
    int sessionSeed = 42,
    AudioSessionContext? context,
    Map<String, dynamic>? checkpoint,
    bool startPaused = false,
  });

  Future<void> updateSessionContext(AudioSessionContext context);
  AudioPlaybackSnapshot get playbackSnapshot;
  AudioDiagnostics get diagnostics;
  Future<Map<String, dynamic>> captureCheckpoint();
  Future<void> dispose();

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
    Future<void> Function()? onPause,
    Future<void> Function()? onResume,
  });

  Future<void> stop();

  Stream<AudioAnalysis> get analysisStream;

  Stream<AudioEngineState> get stateStream;

  Map<String, dynamic> getDiagnostics();
}

final audioEngineProvider = Provider<AudioEngine>((ref) {
  final engine = AudioEngineImpl();
  ref.onDispose(engine.dispose);
  return engine;
});
