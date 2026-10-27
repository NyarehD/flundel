import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:flundel/audio/audio_analysis.dart';
import 'package:flundel/audio/audio_engine.dart';
import 'package:flundel/audio/audio_session_context.dart';
import 'package:flundel/audio/generative/composition_planner.dart';
import 'package:flundel/audio/generative/render_worker.dart';
import 'package:flundel/audio/generative/soundscape_renderer.dart';
import 'package:flundel/audio/playback/native_stream_mixer.dart';
import 'package:flundel/audio/playback/playback_lifecycle.dart';
import 'package:flundel/audio/synthetic_audio.dart';
import 'package:flundel/audio/tools/pcm_wav.dart';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flundel/session/session_phase.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Application facade over composition, DSP worker, native streams, and a
/// serialized lifecycle. All playback time comes from consumed native PCM.
class AudioEngineImpl implements AudioEngine {
  AudioEngineImpl({SoLoud? soloud, this.beforeRender})
    : _soloud = soloud ?? SoLoud.instance {
    _mixer = NativeStreamMixer(_soloud);
  }
  final SoLoud _soloud;
  // Dependency injection for exercising slow producers in the native probe.
  final Future<void> Function()? beforeRender;
  late final NativeStreamMixer _mixer;
  final RenderWorker _worker = RenderWorker();
  final PlaybackLifecycle _lifecycle = PlaybackLifecycle();
  final _analysisController = StreamController<AudioAnalysis>.broadcast();
  final _stateController = StreamController<AudioEngineState>.broadcast();
  final Map<String, bool> layerMuted = {
    for (final key in [
      'noise',
      'pad',
      'piano',
      'binaural',
      'nature',
      'beats',
      'bass',
    ])
      key: false,
  };
  final Map<String, bool> layerSolo = {
    for (final key in [
      'noise',
      'pad',
      'piano',
      'binaural',
      'nature',
      'beats',
      'bass',
    ])
      key: false,
  };
  AudioEngineState _state = AudioEngineState.stopped;
  SoundscapeConfig _config = const SoundscapeConfig();
  AudioSessionContext _context = const AudioSessionContext();
  AudioSession? _session;
  StreamSubscription<AudioInterruptionEvent>? _interruption;
  StreamSubscription<void>? _noisy;
  StreamSubscription<Uint8List>? _capture;
  Timer? _pumpTimer;
  Future<void>? _filling;
  bool _initialized = false;
  bool _buffering = false;
  bool _recovering = false;
  bool _completion = false;
  bool _interrupted = false;
  bool _handlingInterruption = false;
  Future<void> Function()? _onPause;
  Future<void> Function()? _onResume;
  int _seed = 42;
  int _revision = 0;
  int _position = 0;
  int _lastAnalysisFrame = 0;
  int _underruns = 0;
  double _master = .9;
  double _peak = 0;
  double _renderLoad = 0;
  int _renderedBlocks = 0;
  int _worstRenderMicros = 0;
  int _overBudgetBlocks = 0;
  double _startupMs = 0;
  String? _lastError;
  final List<MusicalEvent> _events = [];
  final List<({int frame, List<double> energy})> _meters = [];
  Completer<Uint8List>? _preview;
  PcmWavCapture? _previewPcm;
  AudioSource? _cue;

