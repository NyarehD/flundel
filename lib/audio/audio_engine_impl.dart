import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flundel/audio/audio_analysis.dart';
import 'package:flundel/audio/audio_engine.dart';
import 'package:flundel/audio/dsp/audio_bus.dart';
import 'package:flundel/audio/dsp/binaural_generator.dart';
import 'package:flundel/audio/dsp/environmental_layer.dart';
import 'package:flundel/audio/dsp/noise_engine.dart';
import 'package:flundel/audio/dsp/pad_synth.dart';
import 'package:flundel/audio/procedural/piano_scheduler.dart';
import 'package:flundel/audio/procedural/procedural_controller.dart';
import 'package:flundel/audio/synthetic_audio.dart';

class AudioEngineImpl implements AudioEngine {
  final _analysisController = StreamController<AudioAnalysis>.broadcast();
  final _stateController = StreamController<AudioEngineState>.broadcast();

  AudioEngineState _currentState = AudioEngineState.stopped;
  SoundscapeConfig _currentConfig = const SoundscapeConfig();

  Timer? _controlRateTimer;
  double _elapsedTimeSeconds = 0.0;

  final ProceduralController proceduralController = ProceduralController();
  final NoiseEngine noiseEngine = NoiseEngine();
  final PadSynth padSynth = PadSynth();
  final BinauralGenerator binauralGenerator = BinauralGenerator();
  final EnvironmentalLayer environmentalLayer = EnvironmentalLayer();
  final AudioBus audioBus = AudioBus();

  late final AudioPlayer _noisePlayer;
  late final AudioPlayer _padPlayer;
  late final AudioPlayer _binauralPlayer;
  late final AudioPlayer _envPlayer;

  // Piano voice pool for polyphony management (up to 8 voices)
  final List<AudioPlayer> _pianoVoicePool = [];
  int _nextPianoVoiceIndex = 0;

  bool _initialized = false;
  int _underrunsCount = 0;
  double _lastPeakAmplitude = 0.0;

  // Layer Solo/Mute states for Debug Screen
  final Map<String, bool> layerMuted = {
    'noise': false,
    'pad': false,
    'piano': false,
    'binaural': false,
    'nature': false,
  };

  final Map<String, bool> layerSolo = {
    'noise': false,
    'pad': false,
    'piano': false,
    'binaural': false,
    'nature': false,
  };

  bool get _anySoloActive => layerSolo.values.any((s) => s);

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    _noisePlayer = AudioPlayer();
    _padPlayer = AudioPlayer();
    _binauralPlayer = AudioPlayer();
    _envPlayer = AudioPlayer();

    for (int i = 0; i < 8; i++) {
      _pianoVoicePool.add(AudioPlayer());
    }

    try {
      final noiseUri = noiseEngine.generateWavUri();
      final padUri = padSynth.generatePadWavUri(
        baseFrequencies: proceduralController.harmonyController.currentChord.chordFrequencies,
      );
      final binauralUri = binauralGenerator.generateBinauralWavUri();
      final envUri = environmentalLayer.generateRainWavUri();

      await Future.wait([
        _noisePlayer.setUrl(noiseUri),
        _padPlayer.setUrl(padUri),
        _binauralPlayer.setUrl(binauralUri),
        _envPlayer.setUrl(envUri),
      ]);

      await Future.wait([
        _noisePlayer.setLoopMode(LoopMode.one),
        _padPlayer.setLoopMode(LoopMode.one),
        _binauralPlayer.setLoopMode(LoopMode.one),
        _envPlayer.setLoopMode(LoopMode.one),
      ]);
    } catch (e) {
      debugPrint('AudioEngineImpl initialize error: $e');
      _underrunsCount++;
    }

