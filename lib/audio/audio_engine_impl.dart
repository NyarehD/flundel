import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flundel/audio/audio_analysis.dart';
import 'package:flundel/audio/audio_engine.dart';
import 'package:flundel/audio/synthetic_audio.dart';

class AudioEngineImpl implements AudioEngine {
  final _analysisController = StreamController<AudioAnalysis>.broadcast();
  final _stateController = StreamController<AudioEngineState>.broadcast();

  AudioEngineState _currentState = AudioEngineState.stopped;
  SoundscapeConfig _currentConfig = const SoundscapeConfig();
  Timer? _proceduralTickTimer;
  final Random _random = Random();

  late final AudioPlayer _noisePlayer;
  late final AudioPlayer _padPlayer;
  late final AudioPlayer _binauralPlayer;
  late final AudioPlayer _pianoPlayer;

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    _noisePlayer = AudioPlayer();
    _padPlayer = AudioPlayer();
    _binauralPlayer = AudioPlayer();
    _pianoPlayer = AudioPlayer();

    try {
      final noiseUri = SyntheticAudio.createWarmNoiseWavUri();
      final padUri = SyntheticAudio.createEtherealPadWavUri();
      final binauralUri = SyntheticAudio.createBinauralWavUri();

      await Future.wait([
        _noisePlayer.setUrl(noiseUri),
        _padPlayer.setUrl(padUri),
        _binauralPlayer.setUrl(binauralUri),
      ]);

      await Future.wait([
        _noisePlayer.setLoopMode(LoopMode.one),
        _padPlayer.setLoopMode(LoopMode.one),
        _binauralPlayer.setLoopMode(LoopMode.one),
      ]);
    } catch (_) {}

    _initialized = true;
    _currentState = AudioEngineState.stopped;
    _stateController.add(_currentState);
  }

  @override
  Future<void> start(SoundscapeConfig config) async {
    await initialize();

    _currentConfig = config;
    _currentState = AudioEngineState.playing;
    _stateController.add(_currentState);

    await _applyVolumes();

    try {
      await Future.wait([
        _padPlayer.play(),
        _binauralPlayer.play(),
        _noisePlayer.play(),
      ]);
    } catch (_) {}

    _proceduralTickTimer?.cancel();
    _proceduralTickTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _emitProceduralAnalysis(),
    );
  }

  @override
  Future<void> updateConfig(SoundscapeConfig config) async {
    _currentConfig = config;
    if (_currentState == AudioEngineState.playing) {
      await _applyVolumes();
    }
  }

  Future<void> _applyVolumes() async {
    try {
      await _noisePlayer.setVolume((_currentConfig.noise * _currentConfig.intensity * 0.4).clamp(0.0, 1.0));
      await _padPlayer.setVolume((_currentConfig.pad * _currentConfig.intensity).clamp(0.0, 1.0));
      await _binauralPlayer.setVolume((_currentConfig.binaural * _currentConfig.intensity * 0.8).clamp(0.0, 1.0));
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    _proceduralTickTimer?.cancel();
    _proceduralTickTimer = null;

    try {
      await Future.wait([
        _noisePlayer.pause(),
        _padPlayer.pause(),
        _binauralPlayer.pause(),
      ]);
    } catch (_) {}

    _currentState = AudioEngineState.stopped;
    _stateController.add(_currentState);
  }

  void _emitProceduralAnalysis() {
    if (_currentState != AudioEngineState.playing) return;

    final baseAmp = _currentConfig.intensity * 0.5 + 0.2;
    final noiseJitter = (_random.nextDouble() - 0.5) * 0.1;
    final currentAmp = (baseAmp + noiseJitter).clamp(0.0, 1.0);

    final low = (_currentConfig.warmth * 0.8 + _random.nextDouble() * 0.2).clamp(0.0, 1.0);
    final mid = (_currentConfig.pad * 0.7 + _random.nextDouble() * 0.15).clamp(0.0, 1.0);
    final high = (_currentConfig.complexity * 0.6 + _random.nextDouble() * 0.2).clamp(0.0, 1.0);

    final isPianoEvent = _currentConfig.piano > 0.1 && _random.nextDouble() < (_currentConfig.piano * 0.08);

    if (isPianoEvent) {
      _triggerPianoNote();
    }

    _analysisController.add(AudioAnalysis(
      amplitude: currentAmp,
      lowEnergy: low,
      midEnergy: mid,
      highEnergy: high,
      sessionIntensity: _currentConfig.intensity,
      hasPianoEvent: isPianoEvent,
    ));
  }

  void _triggerPianoNote() async {
    try {
      final freqs = [261.63, 329.63, 392.00, 523.25, 659.25];
      final freq = freqs[_random.nextInt(freqs.length)];
      final noteUri = SyntheticAudio.createTranquilChimeWavUri(freqHz: freq);

      await _pianoPlayer.setVolume((_currentConfig.piano * _currentConfig.intensity).clamp(0.0, 1.0));
      await _pianoPlayer.setUrl(noteUri);
      await _pianoPlayer.play();
    } catch (_) {}
  }

  @override
  Stream<AudioAnalysis> get analysisStream => _analysisController.stream;

  @override
  Stream<AudioEngineState> get stateStream => _stateController.stream;

  void dispose() {
    _proceduralTickTimer?.cancel();
    _noisePlayer.dispose();
    _padPlayer.dispose();
    _binauralPlayer.dispose();
    _pianoPlayer.dispose();
    _analysisController.close();
    _stateController.close();
  }
}
