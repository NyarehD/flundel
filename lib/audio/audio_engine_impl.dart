import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';
// flutter_soloud 5.2.1 omits the generated per-bus visualization switch from
// its public API. This native adapter is isolated here and version-pinned.
import 'package:audio_session/audio_session.dart';
import 'package:flundel/audio/audio_analysis.dart';
import 'package:flundel/audio/audio_engine.dart';
import 'package:flundel/audio/audio_mix_policy.dart';
import 'package:flundel/audio/dsp/rhythm_loop_renderer.dart';
import 'package:flundel/audio/procedural/harmony_controller.dart';
import 'package:flundel/audio/procedural/piano_phrase_scheduler.dart';
import 'package:flundel/audio/rhythm_transport_clock.dart';
import 'package:flundel/audio/soloud_bus_meter_adapter.dart';
import 'package:flundel/domain/models/soundscape_config.dart';

/// Session soundscape playback backed by SoLoud's native mixer.
///
/// The source beds are bundled, distribution-safe original recordings/synths.
/// Each source is routed through a native mixer bus with a limiter and reverb.
class AudioEngineImpl implements AudioEngine {
  AudioEngineImpl({SoLoud? soloud}) : _soloud = soloud ?? SoLoud.instance;

  final SoLoud _soloud;
  final _analysisController = StreamController<AudioAnalysis>.broadcast();
  final _stateController = StreamController<AudioEngineState>.broadcast();
  final Map<String, AudioSource> _sources = {};
  final Map<String, SoundHandle> _handles = {};
  final Set<SoundHandle> _pianoHandles = {};
  final Set<SoundHandle> _cueHandles = {};
  final Set<SoundHandle> _padHandles = {};
  final Set<SoundHandle> _rhythmHandles = {};
  final Set<SoundHandle> _bassHandles = {};
  final Map<ChordType, AudioSource> _bassSources = {};
  final HarmonyController _harmony = HarmonyController();
  SoundHandle? _currentPadHandle;
  final List<StreamSubscription<StreamSoundEvent>> _voiceSubscriptions = [];
  final List<StreamSubscription<StreamSoundEvent>> _rhythmVoiceSubscriptions =
      [];
  final Map<String, bool> layerMuted = {
    'noise': false,
    'pad': false,
    'piano': false,
    'binaural': false,
    'nature': false,
    'beats': false,
    'bass': false,
  };
  final Map<String, bool> layerSolo = {
    'noise': false,
    'pad': false,
    'piano': false,
    'binaural': false,
    'nature': false,
    'beats': false,
    'bass': false,
  };

  AudioEngineState _state = AudioEngineState.stopped;
  SoundscapeConfig _config = const SoundscapeConfig();
  SoundscapeConfig _committedConfig = const SoundscapeConfig();
  Bus? _tonalBus;
  Bus? _textureBus;
  Bus? _rhythmBus;
  Bus? _bassBus;
  AudioSource? _drumSource;
  SoundHandle? _drumHandle;
  SoundHandle? _currentBassHandle;
  final RhythmTransportClock _rhythmClock = RhythmTransportClock();
  Duration _pausedRhythmPhase = Duration.zero;
  int? _rhythmBpm;
  int? _rhythmSeed;
  int _sessionSeed = 42;
  Future<void>? _rhythmLoading;
  AudioSource? _binauralLeft;
  AudioSource? _binauralRight;
  AudioSession? _audioSession;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSubscription;
  StreamSubscription<void>? _noisySubscription;
  StreamSubscription<Uint8List>? _captureSubscription;
  Completer<Uint8List>? _previewCompleter;
  BytesBuilder? _previewBuffer;
  int _previewRawBytesRequired = 0;
  Timer? _pianoTimer;
  final PianoPhraseScheduler _phraseScheduler = PianoPhraseScheduler();
  Timer? _harmonyTimer;
  Random _random = Random(42);
  int _generation = 0;
  int _resourceEpoch = 0;
  int _activePianoVoices = 0;
  bool _hasScheduledFirstPhrase = false;
  double _peak = 0;
  double _focusDepth = 0;
  double _masterVolume = 0.9;
  double _filterCutoffHz = 1400;
  double _reverbMix = 0.12;
  bool _initialized = false;
  bool _disposed = false;
  bool _resumeAfterInterruption = false;
  bool _handlingInterruption = false;
  Future<void> Function()? _onExternalPause;
  Future<void> Function()? _onExternalResume;
  Future<void>? _initialization;
  Future<void>? _updateQueue;
  int _updateRevision = 0;
  String? _lastError;

  static const _assetPaths = <String, String>{
    'noise': 'assets/audio/texture_noise.wav',
    'nature': 'assets/audio/nature/rain_loop.wav',
  };
  static const _chimePaths = <String>[
    'assets/audio/piano/note_1.wav',
    'assets/audio/piano/note_2.wav',
    'assets/audio/piano/note_3.wav',
    'assets/audio/piano/note_4.wav',
  ];
  static const _chimeFrequencies = <double>[523.25, 659.25, 783.99, 987.77];
  // Eighteen source voices plus four mixer buses at the worst case.
  static const _maxConcurrentSourceVoices = 18;
  static const _mixerBusVoices = 4;
  static const _nativeVoiceHeadroom = 3;
  static const _nativeMaxActiveVoiceCount =
      _maxConcurrentSourceVoices + _mixerBusVoices + _nativeVoiceHeadroom;

