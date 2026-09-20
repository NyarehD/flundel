import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flundel/audio/audio_analysis.dart';
import 'package:flundel/audio/audio_engine_impl.dart';

abstract interface class AudioEngine {
  Future<void> initialize();

  Future<void> start(
    SoundscapeConfig config, {
    int sessionSeed = 42,
  });

  Future<void> updateConfig(SoundscapeConfig config);

  Future<void> setFocusDepth(double value);

  Future<void> stop();

  Stream<AudioAnalysis> get analysisStream;

  Stream<AudioEngineState> get stateStream;

  Map<String, dynamic> getDiagnostics();
}

final audioEngineProvider = Provider<AudioEngine>((ref) {
  final engine = AudioEngineImpl();
  engine.initialize();
  ref.onDispose(() => engine.stop());
  return engine;
});
