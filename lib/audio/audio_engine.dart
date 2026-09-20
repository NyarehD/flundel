import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flundel/audio/audio_analysis.dart';
import 'package:flundel/audio/audio_engine_impl.dart';

abstract interface class AudioEngine {
  Future<void> initialize();

  Future<void> start(SoundscapeConfig config);

  Future<void> updateConfig(SoundscapeConfig config);

  Future<void> stop();

  Stream<AudioAnalysis> get analysisStream;

  Stream<AudioEngineState> get stateStream;
}

final audioEngineProvider = Provider<AudioEngine>((ref) {
  final engine = AudioEngineImpl();
  engine.initialize();
  ref.onDispose(() => engine.stop());
  return engine;
});