  @override
  Future<void> initialize() {
    if (_disposed) return Future.error(StateError('Audio engine is disposed'));
    if (_initialized) return Future.value();
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    _setState(AudioEngineState.starting);
    final resourceEpoch = _resourceEpoch;
    final loaded = <String, AudioSource>{};
    try {
      if (!_soloud.isInitialized) {
        await _soloud.init(
          sampleRate: 48000,
          bufferSize: 2048,
          lowLatency: false,
        );
      }
      _soloud.setMaxActiveVoiceCount(_nativeMaxActiveVoiceCount);
      _audioSession = await AudioSession.instance;
      await _audioSession!.configure(const AudioSessionConfiguration.music());
      _interruptionSubscription = _audioSession!.interruptionEventStream.listen(
        _handleInterruptionEvent,
      );
      _noisySubscription = _audioSession!.becomingNoisyEventStream.listen((_) {
        _resumeAfterInterruption = false;
        unawaited(_onExternalPause?.call() ?? pause());
      });
      for (final entry in _assetPaths.entries) {
        loaded[entry.key] = await _soloud.loadAsset(
          entry.value,
          mode: LoadMode.memory,
        );
        if (_disposed || resourceEpoch != _resourceEpoch) {
          for (final source in loaded.values) {
            await _soloud.disposeSource(source);
          }
          return;
        }
      }
      for (final chordType in ChordType.values) {
        loaded['chord_${chordType.name}'] = await _soloud.loadAsset(
          'assets/audio/pads/chords/${chordType.name}.wav',
          mode: LoadMode.memory,
        );
        if (_disposed || resourceEpoch != _resourceEpoch) {
          for (final source in loaded.values) {
            await _soloud.disposeSource(source);
          }
          return;
        }
      }
      for (var i = 0; i < _chimePaths.length; i++) {
        loaded['piano$i'] = await _soloud.loadAsset(
          _chimePaths[i],
          mode: LoadMode.memory,
        );
        if (_disposed || resourceEpoch != _resourceEpoch) {
          for (final source in loaded.values) {
            await _soloud.disposeSource(source);
          }
          return;
        }
      }
      loaded['completionCue'] = await _soloud.loadAsset(
        'assets/audio/completion/gentle_completion.wav',
        mode: LoadMode.memory,
      );
      _binauralLeft = await _soloud.loadWaveform(WaveForm.sin, false, 1, 0);
      _binauralRight = await _soloud.loadWaveform(WaveForm.sin, false, 1, 0);
      _soloud.setWaveformFreq(_binauralLeft!, 180);
      _soloud.setWaveformFreq(_binauralRight!, 190);
      loaded['binauralLeft'] = _binauralLeft!;
      loaded['binauralRight'] = _binauralRight!;
      if (_disposed || resourceEpoch != _resourceEpoch) {
        for (final source in loaded.values) {
          await _soloud.disposeSource(source);
        }
        return;
      }
      _sources.addAll(loaded);
      for (final source in loaded.values) {
        _voiceSubscriptions.add(
          source.soundEvents.listen((event) {
            if (event.event == SoundEventType.handleIsNoMoreValid) {
              _cueHandles.remove(event.handle);
              if (_pianoHandles.remove(event.handle)) {
                _activePianoVoices = _pianoHandles.length;
              }
            }
          }),
        );
      }
      final tonalBus = _soloud.createMixingBus(name: 'flundel-tonal');
      final textureBus = _soloud.createMixingBus(name: 'flundel-texture');
      final rhythmBus = _soloud.createMixingBus(name: 'flundel-rhythm');
      final bassBus = _soloud.createMixingBus(name: 'flundel-bass');
      enableBusMeter(tonalBus);
      enableBusMeter(textureBus);
      enableBusMeter(rhythmBus);
      enableBusMeter(bassBus);
      _tonalBus = tonalBus;
      _textureBus = textureBus;
      _rhythmBus = rhythmBus;
      _bassBus = bassBus;
      tonalBus.playOnEngine(volume: 0.82);
      textureBus.playOnEngine(volume: 0.82);
      rhythmBus.playOnEngine(volume: 0.82);
      bassBus.playOnEngine(volume: 0);
      for (final bus in [tonalBus, textureBus]) {
        bus.filters.freeverbFilter.activate();
        bus.filters.freeverbFilter.wet().value = _reverbMix;
      }
      textureBus.filters.biquadFilter.activate();
      textureBus.filters.biquadFilter.frequency().value = _filterCutoffHz;
      // A global filter is after both native buses, so it limits the complete
      // mix including reverb tails, piano transients and crossfades.
      _soloud.filters.limiterFilter.activate();
      _soloud.filters.limiterFilter.threshold.value = -6;
      _soloud.filters.limiterFilter.outputCeiling.value = -1;
      _soloud.filters.limiterFilter.attackTime.value = 2;
      _soloud.filters.limiterFilter.releaseTime.value = 120;
      _soloud.setGlobalVolume(_masterVolume);
      _soloud.setVisualizationEnabled(true);
      _initialized = true;
      _startCapture();
      _setState(AudioEngineState.stopped);
    } catch (error, stack) {
      _lastError = error.toString();
      await _interruptionSubscription?.cancel();
      await _noisySubscription?.cancel();
      _interruptionSubscription = null;
      _noisySubscription = null;
      for (final subscription in _voiceSubscriptions) {
        await subscription.cancel();
      }
      _voiceSubscriptions.clear();
      for (final source in loaded.values) {
        try {
          await _soloud.disposeSource(source);
        } catch (_) {}
      }
      _sources.clear();
      try {
        _tonalBus?.dispose();
        _textureBus?.dispose();
        _rhythmBus?.dispose();
        _bassBus?.dispose();
      } catch (_) {}
      _tonalBus = null;
      _textureBus = null;
      _rhythmBus = null;
      _bassBus = null;
      _initialized = false;
      _setState(AudioEngineState.stopped);
      Error.throwWithStackTrace(error, stack);
    } finally {
      _initialization = null;
    }
  }