    _initialized = true;
    _currentState = AudioEngineState.stopped;
    _stateController.add(_currentState);
  }

  @override
  Future<void> start(
    SoundscapeConfig config, {
    int sessionSeed = 42,
  }) async {
    await initialize();

    _currentConfig = config;
    _elapsedTimeSeconds = 0.0;
    proceduralController.initialize(sessionSeed, config);

    noiseEngine.volume.setImmediate(config.noise * config.intensity);
    padSynth.volume.setImmediate(config.pad * config.intensity);
    binauralGenerator.volume.setImmediate(config.binaural * config.intensity);
    environmentalLayer.volume.setImmediate(config.nature * config.intensity);

    _currentState = AudioEngineState.playing;
    _stateController.add(_currentState);

    await _applyVolumes();

    try {
      await Future.wait([
        _noisePlayer.play(),
        _padPlayer.play(),
        _binauralPlayer.play(),
        _envPlayer.play(),
      ]);
    } catch (e) {
      debugPrint('AudioEngineImpl play error: $e');
      _underrunsCount++;
    }

    _controlRateTimer?.cancel();
    _controlRateTimer = Timer.periodic(
      const Duration(milliseconds: 50), // 20 Hz control tick
      (_) => _onControlRateTick(0.05),
    );
  }

  @override
  Future<void> updateConfig(SoundscapeConfig config) async {
    _currentConfig = config;
    if (_currentState == AudioEngineState.playing) {
      await _applyVolumes();
    }
  }

  @override
  Future<void> setFocusDepth(double value) async {
    proceduralController.setFocusDepth(value);
  }

  @override
  Future<void> stop() async {
    _controlRateTimer?.cancel();
    _controlRateTimer = null;

    try {
      await Future.wait([
        _noisePlayer.pause(),
        _padPlayer.pause(),
        _binauralPlayer.pause(),
        _envPlayer.pause(),
        ..._pianoVoicePool.map((p) => p.pause()),
      ]);
    } catch (_) {}

    _currentState = AudioEngineState.stopped;
    _stateController.add(_currentState);
  }

  void _onControlRateTick(double deltaTimeSeconds) {
    if (_currentState != AudioEngineState.playing) return;

    _elapsedTimeSeconds += deltaTimeSeconds;

    // 1. Tick procedural controller (macro/micro variations & chord transitions)
    proceduralController.tick(deltaTimeSeconds, _currentConfig);

    // 2. Update smoothed DSP parameters
    noiseEngine.updateParameters(
      noiseLevel: _currentConfig.noise * _currentConfig.intensity,
      warmthValue: _currentConfig.warmth,
      cutoffFrequencyHz: proceduralController.noiseCutoffHz,
    );

    padSynth.updateParameters(
      padLevel: _currentConfig.pad * _currentConfig.intensity,
      detune: proceduralController.padDetuneCents,
      reverbSendLevel: audioBus.reverbBusSend.value,
    );

    binauralGenerator.updateParameters(
      level: _currentConfig.binaural * _currentConfig.intensity,
      carrierFrequency: 180.0,
      differenceHz: 10.0,
    );

    environmentalLayer.updateParameters(
      natureLevel: _currentConfig.nature * _currentConfig.intensity,
    );

    _applyVolumes();

    // 3. Check for procedural piano note event
    final pianoEvent = proceduralController.checkAndGeneratePianoEvent(
      currentTimeSeconds: _elapsedTimeSeconds,
      config: _currentConfig,
    );

    bool triggeredPiano = false;
    if (pianoEvent != null) {
      _triggerPianoVoice(pianoEvent.frequencyHz, pianoEvent.velocity);
      triggeredPiano = true;
    }

    // 4. Calculate signal energy and emit analysis
    final tonalEnergy = (padSynth.volume.value * 0.7 + _currentConfig.piano * 0.3).clamp(0.0, 1.0);
    final textureEnergy = (noiseEngine.volume.value * 0.6 + environmentalLayer.volume.value * 0.4).clamp(0.0, 1.0);

    final rawPeak = (tonalEnergy * 0.5 + textureEnergy * 0.4 + binauralGenerator.volume.value * 0.2);
    _lastPeakAmplitude = audioBus.applyMasterLimiter(rawPeak);

    _analysisController.add(AudioAnalysis(
      amplitude: _lastPeakAmplitude,
      tonalEnergy: tonalEnergy,
      textureEnergy: textureEnergy,
      pianoActivity: proceduralController.pianoScheduler.activeVoiceCount / 8.0,
      focusDepth: proceduralController.focusDepth.value,
      hasPianoEvent: triggeredPiano,
    ));
  }

  Future<void> _applyVolumes() async {
    final anySolo = _anySoloActive;

    final noiseVol = audioBus.calculateEffectiveGain(
      baseLevel: noiseEngine.volume.value * 0.4,
      isMuted: layerMuted['noise']!,
      isSolo: layerSolo['noise']!,
      anyLayerSolo: anySolo,
      busGain: audioBus.textureBusGain.value,
    );

    final padVol = audioBus.calculateEffectiveGain(
      baseLevel: padSynth.volume.value,
      isMuted: layerMuted['pad']!,
      isSolo: layerSolo['pad']!,
      anyLayerSolo: anySolo,
      busGain: audioBus.tonalBusGain.value,
    );

    final binauralVol = audioBus.calculateEffectiveGain(
      baseLevel: binauralGenerator.volume.value * 0.6,
      isMuted: layerMuted['binaural']!,
      isSolo: layerSolo['binaural']!,
      anyLayerSolo: anySolo,
      busGain: audioBus.tonalBusGain.value,
    );

    final envVol = audioBus.calculateEffectiveGain(
      baseLevel: environmentalLayer.volume.value * 0.5,
      isMuted: layerMuted['nature']!,
      isSolo: layerSolo['nature']!,
      anyLayerSolo: anySolo,
      busGain: audioBus.textureBusGain.value,
    );

    try {
      await _noisePlayer.setVolume(noiseVol);
      await _padPlayer.setVolume(padVol);
      await _binauralPlayer.setVolume(binauralVol);
      await _envPlayer.setVolume(envVol);
    } catch (_) {
      _underrunsCount++;
    }
  }

  void _triggerPianoVoice(double freqHz, double velocity) async {
    final anySolo = _anySoloActive;
    if (layerMuted['piano']! || (anySolo && !layerSolo['piano']!)) return;

    final voiceIndex = _nextPianoVoiceIndex;
    _nextPianoVoiceIndex = (_nextPianoVoiceIndex + 1) % _pianoVoicePool.length;
    final player = _pianoVoicePool[voiceIndex];

    proceduralController.pianoScheduler.onVoiceStarted();

    try {
      final noteUri = SyntheticAudio.createTranquilChimeWavUri(freqHz: freqHz);
      final effectiveVol = audioBus.calculateEffectiveGain(
        baseLevel: velocity * _currentConfig.piano,
        isMuted: false,
        isSolo: false,
        anyLayerSolo: false,
        busGain: audioBus.tonalBusGain.value,
      );

      await player.setVolume(effectiveVol);
      await player.setUrl(noteUri);
      await player.play();
    } catch (_) {
      _underrunsCount++;
    } finally {
      Future.delayed(const Duration(milliseconds: 2500), () {
        proceduralController.pianoScheduler.onVoiceFinished();
      });
    }
  }

  @override
  Map<String, dynamic> getDiagnostics() {
    return {
      'state': _currentState.name,
      'activePianoVoices': proceduralController.pianoScheduler.activeVoiceCount,
      'maxPolyphony': PianoScheduler.maxPolyphony,
      'sampleRateHz': 44100,
      'bufferSizeFrames': 256,
      'underrunsCount': _underrunsCount,
      'focusDepth': proceduralController.focusDepth.value,
      'currentChord': proceduralController.harmonyController.currentChord.name,
      'peakAmplitudeDbfs': _lastPeakAmplitude,
      'noiseVolume': noiseEngine.volume.value,
      'padVolume': padSynth.volume.value,
      'binauralVolume': binauralGenerator.volume.value,
      'natureVolume': environmentalLayer.volume.value,
      'layerMuted': Map<String, bool>.from(layerMuted),
      'layerSolo': Map<String, bool>.from(layerSolo),
    };
  }

  @override
  Stream<AudioAnalysis> get analysisStream => _analysisController.stream;

  @override
  Stream<AudioEngineState> get stateStream => _stateController.stream;

  void dispose() {
    _controlRateTimer?.cancel();
    _noisePlayer.dispose();
    _padPlayer.dispose();
    _binauralPlayer.dispose();
    _envPlayer.dispose();
    for (final p in _pianoVoicePool) {
      p.dispose();
    }
    _analysisController.close();
    _stateController.close();
  }
}
