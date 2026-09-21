import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
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
  final SoLoud _soloud = SoLoud.instance;

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

  AudioSource? _noiseSource;
  AudioSource? _padSource;
  AudioSource? _binauralSource;
  AudioSource? _envSource;

  SoundHandle? _noiseHandle;
  SoundHandle? _padHandle;
  SoundHandle? _binauralHandle;
  SoundHandle? _envHandle;

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

    try {
      if (!_soloud.isInitialized) {
        await _soloud.init(
          bufferSize: 2048,  // Prevents hardware buffer starvation on Android
          sampleRate: 48000, // Matches native Android Audio HAL clock rate
        );
      }

      final noiseBytes = noiseEngine.generateWavBytes(sampleRate: 48000);
      final padBytes = padSynth.generatePadWavBytes(
        baseFrequencies: proceduralController.harmonyController.currentChord.chordFrequencies,
        sampleRate: 48000,
      );
      final binauralBytes = binauralGenerator.generateBinauralWavBytes(sampleRate: 48000);
      final envBytes = environmentalLayer.generateRainWavBytes(sampleRate: 48000);

      _noiseSource = await _soloud.loadMem('noise_bed.wav', noiseBytes);
      _padSource = await _soloud.loadMem('pad_bed.wav', padBytes);
      _binauralSource = await _soloud.loadMem('binaural_bed.wav', binauralBytes);
      _envSource = await _soloud.loadMem('env_bed.wav', envBytes);
    } catch (e) {
      debugPrint('AudioEngineImpl initialize fallback/error: $e');
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

    try {
      if (_noiseSource != null) {
        _noiseHandle = await _soloud.play(_noiseSource!, volume: 0.001, looping: true);
      }
      if (_padSource != null) {
        _padHandle = await _soloud.play(_padSource!, volume: 0.001, looping: true);
      }
      if (_binauralSource != null) {
        _binauralHandle = await _soloud.play(_binauralSource!, volume: 0.001, looping: true);
      }
      if (_envSource != null) {
        _envHandle = await _soloud.play(_envSource!, volume: 0.001, looping: true);
      }

      await _applyVolumes();
    } catch (_) {
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
      final handles = [_noiseHandle, _padHandle, _binauralHandle, _envHandle].whereType<SoundHandle>().toList();
      for (final handle in handles) {
        _soloud.fadeVolume(handle, 0.0, const Duration(milliseconds: 400));
      }

      Future.delayed(const Duration(milliseconds: 450), () {
        for (final handle in handles) {
          try {
            _soloud.stop(handle);
          } catch (_) {}
        }
      });

      _noiseHandle = null;
      _padHandle = null;
      _binauralHandle = null;
      _envHandle = null;
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
      if (_noiseHandle != null) {
        _soloud.fadeVolume(_noiseHandle!, noiseVol, const Duration(milliseconds: 100));
      }
      if (_padHandle != null) {
        _soloud.fadeVolume(_padHandle!, padVol, const Duration(milliseconds: 100));
      }
      if (_binauralHandle != null) {
        _soloud.fadeVolume(_binauralHandle!, binauralVol, const Duration(milliseconds: 100));
      }
      if (_envHandle != null) {
        _soloud.fadeVolume(_envHandle!, envVol, const Duration(milliseconds: 100));
      }
    } catch (_) {
      _underrunsCount++;
    }
  }

  void _triggerPianoVoice(double freqHz, double velocity) async {
    final anySolo = _anySoloActive;
    if (layerMuted['piano']! || (anySolo && !layerSolo['piano']!)) return;

    proceduralController.pianoScheduler.onVoiceStarted();

    try {
      final noteBytes = SyntheticAudio.createTranquilChimeWavBytes(freqHz: freqHz, sampleRate: 48000);
      final chimeSource = await _soloud.loadMem('chime_${freqHz.toInt()}.wav', noteBytes);

      final effectiveVol = audioBus.calculateEffectiveGain(
        baseLevel: velocity * _currentConfig.piano,
        isMuted: false,
        isSolo: false,
        anyLayerSolo: false,
        busGain: audioBus.tonalBusGain.value,
      );

      await _soloud.play(chimeSource, volume: effectiveVol, looping: false);
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
      'sampleRateHz': 48000,
      'bufferSizeFrames': 2048,
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
    stop();
    _analysisController.close();
    _stateController.close();
  }
}