  Future<void> _handleInterruptionEvent(AudioInterruptionEvent event) async {
    if (event.begin) {
      if (_state != AudioEngineState.playing) return;
      _resumeAfterInterruption = true;
      _handlingInterruption = true;
      try {
        await (_onExternalPause?.call() ?? pause());
      } finally {
        _handlingInterruption = false;
      }
    } else if (event.type == AudioInterruptionType.pause &&
        _resumeAfterInterruption) {
      _resumeAfterInterruption = false;
      await (_onExternalResume?.call() ?? resume());
    }
  }

  void _startCapture() {
    _captureSubscription?.cancel();
    final capture = _soloud.startMixerOutputStream(
      format: MixerOutputFormat.pcmF32le,
      sampleRate: 48000,
      channels: 2,
      bufferSizeBytes: 192000,
      chunkPCMFrames: 2048,
    );
    _captureSubscription = capture.listen(
      _onCapturedAudio,
      onError: (Object error) => _lastError = 'Mixer capture: $error',
    );
  }

  void _onCapturedAudio(Uint8List bytes) {
    if (_state != AudioEngineState.playing || bytes.length < 4) return;
    final data = ByteData.sublistView(bytes);
    var peak = 0.0;
    var count = 0;
    for (var offset = 0; offset + 4 <= bytes.length; offset += 4) {
      final sample = data.getFloat32(offset, Endian.little).abs();
      if (sample.isFinite) {
        peak = max(peak, sample);
        count++;
      }
    }
    if (count == 0) return;
    final previewBuffer = _previewBuffer;
    final previewCompleter = _previewCompleter;
    if (previewBuffer != null &&
        previewCompleter != null &&
        !previewCompleter.isCompleted) {
      final remaining = _previewRawBytesRequired - previewBuffer.length;
      previewBuffer.add(bytes.sublist(0, min(bytes.length, remaining)));
      if (previewBuffer.length >= _previewRawBytesRequired) {
        previewCompleter.complete(_floatPcmToWav(previewBuffer.toBytes()));
      }
    }
    _peak = peak.clamp(0.0, 1.0);
    final tonal = max(
      _tonalBus?.getChannelVolume(0) ?? 0,
      _tonalBus?.getChannelVolume(1) ?? 0,
    ).clamp(0.0, 1.0);
    final texture = max(
      _textureBus?.getChannelVolume(0) ?? 0,
      _textureBus?.getChannelVolume(1) ?? 0,
    ).clamp(0.0, 1.0);
    _analysisController.add(
      AudioAnalysis(
        amplitude: _peak,
        tonalEnergy: (tonal * 2 * _masterVolume).clamp(0.0, 1.0),
        textureEnergy: (texture * 2 * _masterVolume).clamp(0.0, 1.0),
        pianoActivity: (_activePianoVoices / 8).clamp(0.0, 1.0),
        focusDepth: _focusDepth,
      ),
    );
  }

  @override
  Future<Uint8List> captureOutputPreview(Duration duration) async {
    if (_state != AudioEngineState.playing) {
      throw StateError('Start a soundscape before capturing a preview');
    }
    if (_previewCompleter != null) {
      throw StateError('A preview capture is already active');
    }
    if (duration < const Duration(seconds: 1) ||
        duration > const Duration(seconds: 12)) {
      throw RangeError.range(duration.inSeconds, 1, 12, 'duration');
    }
    final completer = Completer<Uint8List>();
    _previewCompleter = completer;
    _previewBuffer = BytesBuilder(copy: false);
    _previewRawBytesRequired = (duration.inMicroseconds * 48000 ~/ 1000000) * 8;
    try {
      return await completer.future.timeout(
        duration + const Duration(seconds: 4),
      );
    } finally {
      if (identical(_previewCompleter, completer)) {
        _previewCompleter = null;
        _previewBuffer = null;
        _previewRawBytesRequired = 0;
      }
    }
  }