  @override
  Future<void> initialize() => _lifecycle.run(_initialize);
  Future<void> _initialize() async {
    if (_initialized) return;
    try {
      if (!_soloud.isInitialized) {
        await _soloud.init(sampleRate: 48000, lowLatency: false);
      }
      _soloud.setMaxActiveVoiceCount(20);
      _soloud.filters.limiterFilter.activate();
      _soloud.filters.limiterFilter.threshold.value = -6;
      _soloud.filters.limiterFilter.outputCeiling.value = -1;
      _soloud.filters.limiterFilter.attackTime.value = 2;
      _soloud.filters.limiterFilter.releaseTime.value = 120;
      _soloud.setGlobalVolume(_master);
      await _worker.open();
      _session = await AudioSession.instance;
      await _session!.configure(const AudioSessionConfiguration.music());
      _interruption = _session!.interruptionEventStream.listen((event) async {
        try {
          if (event.begin && _state == AudioEngineState.playing) {
            _interrupted = true;
            _handlingInterruption = true;
            try {
              await (_onPause?.call() ?? pause());
            } finally {
              _handlingInterruption = false;
            }
          } else if (!event.begin &&
              event.type == AudioInterruptionType.pause &&
              _interrupted) {
            _interrupted = false;
            await (_onResume?.call() ?? resume());
          }
        } on Object catch (e) {
          _lastError = 'Audio interruption: $e';
        }
      });
      _noisy = _session!.becomingNoisyEventStream.listen((_) {
        _interrupted = false;
        unawaited(
          (_onPause?.call() ?? pause()).catchError((Object e) {
            _lastError = '$e';
          }),
        );
      });
      _capture = _soloud
          .startMixerOutputStream(
            sampleRate: 48000,
            channels: 2,
            bufferSizeBytes: 192000,
            // Drain all available PCM. Fixed chunks in SoLoud 5.2.1 can stall
            // its notification latch when Android supplies multiple chunks in
            // one device callback; the threshold path acknowledges the full batch.
            notificationThresholdBytes: 16384,
          )
          .listen(
            _captured,
            onError: (Object e) {
              _lastError = 'Capture: $e';
            },
          );
      _initialized = true;
    } on Object catch (e) {
      _lastError = '$e';
      await _cleanup();
      rethrow;
    }
  }

  void _validate(SoundscapeConfig config) {
    if (config.beatsBpm < 60 || config.beatsBpm > 100) {
      throw ArgumentError('Tempo must be 60..100');
    }
    for (final e in config.toJson().entries) {
      if (e.value is double &&
          (!(e.value as double).isFinite ||
              (e.value as double) < 0 ||
              (e.value as double) > 1)) {
        throw ArgumentError('Invalid ${e.key}');
      }
    }
  }

  @override
  Future<void> start(
    SoundscapeConfig config, {
    int sessionSeed = 42,
    AudioSessionContext? context,
    Map<String, dynamic>? checkpoint,
    bool startPaused = false,
  }) {
    _validate(config);
    final epoch = _lifecycle.invalidate();
    return _lifecycle.run(() async {
      final watch = Stopwatch()..start();
      await _initialize();
      await _stop(fade: false);
      if (epoch != _lifecycle.epoch) return;
      _config = config;
      _context = context ?? const AudioSessionContext(presetId: 'custom');
      _seed = sessionSeed;
      _completion = false;
      _revision = 0;
      _lastError = null;
      _underruns = 0;
      _setState(AudioEngineState.starting);
      try {
        if (!startPaused && await _session?.setActive(true) == false) {
          throw StateError('Audio focus denied');
        }
        await _worker.reset(
          config: config,
          context: _context,
          seed: sessionSeed,
          checkpoint: checkpoint,
        );
        final frame =
            checkpoint?['frame'] as int? ??
            _context.elapsed.inMicroseconds * 48000 ~/ 1000000;
        _position = frame;
        _lastAnalysisFrame = frame;
        await _mixer.open(frame);
        await _fill(epoch);
        if (epoch != _lifecycle.epoch) return;
        if (startPaused) {
          _setState(AudioEngineState.paused);
        } else {
          _mixer.start(_config, layerMuted, layerSolo);
          _setState(AudioEngineState.playing);
          _startPump();
        }
        _startupMs = watch.elapsedMicroseconds / 1000;
      } on Object catch (e) {
        _lastError = '$e';
        await _stop(fade: false);
        rethrow;
      }
    });
  }

  Future<void> _fill(int epoch) {
    if (_filling != null) return _filling!;
    final work = () async {
      while (epoch == _lifecycle.epoch && _mixer.queuedFrames < 48000) {
        await beforeRender?.call();
        if (epoch != _lifecycle.epoch) return;
        final block = await _worker.render();
        if (epoch != _lifecycle.epoch) return;
        _renderedBlocks++;
        _worstRenderMicros = max(_worstRenderMicros, block.renderMicros);
        if (block.renderMicros > block.frames * 1000000 / 48000 / 2) {
          _overBudgetBlocks++;
        }
        _renderLoad = max(
          _renderLoad * .98,
          block.renderMicros / (block.frames * 1000000 / 48000),
        );
        _mixer.append(block);
        _events.addAll(block.events);
        _meters.add((
          frame: block.startFrame,
          energy: block.stems
              .map(
                (s) => sqrt(s.fold<double>(0, (a, b) => a + b * b) / s.length),
              )
              .toList(),
        ));
      }
    }();
    _filling = work;
    return work.whenComplete(() {
      if (identical(_filling, work)) _filling = null;
    });
  }

  void _startPump() {
    _pumpTimer?.cancel();
    _pumpTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (_state != AudioEngineState.playing || _completion || _recovering) {
        return;
      }
      _position = _mixer.consumedFrames;
      _emitAnalysis();
      if (_mixer.hadUnderrun || _mixer.queuedFrames < 8192) {
        _recovering = true;
        _buffering = true;
        _mixer.setPaused(true);
        unawaited(
          _lifecycle
              .run(_recover)
              .catchError((Object e) {
                _renderFailed('Buffer recovery: $e');
              })
              .whenComplete(() => _recovering = false),
        );
      } else {
        unawaited(
          _fill(_lifecycle.epoch).catchError((Object e) {
            _renderFailed('Render: $e');
          }),
        );
      }
    });
  }

  void _renderFailed(String error) {
    _lastError = error;
    _pumpTimer?.cancel();
    _mixer.setPaused(true);
    _buffering = false;
    _setState(AudioEngineState.paused);
    // Do not await the app callback inside the engine lifecycle queue.
    final notify = _onPause;
    if (notify != null) unawaited(notify().catchError((Object _) {}));
  }

  Future<void> _recover() async {
    if (_state != AudioEngineState.playing || _completion) return;
    _underruns++;
    await _filling;
    if (_mixer.hadUnderrun || _mixer.skewFrames > 1) {
      final checkpoint = await _worker.checkpoint(_position);
      await _mixer.close();
      await _worker.reset(
        config: _config,
        context: _context,
        seed: _seed,
        checkpoint: checkpoint,
      );
      _events.clear();
      _meters.clear();
      await _mixer.open(_position);
    }
    await _fill(_lifecycle.epoch);
    _mixer.start(_config, layerMuted, layerSolo);
    _buffering = false;
  }

  @override
  Future<void> updateConfig(SoundscapeConfig config) {
    _validate(config);
    final epoch = _lifecycle.epoch;
    return _lifecycle.run(() async {
      if (epoch != _lifecycle.epoch || _completion) {
        throw StateError('Session changed');
      }
      if (_state != AudioEngineState.stopped &&
          (config.beatsBpm != _config.beatsBpm ||
              config.gentlePulses != _config.gentlePulses)) {
        throw StateError('Rhythm tempo and voice are fixed during a session');
      }
      _config = config;
      if (_initialized) _mixer.applyGains(config, layerMuted, layerSolo);
      if (_state != AudioEngineState.stopped) {
        await _worker.update(config, _context, ++_revision);
      }
    });
  }

  @override
  Future<void> updateSessionContext(AudioSessionContext context) {
    final epoch = _lifecycle.epoch;
    return _lifecycle.run(() async {
      if (epoch != _lifecycle.epoch) return;
      if (context.presetId != _context.presetId &&
          _state != AudioEngineState.stopped) {
        throw StateError('Preset is fixed during a session');
      }
      _context = context;
      if (_state != AudioEngineState.stopped) {
        await _worker.update(_config, _context, ++_revision);
      }
    });
  }

  /// Debug compatibility; normal sessions use the typed context.
  @override
  Future<void> setFocusDepth(double value) {
    final phase = value >= .8
        ? SessionPhase.deepFocus
        : value >= .6
        ? SessionPhase.enteringFocus
        : value >= .4
        ? SessionPhase.windDown
        : SessionPhase.settling;
    return updateSessionContext(
      AudioSessionContext(
        presetId: _context.presetId,
        elapsed: playbackSnapshot.position,
        duration: _context.duration,
        phase: phase,
        followTimeline: false,
      ),
    );
  }

  @override
  AudioPlaybackSnapshot get playbackSnapshot {
    if (_initialized &&
        (_state == AudioEngineState.playing ||
            _state == AudioEngineState.paused)) {
      _position = _mixer.consumedFrames;
    }
    return AudioPlaybackSnapshot(
      consumedFrames: _position,
      buffering: _buffering,
      queuedFrames: _initialized ? _mixer.queuedFrames : 0,
    );
  }

  @override
  Future<Map<String, dynamic>> captureCheckpoint() => _lifecycle.run(() async {
    if (_state != AudioEngineState.playing &&
        _state != AudioEngineState.paused) {
      throw StateError('No active audio session');
    }
    final frame = playbackSnapshot.consumedFrames;
    final snapshot = await _worker.checkpoint(frame);
    // Current user intent takes precedence over the small amount of already
    // queued synthesis; DSP state remains anchored at the consumed frame.
    snapshot['config'] = _config.toJson();
    snapshot['context'] = _context.toJson();
    return snapshot;
  });
  @override
  Future<void> pause() => _lifecycle.run(() async {
    if (!_handlingInterruption) _interrupted = false;
    if (_state != AudioEngineState.playing) return;
    _pumpTimer?.cancel();
    _mixer.setPaused(true);
    _position = _mixer.consumedFrames;
    _setState(AudioEngineState.paused);
    _buffering = false;
    await _session?.setActive(false);
  });
  @override
  Future<void> resume() => _lifecycle.run(() async {
    if (_state != AudioEngineState.paused) return;
    if (await _session?.setActive(true) == false) {
      throw StateError('Audio focus denied');
    }
    await _fill(_lifecycle.epoch);
    _mixer.start(_config, layerMuted, layerSolo);
    _interrupted = false;
    _buffering = false;
    _setState(AudioEngineState.playing);
    _startPump();
  });
  @override
  Future<void> stop() {
    _lifecycle.invalidate();
    return _lifecycle.run(() => _stop(fade: true));
  }

  Future<void> _stop({required bool fade}) async {
    _pumpTimer?.cancel();
    _pumpTimer = null;
    try {
      await _filling;
    } on Object {
      // A failed pending render must not prevent native resources being freed.
    }
    if (_initialized) {
      if (fade && _state == AudioEngineState.playing) {
        _mixer.fadeOut(const Duration(milliseconds: 300));
        await Future<void>.delayed(const Duration(milliseconds: 320));
      }
      await _mixer.close();
      await _session?.setActive(false);
    }
    _events.clear();
    _meters.clear();
    _completion = false;
    _buffering = false;
    _interrupted = false;
    _setState(AudioEngineState.stopped);
    if (_preview != null && !_preview!.isCompleted) {
      _preview!.completeError(StateError('Playback stopped'));
    }
  }

  @override
  Future<void> playCompletionCue() => _lifecycle.run(() async {
    if (_state != AudioEngineState.playing) return;
    _completion = true;
    _pumpTimer?.cancel();
    _mixer.fadeOut(const Duration(milliseconds: 500));
    await Future<void>.delayed(const Duration(milliseconds: 520));
    _mixer.setPaused(true);
    if (_master <= 0 || _config.intensity <= 0) return;
    _cue = await _soloud.loadMem(
      'flundel-completion',
      SyntheticAudio.createTranquilChimeWavBytes(
        freqHz: 659.25,
        durationSeconds: 2.4,
      ),
    );
    _soloud.play(_cue!, volume: .10 * _config.intensity);
    await Future<void>.delayed(const Duration(milliseconds: 2450));
    await _soloud.disposeSource(_cue!);
    _cue = null;
  });
  void _emitAnalysis() {
    final frame = _position;
    final anySolo = layerSolo.values.any((v) => v);
    double gain(AudioStem s) =>
        (layerMuted[s.control] == true ||
            (anySolo && layerSolo[s.control] != true))
        ? 0
        : s.gain(_config) * _master;
    final event =
        _events.any(
          (e) =>
              e.kind == 'piano' &&
              e.frame > _lastAnalysisFrame &&
              e.frame <= frame,
        ) &&
        gain(AudioStem.piano) > 0;
    final active = _events
        .where(
          (e) =>
              e.kind == 'piano' &&
              e.frame <= frame &&
              e.frame > frame - 3 * 48000,
        )
        .length;
    final meter = _meters.where((m) => m.frame <= frame).lastOrNull;
    var tonal = 0.0;
    var texture = 0.0;
    if (meter != null) {
      for (final s in AudioStem.values) {
        final level = meter.energy[s.index] * gain(s) * 4;
        if ([
          AudioStem.noise,
          AudioStem.nature,
          AudioStem.wind,
          AudioStem.water,
          AudioStem.birds,
        ].contains(s)) {
          texture += level;
        } else {
          tonal += level;
        }
      }
    }
    _analysisController.add(
      AudioAnalysis(
        amplitude: _peak,
        tonalEnergy: tonal.clamp(0.0, 1.0),
        textureEnergy: texture.clamp(0.0, 1.0),
        pianoActivity: gain(AudioStem.piano) > 0
            ? (active / 8).clamp(0.0, 1.0)
            : 0,
        focusDepth: switch (_context.atFrame(frame).phase) {
          SessionPhase.settling => .3,
          SessionPhase.enteringFocus => .65,
          SessionPhase.deepFocus => .85,
          SessionPhase.windDown => .5,
          SessionPhase.completion => 0,
        },
        hasPianoEvent: event,
      ),
    );
    _lastAnalysisFrame = frame;
    _events.removeWhere((e) => e.frame < frame - 5 * 48000);
    while (_meters.length > 1 && _meters[1].frame <= frame) {
      _meters.removeAt(0);
    }
  }

  void _captured(Uint8List bytes) {
    if (_state != AudioEngineState.playing) return;
    final data = ByteData.sublistView(bytes);
    var peak = 0.0;
    for (var i = 0; i + 4 <= bytes.length; i += 4) {
      peak = max(peak, data.getFloat32(i, Endian.little).abs());
    }
    _peak = peak.isFinite ? peak : 0;
    if (_preview != null && !_preview!.isCompleted) {
      _previewPcm!.addFloat32(bytes);
      if (_previewPcm!.complete) _preview!.complete(_previewPcm!.bytes);
    }
  }

  @override
  Future<Uint8List> captureOutputPreview(Duration duration) async {
    if (_state != AudioEngineState.playing || _preview != null) {
      throw StateError('Preview requires playing and no other capture');
    }
    if (duration < const Duration(seconds: 1) ||
        duration > const Duration(seconds: 60)) {
      throw ArgumentError('Preview is 1..60 seconds');
    }
    final completer = Completer<Uint8List>();
    _preview = completer;
    _previewPcm = PcmWavCapture(duration.inMicroseconds * 48000 ~/ 1000000 * 2);
    try {
      return await completer.future.timeout(
        duration + const Duration(seconds: 4),
      );
    } finally {
      _preview = null;
      _previewPcm = null;
    }
  }

  @override
  void setMasterVolume(double value) {
    if (_lifecycle.closed || !value.isFinite) return;
    _master = value.clamp(0.0, 1.0);
    if (_initialized) {
      _soloud.fadeGlobalVolume(_master, const Duration(milliseconds: 180));
    }
  }

  @override
  void setLayerMuted(String layer, bool muted) {
    if (_lifecycle.closed || !layerMuted.containsKey(layer)) return;
    layerMuted[layer] = muted;
    if (_initialized) _mixer.applyGains(_config, layerMuted, layerSolo);
  }

  @override
  void setLayerSolo(String layer, bool solo) {
    if (_lifecycle.closed || !layerSolo.containsKey(layer)) return;
    layerSolo[layer] = solo;
    if (_initialized) _mixer.applyGains(_config, layerMuted, layerSolo);
  }

  @override
  void setFilterCutoff(double value) =>
      _updateEffects(cutoff: value.clamp(200.0, 8000.0));

  @override
  void setReverbMix(double value) =>
      _updateEffects(reverb: value.clamp(0.0, 1.0));

  void _updateEffects({double? cutoff, double? reverb}) {
    if (_state == AudioEngineState.stopped || _lifecycle.closed) return;
    final epoch = _lifecycle.epoch;
    unawaited(
      _lifecycle
          .run(() async {
            if (epoch != _lifecycle.epoch || _completion) return;
            await _worker.update(
              _config,
              _context,
              ++_revision,
              cutoff: cutoff,
              reverb: reverb,
            );
          })
          .catchError((Object error) {
            if (epoch == _lifecycle.epoch && !_lifecycle.closed) {
              _lastError = 'Effects: $error';
            }
          }),
    );
  }

  @override
  void setExternalPlaybackHandlers({
    Future<void> Function()? onPause,
    Future<void> Function()? onResume,
  }) {
    _onPause = onPause;
    _onResume = onResume;
  }

  @override
  AudioDiagnostics get diagnostics => AudioDiagnostics(
    playback: playbackSnapshot,
    underruns: _underruns,
    activeVoices: _initialized ? _soloud.getVoiceCount() : 0,
    bufferBytes: _initialized ? _mixer.bufferBytes : 0,
    renderLoad: _renderLoad,
    renderedBlocks: _renderedBlocks,
    worstRenderMs: _worstRenderMicros / 1000,
    overBudgetBlocks: _overBudgetBlocks,
    error: _lastError,
  );
  @override
  Map<String, dynamic> getDiagnostics() => {
    'state': _state.name,
    'backend': 'flutter_soloud/streaming',
    'workerRunning': _worker.isOpen,
    'nativeInitialized': _soloud.isInitialized,
    'sampleRateHz': 48000,
    'bufferSizeFrames': 2048,
    'peakAmplitude': _peak,
    'outputPeakDbfs': _peak > 0 ? 20 * log(_peak) / ln10 : -120.0,
    'lastError': _lastError,
    'activeVoiceHandles': _mixer.activeVoices,
    'nativeVoiceCount': _initialized ? _soloud.getVoiceCount() : 0,
    'maxPianoVoices': 8,
    'activePianoVoices': _events
        .where(
          (e) =>
              e.kind == 'piano' &&
              e.frame <= _position &&
              e.frame > _position - 3 * 48000,
        )
        .length,
    'consumedFrames': playbackSnapshot.consumedFrames,
    'queuedFrames': playbackSnapshot.queuedFrames,
    'buffering': _buffering,
    'underrunsCount': _underruns,
    'bufferBytes': diagnostics.bufferBytes,
    'renderLoad': _renderLoad,
    'renderedBlocks': _renderedBlocks,
    'worstRenderMs': _worstRenderMicros / 1000,
    'overBudgetBlocks': _overBudgetBlocks,
    'startupMs': _startupMs,
    'masterVolume': _master,
    'layerMuted': Map.of(layerMuted),
    'layerSolo': Map.of(layerSolo),
    'rhythmBpm': _config.beatsBpm,
    'gentlePulses': _config.gentlePulses,
    'mixerCaptureActive': _initialized && _soloud.isMixerOutputStreamRunning,
    'stemSkewFrames': _initialized ? _mixer.skewFrames : 0,
  };
  void _setState(AudioEngineState s) {
    if (s == _state) return;
    _state = s;
    if (!_stateController.isClosed) _stateController.add(s);
  }

  @override
  Stream<AudioAnalysis> get analysisStream => _analysisController.stream;
  @override
  Stream<AudioEngineState> get stateStream => _stateController.stream;
  Future<void> _cleanup() async {
    _pumpTimer?.cancel();
    await _capture?.cancel();
    await _interruption?.cancel();
    await _noisy?.cancel();
    _capture = null;
    _interruption = null;
    _noisy = null;
    if (_soloud.isInitialized) {
      if (_soloud.isMixerOutputStreamRunning) _soloud.stopMixerOutputStream();
      await _mixer.close();
      if (_cue != null) await _soloud.disposeSource(_cue!);
      await _soloud.deinitAsync();
    }
    _cue = null;
    _initialized = false;
    await _worker.dispose();
  }

  @override
  Future<void> dispose() => _lifecycle.close(() async {
    await _stop(fade: false);
    _onPause = null;
    _onResume = null;
    await _cleanup();
    await _analysisController.close();
    await _stateController.close();
  });
}