  Uint8List _floatPcmToWav(Uint8List raw) {
    final frames = raw.length ~/ 8;
    final output = Uint8List(44 + frames * 4);
    final header = ByteData.sublistView(output);
    output.setRange(0, 4, ascii.encode('RIFF'));
    header.setUint32(4, output.length - 8, Endian.little);
    output.setRange(8, 12, ascii.encode('WAVE'));
    output.setRange(12, 16, ascii.encode('fmt '));
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 2, Endian.little);
    header.setUint32(24, 48000, Endian.little);
    header.setUint32(28, 192000, Endian.little);
    header.setUint16(32, 4, Endian.little);
    header.setUint16(34, 16, Endian.little);
    output.setRange(36, 40, ascii.encode('data'));
    header.setUint32(40, frames * 4, Endian.little);
    final input = ByteData.sublistView(raw);
    for (var i = 0; i < raw.length ~/ 4; i++) {
      final value = input.getFloat32(i * 4, Endian.little);
      final sample = (value.isFinite ? value : 0).clamp(-1.0, 1.0);
      header.setInt16(44 + i * 2, (sample * 32767).round(), Endian.little);
    }
    return output;
  }

  @override
  Future<void> start(SoundscapeConfig config, {int sessionSeed = 42}) async {
    if (config.beatsBpm < 60 || config.beatsBpm > 100) {
      throw RangeError.range(config.beatsBpm, 60, 100, 'beatsBpm');
    }
    final generation = ++_generation;
    _cancelPianoEvents();
    _harmonyTimer?.cancel();
    _sessionSeed = sessionSeed;
    _pausedRhythmPhase = Duration.zero;
    await initialize();
    if (_disposed || generation != _generation) return;
    _config = config;
    _random = Random(sessionSeed);
    _harmony.reset();
    _activePianoVoices = 0;
    _hasScheduledFirstPhrase = false;
    _setState(AudioEngineState.starting);

    try {
      final active = await _audioSession?.setActive(true);
      if (active == false) throw StateError('Audio focus was denied');
      await _stopVoices(fade: false);
      if (_disposed || generation != _generation) return;
      final tonalBus = _tonalBus;
      final textureBus = _textureBus;
      if (tonalBus == null || textureBus == null || _rhythmBus == null) {
        throw StateError('SoLoud mixer buses were not created');
      }
      for (final key in _assetPaths.keys) {
        final source = _sources[key];
        if (source == null) throw StateError('Missing loaded source: $key');
        final handle = textureBus.play(source, volume: 0, looping: true);
        _handles[key] = handle;
      }
      final initialPad = _sources['chord_${_harmony.currentChord.type.name}'];
      if (initialPad == null) {
        throw StateError('Missing initial chord pad source');
      }
      _currentPadHandle = tonalBus.play(initialPad, volume: 0, looping: true);
      _padHandles.add(_currentPadHandle!);
      _handles['binauralLeft'] = tonalBus.play(
        _sources['binauralLeft']!,
        volume: 0,
        pan: -1,
        looping: true,
      );
      _handles['binauralRight'] = tonalBus.play(
        _sources['binauralRight']!,
        volume: 0,
        pan: 1,
        looping: true,
      );
      if (config.beats > 0 || config.bass > 0) {
        await _ensureRhythmSources(config.beatsBpm, sessionSeed);
        if (_disposed || generation != _generation) return;
        _startRhythmVoices(
          generation,
          startAt: _soloud.getEngineTime() + const Duration(milliseconds: 150),
          phase: Duration.zero,
          chord: _harmony.currentChord.type,
        );
      }
      await _applyVolumes();
      _applyDspParameters();
      if (_disposed || generation != _generation) {
        await _stopVoices(fade: false);
        return;
      }
      _setState(AudioEngineState.playing);
      _committedConfig = config;
      _schedulePiano(generation);
      _scheduleHarmony(generation);
    } catch (error) {
      _lastError = error.toString();
      await _stopVoices(fade: false);
      _setState(AudioEngineState.stopped);
      rethrow;
    }
  }

  @override
  Future<void> updateConfig(SoundscapeConfig config) async {
    if (_state != AudioEngineState.stopped &&
        config.beatsBpm != _config.beatsBpm) {
      throw StateError('Rhythm tempo is fixed for an active session');
    }
    _config = config;
    final revision = ++_updateRevision;
    final previous = _updateQueue;
    final update = () async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {
          // A failed prior slider update must not poison future updates.
        }
      }
      if (revision != _updateRevision || _disposed) return;
      try {
        if (_state == AudioEngineState.playing &&
            (config.beats > 0 || config.bass > 0) &&
            _drumHandle == null) {
          await _ensureRhythmSources(config.beatsBpm, _sessionSeed);
          if (revision != _updateRevision || _disposed) return;
          _startRhythmVoices(
            _generation,
            startAt:
                _soloud.getEngineTime() + const Duration(milliseconds: 150),
            phase: _pausedRhythmPhase,
            chord: _harmony.currentChord.type,
          );
        }
        await _applyVolumes();
        _applyDspParameters();
        _committedConfig = config;
      } catch (_) {
        if (revision == _updateRevision) _config = _committedConfig;
        rethrow;
      }
    }();
    _updateQueue = update;
    await update;
  }

  Future<void> _applyVolumes() async {
    if (_tonalBus == null || _textureBus == null || _disposed) return;
    if (_binauralRight != null) {
      final beatHz = AudioMixPolicy.binauralBeatHz(_config);
      _soloud.setWaveformFreq(_binauralRight!, 180 + beatHz);
    }
    final anySolo = layerSolo.values.any((value) => value);
    final intensity = _config.intensity.clamp(0.0, 1.0);
    final levels = <String, double>{
      'noise': AudioMixPolicy.noiseLevel(_config),
      'binauralLeft': _config.binaural * 0.12,
      'binauralRight': _config.binaural * 0.12,
      'nature': AudioMixPolicy.natureLevel(_config),
    };
    for (final entry in _handles.entries.toList()) {
      final key = entry.key;
      if (key == 'pad') continue;
      final layer = key.startsWith('binaural') ? 'binaural' : key;
      final muted = layerMuted[layer] ?? false;
      final soloAllowed = !anySolo || layerSolo[layer] == true;
      final target =
          (levels[key]! * intensity * (muted || !soloAllowed ? 0 : 1)).clamp(
            0.0,
            1.0,
          );
      _soloud.fadeVolume(
        entry.value,
        target,
        const Duration(milliseconds: 220),
      );
    }
    final pianoMuted =
        layerMuted['piano']! ||
        (anySolo && !layerSolo['piano']!) ||
        intensity <= 0;
    for (final handle in _pianoHandles) {
      _soloud.setVolume(
        handle,
        pianoMuted ? 0 : AudioMixPolicy.pianoLevel(_config).clamp(0.0, 0.8),
      );
    }
    final harmonyMuted =
        layerMuted['pad']! || (anySolo && !layerSolo['pad']!) || intensity <= 0;
    for (final handle in _padHandles) {
      final activePad = handle == _currentPadHandle;
      _soloud.fadeVolume(
        handle,
        harmonyMuted || !activePad
            ? 0
            : (AudioMixPolicy.padLevel(_config) * intensity).clamp(0.0, 0.75),
        const Duration(milliseconds: 450),
      );
    }
    final beatsMuted =
        layerMuted['beats']! ||
        (anySolo && !layerSolo['beats']!) ||
        intensity <= 0;
    final beatsTarget = beatsMuted
        ? 0.0
        : (_config.beats * AudioMixPolicy.beatsGain * intensity).clamp(
            0.0,
            0.8,
          );
    for (final handle in _rhythmHandles) {
      _soloud.fadeVolume(
        handle,
        beatsTarget,
        const Duration(milliseconds: 180),
      );
    }
    final bassMuted =
        layerMuted['bass']! ||
        (anySolo && !layerSolo['bass']!) ||
        intensity <= 0;
    final bassTarget = bassMuted
        ? 0.0
        : (_config.bass * AudioMixPolicy.bassGain * intensity).clamp(0.0, 0.8);
    final bassBusHandle = _bassBus?.soundHandle;
    if (bassBusHandle != null && bassBusHandle.id > 0) {
      _soloud.fadeVolume(
        bassBusHandle,
        bassTarget,
        const Duration(milliseconds: 180),
      );
    }
  }

  Future<void> _ensureRhythmSources(int bpm, int seed) async {
    final keyMatches =
        _rhythmBpm == bpm &&
        _rhythmSeed == seed &&
        _drumSource != null &&
        _bassSources.length == ChordType.values.length;
    if (keyMatches) return;
    final inFlight = _rhythmLoading;
    if (inFlight != null) {
      await inFlight;
      if (_rhythmBpm == bpm && _rhythmSeed == seed && _drumSource != null) {
        return;
      }
    }
    final load = _loadRhythmSources(bpm, seed);
    _rhythmLoading = load;
    try {
      await load;
    } finally {
      if (identical(_rhythmLoading, load)) _rhythmLoading = null;
    }
  }

  Future<void> _loadRhythmSources(int bpm, int seed) async {
    await _disposeRhythmSources();
    final bank = await Isolate.run(
      () => RhythmLoopRenderer.render(bpm: bpm, seed: seed, sampleRate: 48000),
    );
    if (_disposed) return;
    final loaded = <AudioSource>[];
    try {
      final drums = await _soloud.loadMem(
        'flundel-rhythm-$bpm-$seed-drums.wav',
        bank.drumsWav,
        mode: LoadMode.memory,
      );
      loaded.add(drums);
      final bass = <ChordType, AudioSource>{};
      for (final chord in ChordType.values) {
        final source = await _soloud.loadMem(
          'flundel-rhythm-$bpm-$seed-bass-${chord.name}.wav',
          bank.bassWavs[chord]!,
          mode: LoadMode.memory,
        );
        loaded.add(source);
        bass[chord] = source;
      }
      if (_disposed) {
        for (final source in loaded) {
          await _soloud.disposeSource(source);
        }
        return;
      }
      _drumSource = drums;
      _bassSources.addAll(bass);
      _rhythmClock.reset(bank.duration);
      _rhythmBpm = bpm;
      _rhythmSeed = seed;
      for (final source in loaded) {
        _rhythmVoiceSubscriptions.add(
          source.soundEvents.listen((event) {
            if (event.event != SoundEventType.handleIsNoMoreValid) return;
            _rhythmHandles.remove(event.handle);
            _bassHandles.remove(event.handle);
            if (_drumHandle == event.handle) _drumHandle = null;
            if (_currentBassHandle == event.handle) _currentBassHandle = null;
          }),
        );
      }
    } catch (_) {
      for (final source in loaded) {
        try {
          await _soloud.disposeSource(source);
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<void> _disposeRhythmSources() async {
    for (final subscription in _rhythmVoiceSubscriptions) {
      await subscription.cancel();
    }
    _rhythmVoiceSubscriptions.clear();
    final drumSource = _drumSource;
    final sources = <AudioSource>[];
    if (drumSource != null) sources.add(drumSource);
    sources.addAll(_bassSources.values);
    _drumSource = null;
    _bassSources.clear();
    _rhythmBpm = null;
    _rhythmSeed = null;
    _rhythmClock.reset(Duration.zero);
    for (final source in sources) {
      try {
        await _soloud.disposeSource(source);
      } catch (_) {}
    }
  }

  void _startRhythmVoices(
    int generation, {
    required Duration startAt,
    required Duration phase,
    required ChordType chord,
  }) {
    if (_state == AudioEngineState.paused ||
        _disposed ||
        generation != _generation ||
        _rhythmClock.loopDuration == Duration.zero) {
      return;
    }
    final drumBus = _rhythmBus;
    final bassBus = _bassBus;
    final drumSource = _drumSource;
    final bassSource = _bassSources[chord];
    if (drumBus == null ||
        bassBus == null ||
        drumSource == null ||
        bassSource == null) {
      return;
    }
    _rhythmClock.anchor(startAt, phase: phase);
    final normalizedPhase = _rhythmClock.phaseAt(startAt);
    final drum = drumBus.playScheduled(
      drumSource,
      startAt,
      looping: true,
      volume: 0,
    );
    _soloud.seek(drum, normalizedPhase);
    _soloud.setInaudibleBehavior(drum, true, false);
    _rhythmHandles.add(drum);
    _drumHandle = drum;
    final bass = bassBus.playScheduled(
      bassSource,
      startAt,
      looping: true,
      volume: 1,
    );
    _soloud.seek(bass, normalizedPhase);
    _soloud.setInaudibleBehavior(bass, true, false);
    _bassHandles.add(bass);
    _currentBassHandle = bass;
  }

  Duration _rhythmPhaseAt(Duration engineTime) =>
      _rhythmClock.phaseAt(engineTime);

  void _scheduleBassChord(ChordType chord, int generation) {
    if (_state != AudioEngineState.playing ||
        generation != _generation ||
        _bassHandles.isEmpty) {
      return;
    }
    final bus = _bassBus;
    final source = _bassSources[chord];
    if (bus == null || source == null) return;
    final atTime = _soloud.getEngineTime() + const Duration(milliseconds: 150);
    final phase = _rhythmPhaseAt(atTime);
    final incoming = bus.playScheduled(
      source,
      atTime,
      looping: true,
      volume: 0,
    );
    _soloud.seek(incoming, phase);
    _soloud.setInaudibleBehavior(incoming, true, false);
    final old = _currentBassHandle;
    _bassHandles.add(incoming);
    _currentBassHandle = incoming;
    _soloud.fadeScheduled(
      incoming,
      atTime,
      1,
      const Duration(milliseconds: 80),
    );
    if (old != null) {
      _soloud.fadeScheduled(
        old,
        atTime,
        0,
        const Duration(milliseconds: 80),
        thenStop: true,
      );
    }
  }

  Future<void> _stopRhythmVoices() async {
    final handles = {..._rhythmHandles, ..._bassHandles};
    _rhythmHandles.clear();
    _bassHandles.clear();
    _drumHandle = null;
    _currentBassHandle = null;
    for (final handle in handles) {
      try {
        await _soloud.stop(handle);
      } catch (_) {}
    }
  }

  void _applyDspParameters() {
    final textureBus = _textureBus;
    if (textureBus == null) return;
    final warm = _config.warmth.clamp(0.0, 1.0);
    _filterCutoffHz = 4200 - (warm * 3500);
    textureBus.filters.biquadFilter.frequency().value = _filterCutoffHz;
    _reverbMix = (0.04 + (_config.complexity.clamp(0.0, 1.0) * 0.20));
    _tonalBus?.filters.freeverbFilter.wet().value = _reverbMix;
    textureBus.filters.freeverbFilter.wet().value = _reverbMix * 0.65;
  }

  void _schedulePiano(int generation) {
    if (_state != AudioEngineState.playing || generation != _generation) return;
    final delay = AudioMixPolicy.nextPianoDelay(
      random: _random,
      firstNote: !_hasScheduledFirstPhrase,
      config: _config,
      focusDepth: _focusDepth,
    );
    _hasScheduledFirstPhrase = true;
    _pianoTimer = Timer(delay, () async {
      if (_state != AudioEngineState.playing || generation != _generation) {
        return;
      }
      final chord = _harmony.currentChord;
      final count = AudioMixPolicy.phraseNoteCount(_config);
      final phrase = AudioMixPolicy.createPhraseFrequencies(
        chord: chord,
        random: _random,
        noteCount: count,
      );
      _phraseScheduler.schedule(
        frequencies: phrase,
        spacing: AudioMixPolicy.phraseSpacing(_random, _config),
        onNote: (frequency, index) {
          if (_state != AudioEngineState.playing || generation != _generation) {
            return;
          }
          unawaited(
            _playPiano(
              generation,
              targetFrequency: frequency,
              velocity: AudioMixPolicy.pianoPhraseVelocity(
                index,
                phrase.length,
              ),
            ),
          );
        },
      );
      _schedulePiano(generation);
    });
  }

  void _scheduleHarmony(int generation) {
    if (_state != AudioEngineState.playing || generation != _generation) return;
    final complexity = _config.complexity.clamp(0.0, 1.0);
    final holdSeconds =
        (16 - complexity * 2 + _focusDepth * 4 + _random.nextDouble() * 4)
            .round();
    _harmonyTimer = Timer(Duration(seconds: holdSeconds), () async {
      if (_state != AudioEngineState.playing || generation != _generation) {
        return;
      }
      final chord = _harmony.transitionNextChord(_random);
      _scheduleBassChord(chord.type, generation);
      final source = _sources['chord_${chord.type.name}'];
      final bus = _tonalBus;
      if (source == null || bus == null) return;
      final oldHandle = _currentPadHandle;
      final incoming = bus.play(source, volume: 0, looping: true);
      _padHandles.add(incoming);
      _currentPadHandle = incoming;
      final anySolo = layerSolo.values.any((value) => value);
      final muted =
          layerMuted['pad']! ||
          (anySolo && !layerSolo['pad']!) ||
          _config.intensity <= 0;
      _soloud.fadeVolume(
        incoming,
        muted
            ? 0
            : (AudioMixPolicy.padLevel(_config) * _config.intensity).clamp(
                0.0,
                0.75,
              ),
        const Duration(seconds: 2),
      );
      if (oldHandle != null) {
        _soloud.fadeVolume(oldHandle, 0, const Duration(seconds: 2));
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 2050), () async {
            _padHandles.remove(oldHandle);
            try {
              await _soloud.stop(oldHandle);
            } catch (_) {}
          }),
        );
      }
      if (_state != AudioEngineState.playing || generation != _generation) {
        return;
      }
      _scheduleHarmony(generation);
    });
  }

  Future<void> _playPiano(
    int generation, {
    required double targetFrequency,
    required double velocity,
  }) async {
    final level = (_config.piano * _config.intensity).clamp(0.0, 1.0);
    final anySolo = layerSolo.values.any((value) => value);
    if (level <= 0 ||
        _masterVolume <= 0 ||
        layerMuted['piano']! ||
        (anySolo && !layerSolo['piano']!)) {
      return;
    }
    if (_pianoHandles.length >= AudioMixPolicy.maxPianoVoices) return;
    final bus = _tonalBus;
    if (bus == null || generation != _generation || _disposed) return;
    final index = List<int>.generate(_chimeFrequencies.length, (i) => i).reduce(
      (a, b) =>
          (targetFrequency - _chimeFrequencies[a]).abs() <=
              (targetFrequency - _chimeFrequencies[b]).abs()
          ? a
          : b,
    );
    final source = _sources['piano$index'];
    if (source == null) return;
    final voiceLevel = (AudioMixPolicy.pianoLevel(_config) * velocity).clamp(
      0.0,
      0.8,
    );
    try {
      final handle = bus.play(source, volume: voiceLevel, looping: false);
      _soloud.setRelativePlaySpeed(
        handle,
        targetFrequency / _chimeFrequencies[index],
      );
      _pianoHandles.add(handle);
      _activePianoVoices = _pianoHandles.length;
      _analysisController.add(
        AudioAnalysis(
          amplitude: _peak,
          tonalEnergy:
              max(
                _tonalBus?.getChannelVolume(0) ?? 0,
                _tonalBus?.getChannelVolume(1) ?? 0,
              ).clamp(0.0, 1.0) *
              _masterVolume,
          textureEnergy:
              max(
                _textureBus?.getChannelVolume(0) ?? 0,
                _textureBus?.getChannelVolume(1) ?? 0,
              ).clamp(0.0, 1.0) *
              _masterVolume,
          pianoActivity: (_activePianoVoices / 8).clamp(0.0, 1.0),
          focusDepth: _focusDepth,
          hasPianoEvent: true,
        ),
      );
    } catch (error) {
      _lastError = 'Piano playback: $error';
    }
  }

  @override
  Future<void> setFocusDepth(double value) async {
    _focusDepth = value.clamp(0.0, 1.0);
    // Binaural carriers must remain isolated to their intended ears at every
    // focus depth; depth changes note spacing and chord holds instead.
    if (!_analysisController.isClosed && _state == AudioEngineState.playing) {
      _analysisController.add(
        AudioAnalysis(
          amplitude: _peak,
          tonalEnergy: ((_tonalBus?.getChannelVolume(0) ?? 0) * _masterVolume)
              .clamp(0.0, 1.0),
          textureEnergy:
              (_textureBus?.getChannelVolume(0) ?? 0).clamp(0.0, 1.0) *
              _masterVolume,
          pianoActivity: (_activePianoVoices / 8).clamp(0.0, 1.0),
          focusDepth: _focusDepth,
        ),
      );
    }
  }

  @override
  Future<void> pause() async {
    if (_state != AudioEngineState.playing) return;
    if (!_handlingInterruption) _resumeAfterInterruption = false;
    _cancelPianoEvents();
    _harmonyTimer?.cancel();
    _pausedRhythmPhase = _rhythmPhaseAt(_soloud.getEngineTime());
    await _stopRhythmVoices();
    for (final handle in _handles.values.toList()) {
      _soloud.pauseSwitch(handle);
    }
    for (final handle in _padHandles.toList()) {
      _soloud.pauseSwitch(handle);
    }
    for (final handle in [..._pianoHandles, ..._cueHandles]) {
      _soloud.pauseSwitch(handle);
    }
    await _audioSession?.setActive(false);
    _setState(AudioEngineState.paused);
  }

  @override
  Future<void> resume() async {
    if (_state != AudioEngineState.paused) return;
    final generation = _generation;
    _resumeAfterInterruption = false;
    try {
      final active = await _audioSession?.setActive(true);
      if (active == false) {
        _lastError = 'Audio focus was denied while resuming';
        throw StateError(_lastError!);
      }
    } catch (error) {
      _lastError = 'Unable to restore audio focus: $error';
      rethrow;
    }
    if ((_config.beats > 0 || _config.bass > 0) && _drumSource == null) {
      await _ensureRhythmSources(_config.beatsBpm, _sessionSeed);
    }
    if (_disposed ||
        generation != _generation ||
        _state != AudioEngineState.paused) {
      return;
    }
    for (final handle in _handles.values.toList()) {
      _soloud.pauseSwitch(handle);
    }
    for (final handle in _padHandles.toList()) {
      _soloud.pauseSwitch(handle);
    }
    for (final handle in [..._pianoHandles, ..._cueHandles]) {
      _soloud.pauseSwitch(handle);
    }
    _setState(AudioEngineState.playing);
    if ((_config.beats > 0 || _config.bass > 0) && _drumSource != null) {
      _startRhythmVoices(
        _generation,
        startAt: _soloud.getEngineTime() + const Duration(milliseconds: 150),
        phase: _pausedRhythmPhase,
        chord: _harmony.currentChord.type,
      );
      await _applyVolumes();
    }
    _schedulePiano(_generation);
    _scheduleHarmony(_generation);
  }

  @override
  Future<void> stop() async {
    ++_generation;
    _cancelPianoEvents();
    _harmonyTimer?.cancel();
    await _stopVoices(fade: true);
    _pausedRhythmPhase = Duration.zero;
    _activePianoVoices = 0;
    _setState(AudioEngineState.stopped);
    await _audioSession?.setActive(false);
  }

  Future<void> _stopVoices({required bool fade}) async {
    final oldHandles = [
      ..._handles.values,
      ..._padHandles,
      ..._rhythmHandles,
      ..._bassHandles,
    ].toList();
    final oldPianoHandles = [..._pianoHandles, ..._cueHandles];
    _pianoHandles.clear();
    _cueHandles.clear();
    _handles.clear();
    _padHandles.clear();
    _rhythmHandles.clear();
    _bassHandles.clear();
    _currentPadHandle = null;
    _currentBassHandle = null;
    _drumHandle = null;
    if (fade) {
      for (final handle in [...oldHandles, ...oldPianoHandles]) {
        _soloud.fadeVolume(handle, 0, const Duration(milliseconds: 350));
      }
      await Future<void>.delayed(const Duration(milliseconds: 370));
    }
    for (final handle in [...oldHandles, ...oldPianoHandles]) {
      try {
        await _soloud.stop(handle);
      } catch (error) {
        _lastError = 'Stopping voice: $error';
      }
    }
  }

  void _cancelPianoEvents() {
    _pianoTimer?.cancel();
    _pianoTimer = null;
    _phraseScheduler.cancel();
  }

  @override
  Future<void> playCompletionCue() async {
    if (_state != AudioEngineState.playing || _disposed) return;
    _cancelPianoEvents();
    _harmonyTimer?.cancel();
    _harmonyTimer = null;
    if (_config.intensity <= 0 ||
        _masterVolume <= 0 ||
        layerMuted.values.every((v) => v)) {
      await _stopRhythmVoices();
      return;
    }
    final bus = _tonalBus;
    final source = _sources['completionCue'];
    if (bus == null || source == null) return;
    for (final handle in [
      ..._handles.values,
      ..._padHandles,
      ..._pianoHandles,
      ..._rhythmHandles,
      ..._bassHandles,
    ]) {
      _soloud.fadeVolume(handle, 0, const Duration(milliseconds: 500));
    }
    await Future<void>.delayed(const Duration(milliseconds: 520));
    await _stopRhythmVoices();
    final handle = bus.play(
      source,
      volume: 0.10 * _config.intensity,
      looping: false,
    );
    _cueHandles.add(handle);
    try {
      await source.allInstancesFinished.first.timeout(
        const Duration(seconds: 5),
      );
    } on TimeoutException {
      // A native playback stall should not hang focus-session completion.
    }
  }

  @override
  Map<String, dynamic> getDiagnostics() => {
    'state': _state.name,
    'backend': 'flutter_soloud',
    'sampleRateHz': 48000,
    'bufferSizeFrames': 2048,
    'peakAmplitude': _peak,
    'activePianoVoices': _activePianoVoices,
    'maxPianoVoices': AudioMixPolicy.maxPianoVoices,
    'activeVoiceHandles':
        _handles.length +
        _padHandles.length +
        _pianoHandles.length +
        _cueHandles.length +
        _rhythmHandles.length +
        _bassHandles.length +
        (_tonalBus?.isActive == true ? 1 : 0) +
        (_textureBus?.isActive == true ? 1 : 0) +
        (_rhythmBus?.isActive == true ? 1 : 0) +
        (_bassBus?.isActive == true ? 1 : 0),
    'maxConcurrentSourceVoices': _maxConcurrentSourceVoices,
    'maxMixerBusVoices': _mixerBusVoices,
    'expectedPeakActiveVoices': _maxConcurrentSourceVoices + _mixerBusVoices,
    'nativeConfiguredMaxActiveVoices': _soloud.isInitialized
        ? _soloud.getMaxActiveVoiceCount()
        : null,
    'focusDepth': _focusDepth,
    'masterVolume': _masterVolume,
    'underrunsCount': null,
    'outputPeakDbfs': _peak <= 0 ? -120.0 : 20 * log(_peak) / ln10,
    'lastError': _lastError,
    'layerMuted': Map<String, bool>.from(layerMuted),
    'layerSolo': Map<String, bool>.from(layerSolo),
    'mixerCaptureActive': _soloud.isMixerOutputStreamRunning,
    'rhythmBpm': _rhythmBpm,
    'rhythmPhaseSeconds': _rhythmClock.loopDuration == Duration.zero
        ? null
        : _rhythmPhaseAt(_soloud.getEngineTime()).inMicroseconds / 1000000,
    'activeRhythmVoices': _rhythmHandles.length + _bassHandles.length,
    'rhythmEnergy': max(
      _rhythmBus?.getChannelVolume(0) ?? 0,
      _rhythmBus?.getChannelVolume(1) ?? 0,
    ).clamp(0.0, 1.0),
    'bassEnergy': max(
      _bassBus?.getChannelVolume(0) ?? 0,
      _bassBus?.getChannelVolume(1) ?? 0,
    ).clamp(0.0, 1.0),
  };

  @override
  Stream<AudioAnalysis> get analysisStream => _analysisController.stream;

  @override
  Stream<AudioEngineState> get stateStream => _stateController.stream;

  @override
  void setLayerMuted(String layer, bool muted) {
    if (!layerMuted.containsKey(layer)) return;
    layerMuted[layer] = muted;
    unawaited(_applyVolumes());
  }

  @override
  void setLayerSolo(String layer, bool solo) {
    if (!layerSolo.containsKey(layer)) return;
    layerSolo[layer] = solo;
    unawaited(_applyVolumes());
  }

  @override
  void setMasterVolume(double value) {
    _masterVolume = value.clamp(0.0, 1.0);
    _soloud.setGlobalVolume(_masterVolume);
  }

  @override
  void setFilterCutoff(double value) {
    _filterCutoffHz = value.clamp(200.0, 8000.0);
    _textureBus?.filters.biquadFilter.frequency().value = _filterCutoffHz;
  }

  @override
  void setReverbMix(double value) {
    _reverbMix = value.clamp(0.0, 1.0);
    _tonalBus?.filters.freeverbFilter.wet().value = _reverbMix;
    _textureBus?.filters.freeverbFilter.wet().value = _reverbMix * 0.65;
  }

  @override
  void setExternalPlaybackHandlers({
    required Future<void> Function() onPause,
    required Future<void> Function() onResume,
  }) {
    _onExternalPause = onPause;
    _onExternalResume = onResume;
  }

  void _setState(AudioEngineState value) {
    if (_state == value) return;
    _state = value;
    if (!_stateController.isClosed) _stateController.add(value);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    ++_generation;
    ++_resourceEpoch;
    _cancelPianoEvents();
    _harmonyTimer?.cancel();
    final initialization = _initialization;
    if (initialization != null) {
      try {
        await initialization;
      } catch (_) {}
    }
    if (!(_previewCompleter?.isCompleted ?? true)) {
      _previewCompleter!.completeError(StateError('Audio engine disposed'));
    }
    await _stopVoices(fade: false);
    await _captureSubscription?.cancel();
    await _interruptionSubscription?.cancel();
    await _noisySubscription?.cancel();
    if (_soloud.isMixerOutputStreamRunning) _soloud.stopMixerOutputStream();
    for (final source in _sources.values.toList()) {
      try {
        await _soloud.disposeSource(source);
      } catch (_) {}
    }
    _sources.clear();
    await _disposeRhythmSources();
    try {
      _tonalBus?.dispose();
      _textureBus?.dispose();
      _rhythmBus?.dispose();
      _bassBus?.dispose();
    } catch (_) {}
    _tonalBus = null;
    _textureBus = null;
    _rhythmBus = null;
    _bassBus = null;
    if (_soloud.isInitialized) await _soloud.deinitAsync();
    _initialized = false;
    await _analysisController.close();
    await _stateController.close();
  }
}
