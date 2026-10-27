import 'dart:async';
import 'dart:math' show max;

import 'package:flundel/audio/audio_engine.dart';
import 'package:flundel/audio/audio_session_context.dart';
import 'package:flundel/audio/flundel_audio_handler.dart';
import 'package:flundel/domain/models/focus_session.dart';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';
import 'package:flundel/session/session_phase.dart';
import 'package:flundel/session/session_state.dart';
import 'package:flundel/storage/local_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

final sessionViewModelProvider =
    NotifierProvider<SessionViewModel, SessionState>(SessionViewModel.new);

class SessionViewModel extends Notifier<SessionState> {
  Timer? _timer;
  AppLifecycleListener? _appLifecycle;
  Map<String, dynamic>? _audioCheckpoint;
  int _lastCheckpointSecond = 0;
  Future<void> _storageTail = Future.value();
  bool _checkpointPending = false;
  bool _restoreNeedsRetry = false;
  LocalStorageRepository? _storageRepository;
  AudioEngine? _engine;
  bool _disposed = false;
  SoundscapeConfig? _committedConfig;
  SoundscapeConfig? _requestedConfig;
  SoundscapeConfig? _pendingConfig;
  Future<void>? _configDrain;
  int _configRevision = 0;
  int _sessionEpoch = 0;
  Future<void> _lifecycleTail = Future<void>.value();
  final List<_ConfigWaiter> _configWaiters = [];

  LocalStorageRepository get _storage {
    final repository = _storageRepository;
    if (repository != null) return repository;
    final created = ref.read(localStorageRepositoryProvider);
    _storageRepository = created;
    return created;
  }

  AudioEngine get _audioEngine {
    final engine = _engine;
    if (engine != null) return engine;
    final created = ref.read(audioEngineProvider);
    _engine = created;
    return created;
  }

  @override
  SessionState build() {
    _disposed = false;
    _appLifecycle = AppLifecycleListener(
      onInactive: () {
        if (state.isActive) unawaited(_checkpointSession());
      },
      onPause: () {
        if (state.isActive) unawaited(_checkpointSession());
      },
    );
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
      _appLifecycle?.dispose();
      _engine?.setExternalPlaybackHandlers();
      flundelAudioHandler?.onPlay = null;
      flundelAudioHandler?.onPause = null;
      flundelAudioHandler?.onStop = null;
      _pendingConfig = null;
      for (final waiter in _configWaiters) {
        if (!waiter.completer.isCompleted) waiter.completer.complete(false);
      }
      _configWaiters.clear();
    });

    final activeJson = _storage.getActiveSession();
    if (activeJson != null) {
      try {
        final saved = FocusSession.fromJson(activeJson);
        final now = DateTime.now();
        _audioCheckpoint = activeJson['audioCheckpoint'] is Map
            ? Map<String, dynamic>.from(activeJson['audioCheckpoint'] as Map)
            : null;
        final frames =
            (_audioCheckpoint?['frame'] as num?)?.toInt() ??
            (activeJson['elapsedFrames'] as num?)?.toInt() ??
            (saved.pausedAt == null
                ? 0
                : max(
                        0,
                        saved.pausedAt!.difference(saved.startedAt).inSeconds -
                            saved.totalPausedSeconds,
                      ) *
                      48000);
        final elapsed = frames ~/ 48000;
        final session = saved.copyWith(
          pausedAt: now,
          startedAt: now.subtract(Duration(seconds: elapsed)),
          totalPausedSeconds: 0,
        );
        _lastCheckpointSecond = elapsed;

        if (session.durationSeconds == null ||
            elapsed < session.durationSeconds!) {
          final initialPhase = SessionPhaseX.calculatePhase(
            elapsedSeconds: elapsed,
            totalDurationSeconds: session.durationSeconds,
          );
          _sessionEpoch++;
          _committedConfig = session.preset.config;
          _requestedConfig = session.preset.config;
          final selectedPreset = SoundscapePreset.builtInPresets.firstWhere(
            (preset) => preset.id == session.preset.id,
            orElse: () => session.preset,
          );

          final restoredState = SessionState(
            isActive: true,
            isPaused: true,
            currentSession: session,
            elapsedSeconds: elapsed,
            remainingSeconds: session.durationSeconds != null
                ? session.durationSeconds! - elapsed
                : null,
            phase: SessionPhaseX.calculatePhase(
              elapsedSeconds: elapsed,
              totalDurationSeconds: session.durationSeconds,
            ),
            selectedPreset: selectedPreset,
            selectedDurationSeconds: session.durationSeconds,
            pomodoroEnabled: session.isPomodoro,
            completionCueEnabled: session.completionCueEnabled,
          );
          _bindMediaHandler(restoredState);
          unawaited(
            _serializeLifecycle(
              () => _restoreAudioSession(session, initialPhase),
            ),
          );
          return restoredState;
        } else {
          unawaited(_storage.clearActiveSession());
        }
      } on Object {
        unawaited(_storage.clearActiveSession());
      }
    }

    return SessionState(
      selectedPreset: SoundscapePreset.builtInPresets.firstWhere(
        (p) => p.id == _storage.getLastPresetId(),
        orElse: () => SoundscapePreset.builtInPresets.first,
      ),
      selectedDurationSeconds: _storage.getLastDurationSeconds(),
      pomodoroEnabled: _storage.isPomodoroEnabled(),
      completionCueEnabled: _storage.isCompletionCueEnabled(),
    );
  }

  void selectPreset(SoundscapePreset preset) {
    if (state.isActive) return;
    unawaited(_storage.setLastPresetId(preset.id));
    state = state.copyWith(selectedPreset: preset);
  }

  void selectDuration(int? durationSeconds) {
    if (state.isActive) return;
    unawaited(_storage.setLastDurationSeconds(durationSeconds));
    state = state.copyWith(selectedDurationSeconds: durationSeconds);
  }

  void togglePomodoro(bool enabled) {
    unawaited(_storage.setPomodoroEnabled(enabled));
    state = state.copyWith(pomodoroEnabled: enabled);
  }

  Future<void> setCompletionCueEnabled(bool enabled) =>
      _serializeLifecycle(() async {
        await _configDrain;
        final epoch = _sessionEpoch;
        final session = state.currentSession;
        await _storage.setCompletionCueEnabled(enabled);
        if (_disposed || epoch != _sessionEpoch) return;
        if (session != null && state.currentSession?.id == session.id) {
          final updated = session.copyWith(completionCueEnabled: enabled);
          await _saveSessionJson(_sessionJson(updated));
          if (!_disposed &&
              epoch == _sessionEpoch &&
              state.currentSession?.id == session.id) {
            state = state.copyWith(
              completionCueEnabled: enabled,
              currentSession: updated,
            );
          }
        } else {
          state = state.copyWith(completionCueEnabled: enabled);
        }
      });

  Future<void> startSession() => _serializeLifecycle(_startSession);

  Future<void> _startSession() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, isPaused: false);
    final epoch = ++_sessionEpoch;
    _audioCheckpoint = null;
    _restoreNeedsRetry = false;
    _lastCheckpointSecond = 0;

    final sessionSeed = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
    final session = FocusSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startedAt: DateTime.now(),
      durationSeconds: state.selectedDurationSeconds,
      preset: state.selectedPreset,
      sessionSeed: sessionSeed,
      isPomodoro: state.pomodoroEnabled,
      completionCueEnabled: _storage.isCompletionCueEnabled(),
    );

    try {
      await _saveSessionJson(_sessionJson(session));
      await _audioEngine.start(
        session.preset.config,
        sessionSeed: session.sessionSeed,
        context: _audioContext(session),
      );
      if (_disposed || epoch != _sessionEpoch) return;
    } on Object {
      await _storage.clearActiveSession();
      if (!_disposed && epoch == _sessionEpoch) {
        state = state.copyWith(
          isActive: false,
          isLoading: false,
          isPaused: false,
        );
      }
      return;
    }
    _committedConfig = session.preset.config;
    _requestedConfig = session.preset.config;
    await _audioEngine.updateSessionContext(_audioContext(session));

    try {
      unawaited(
        Vibration.hasVibrator()
            .then((hasVibrator) async {
              if (hasVibrator) await Vibration.vibrate(duration: 50);
            })
            .catchError((Object _) {}),
      );
    } on Object {}

    state = state.copyWith(
      isActive: true,
      isLoading: false,
      currentSession: session,
      elapsedSeconds: 0,
      remainingSeconds: state.selectedDurationSeconds,
      phase: SessionPhase.settling,
    );

    _startTimer();
    _bindMediaHandler(state);
  }

  /// Applies live slider changes as a last-write-wins stream. Updates are
  /// serialized, while intermediate drag values are coalesced to the latest
  /// requested config. The visible config is committed only after the engine
  /// accepts it and the active-session snapshot is persisted.
  Future<bool> updateSessionControls({
    double? intensity,
    double? warmth,
    double? piano,
    double? beats,
    double? bass,
    double? nature,
    double? binaural,
    double? noise,
    double? pad,
    double? complexity,
  }) {
    if (!state.isActive ||
        state.isPaused ||
        state.isLoading ||
        state.currentSession == null) {
      return Future.value(false);
    }

    final baseConfig =
        _pendingConfig ??
        _requestedConfig ??
        _committedConfig ??
        state.currentSession!.preset.config;
    final nextConfig = baseConfig.copyWith(
      intensity: intensity ?? baseConfig.intensity,
      warmth: warmth ?? baseConfig.warmth,
      piano: piano ?? baseConfig.piano,
      beats: beats ?? baseConfig.beats,
      bass: bass ?? baseConfig.bass,
      nature: nature ?? baseConfig.nature,
      binaural: binaural ?? baseConfig.binaural,
      noise: noise ?? baseConfig.noise,
      pad: pad ?? baseConfig.pad,
      complexity: complexity ?? baseConfig.complexity,
    );
    _pendingConfig = nextConfig;
    _requestedConfig = nextConfig;

    final completer = Completer<bool>();
    _configWaiters.add(_ConfigWaiter(++_configRevision, completer));
    _startConfigDrain();
    return completer.future;
  }

  void _startConfigDrain() {
    if (_configDrain != null) return;
    _configDrain = _drainConfigUpdates().whenComplete(() {
      _configDrain = null;
      if (_pendingConfig != null) _startConfigDrain();
    });
  }

  Future<void> _drainConfigUpdates() async {
    while (_pendingConfig != null) {
      final config = _pendingConfig!;
      final revision = _configRevision;
      final epoch = _sessionEpoch;
      final sessionId = state.currentSession?.id;
      _pendingConfig = null;

      try {
        await _audioEngine.updateConfig(config);
        if (_disposed) {
          final committedConfig = _committedConfig;
          if (committedConfig != null) {
            try {
              await _audioEngine.updateConfig(committedConfig);
            } on Object {}
          }
          _completeConfigWaiters(revision, false);
          return;
        }
        final session = state.currentSession;
        if (session == null ||
            !state.isActive ||
            sessionId != session.id ||
            epoch != _sessionEpoch) {
          _completeConfigWaiters(revision, false);
          continue;
        }

        final updatedPreset = session.preset.copyWith(config: config);
        final updatedSession = session.copyWith(preset: updatedPreset);
        await _saveSessionJson(_sessionJson(updatedSession));
        if (!state.isActive ||
            sessionId != state.currentSession?.id ||
            epoch != _sessionEpoch) {
          _completeConfigWaiters(revision, false);
          continue;
        }
        if (_disposed) {
          _completeConfigWaiters(revision, false);
          return;
        }
        _committedConfig = config;
        state = state.copyWith(currentSession: updatedSession);
        _completeConfigWaiters(revision, true);
      } on Object {
        // If persistence failed after the engine accepted the new config, put
        // the engine back on the last durable configuration where possible.
        final committedConfig = _committedConfig;
        if (committedConfig != null) {
          try {
            await _audioEngine.updateConfig(committedConfig);
          } on Object {
            // The UI and restored session still retain the last durable value.
          }
        }
        if (_pendingConfig == null) {
          _completeConfigWaiters(revision, false);
          _requestedConfig = _committedConfig;
        }
      }
    }
  }

  void _completeConfigWaiters(int revision, bool success) {
    final completed = _configWaiters
        .where((waiter) => waiter.revision <= revision)
        .toList();
    _configWaiters.removeWhere((waiter) => waiter.revision <= revision);
    for (final waiter in completed) {
      if (!waiter.completer.isCompleted) waiter.completer.complete(success);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  void _tick() {
    if (!state.isActive || state.isPaused || state.currentSession == null) {
      return;
    }

    final session = state.currentSession!;
    final newElapsed = _audioEngine.playbackSnapshot.position.inSeconds;
    if (newElapsed - _lastCheckpointSecond >= 4) {
      unawaited(_checkpointSession());
    }
    final totalDuration = state.selectedDurationSeconds;

    if (totalDuration != null) {
      final newRemaining = totalDuration - newElapsed;
      if (newRemaining <= 0) {
        unawaited(completeSession());
        return;
      }

      final newPhase = SessionPhaseX.calculatePhase(
        elapsedSeconds: newElapsed,
        totalDurationSeconds: totalDuration,
      );

      if (newPhase != state.phase) {
        unawaited(
          _audioEngine.updateSessionContext(
            _audioContext(session, elapsed: newElapsed, phase: newPhase),
          ),
        );
      }

      state = state.copyWith(
        elapsedSeconds: newElapsed,
        remainingSeconds: newRemaining,
        phase: newPhase,
      );
    } else {
      // Endless session
      final newPhase = SessionPhaseX.calculatePhase(
        elapsedSeconds: newElapsed,
        totalDurationSeconds: null,
      );

      if (newPhase != state.phase) {
        unawaited(
          _audioEngine.updateSessionContext(
            _audioContext(session, elapsed: newElapsed, phase: newPhase),
          ),
        );
      }

      state = state.copyWith(
        elapsedSeconds: newElapsed,
        remainingSeconds: null,
        phase: newPhase,
      );
    }
  }

  AudioSessionContext _audioContext(
    FocusSession session, {
    int? elapsed,
    SessionPhase? phase,
  }) => AudioSessionContext(
    presetId: session.preset.id,
    elapsed: Duration(seconds: elapsed ?? state.elapsedSeconds),
    duration: session.durationSeconds == null
        ? null
        : Duration(seconds: session.durationSeconds!),
    phase: phase ?? state.phase,
  );

  Map<String, dynamic> _sessionJson(FocusSession session) => {
    ...session.toJson(),
    'audioCheckpoint': _audioCheckpoint,
    'elapsedFrames': _audioCheckpoint?['frame'] ?? state.elapsedSeconds * 48000,
  };

  Future<void> _saveSessionJson(Map<String, dynamic> json) {
    final work = _storageTail.then((_) => _storage.saveActiveSession(json));
    _storageTail = work.catchError((Object _) {});
    return work;
  }

  Future<void> _checkpointSession() async {
    if (_checkpointPending || _disposed || !state.isActive || state.isLoading) {
      return;
    }
    _checkpointPending = true;
    try {
      await _serializeLifecycle(() async {
        final epoch = _sessionEpoch;
        final checkpoint = await _audioEngine.captureCheckpoint();
        await _configDrain;
        final session = state.currentSession;
        if (_disposed ||
            epoch != _sessionEpoch ||
            session == null ||
            !state.isActive) {
          return;
        }
        _audioCheckpoint = checkpoint;
        await _saveSessionJson(_sessionJson(session));
        _lastCheckpointSecond = (checkpoint['frame'] as int) ~/ 48000;
      });
    } on Object {
      // Retry on the next timer tick; do not claim a checkpoint was durable.
    } finally {
      _checkpointPending = false;
    }
  }

  Future<void> stopSession() {
    if (state.isActive) state = state.copyWith(isLoading: true);
    return _serializeLifecycle(_stopSession);
  }

  Future<void> _stopSession() async {
    state = state.copyWith(isLoading: true);
    _timer?.cancel();
    _timer = null;

    // Let any accepted in-flight configuration finish before stopping audio
    // and clearing the durable snapshot. This prevents a late config write
    // from recreating an active session after stop completes.
    await _configDrain;
    ++_sessionEpoch;
    _pendingConfig = null;

    await _audioEngine.stop();
    await _storageTail;
    await _storage.clearActiveSession();
    _audioCheckpoint = null;
    flundelAudioHandler?.publishIdle();
    if (_disposed) return;
    _pendingConfig = null;
    _requestedConfig = null;

    state = state.copyWith(
      isActive: false,
      isPaused: false,
      isLoading: false,
      currentSession: null,
      elapsedSeconds: 0,
      remainingSeconds: state.selectedDurationSeconds,
      phase: SessionPhase.settling,
    );
  }

  Future<void> completeSession() => _serializeLifecycle(_completeSession);

  Future<void> _completeSession() async {
    ++_sessionEpoch;
    state = state.copyWith(isLoading: true);
    _timer?.cancel();
    _timer = null;

    await _configDrain;
    _pendingConfig = null;
    if (_disposed) return;

    try {
      unawaited(
        Vibration.hasVibrator()
            .then((hasVibrator) async {
              if (hasVibrator)
                await Vibration.vibrate(pattern: [0, 100, 100, 150]);
            })
            .catchError((Object _) {}),
      );
    } on Object {}

    final cueEnabled = state.currentSession?.completionCueEnabled ?? true;
    if (cueEnabled) {
      await _audioEngine.playCompletionCue();
    }
    await _audioEngine.stop();
    await _storageTail;
    await _storage.clearActiveSession();
    _audioCheckpoint = null;
    flundelAudioHandler?.publishIdle();
    if (_disposed) return;
    _pendingConfig = null;
    _requestedConfig = null;

    state = state.copyWith(
      isActive: false,
      isPaused: false,
      isLoading: false,
      currentSession: null,
      elapsedSeconds: 0,
      remainingSeconds: state.selectedDurationSeconds,
      phase: SessionPhase.completion,
    );
  }

  Future<void> pauseSession() => _serializeLifecycle(_pauseSession);

  Future<void> _pauseSession() async {
    if (!state.isActive || state.isPaused || state.currentSession == null) {
      return;
    }
    state = state.copyWith(isLoading: true);
    await _configDrain;
    if (_disposed || !state.isActive || state.currentSession == null) {
      if (!_disposed) state = state.copyWith(isLoading: false);
      return;
    }
    final now = DateTime.now();
    final session = state.currentSession!;
    final pausedSession = session.copyWith(pausedAt: now);
    try {
      await _audioEngine.pause();
      _audioCheckpoint = await _audioEngine.captureCheckpoint();
      await _saveSessionJson(_sessionJson(pausedSession));
      _timer?.cancel();
      _timer = null;
      state = state.copyWith(
        isPaused: true,
        isLoading: false,
        currentSession: pausedSession,
      );
      flundelAudioHandler?.publish(playing: false);
    } on Object {
      _timer?.cancel();
      _timer = null;
      state = state.copyWith(
        isPaused: true,
        isLoading: false,
        currentSession: pausedSession,
      );
      flundelAudioHandler?.publish(playing: false);
    }
  }

  Future<void> resumeSession() => _serializeLifecycle(_resumeSession);

  Future<void> _resumeSession() async {
    final session = state.currentSession;
    final pausedAt = session?.pausedAt;
    if (!state.isActive ||
        !state.isPaused ||
        session == null ||
        pausedAt == null) {
      return;
    }
    state = state.copyWith(isLoading: true);
    final updatedSession = session.copyWith(
      pausedAt: null,
      totalPausedSeconds:
          session.totalPausedSeconds +
          DateTime.now().difference(pausedAt).inSeconds,
    );
    try {
      if (_restoreNeedsRetry) {
        await _audioEngine.start(
          session.preset.config,
          sessionSeed: session.sessionSeed,
          context: _audioContext(session),
          checkpoint: _audioCheckpoint,
          startPaused: true,
        );
        _restoreNeedsRetry = false;
      }
      await _audioEngine.resume();
      await _saveSessionJson(_sessionJson(updatedSession));
      state = state.copyWith(
        isPaused: false,
        isLoading: false,
        currentSession: updatedSession,
      );
      _startTimer();
      flundelAudioHandler?.publish(playing: true);
    } on Object {
      try {
        await _audioEngine.pause();
        await _saveSessionJson(_sessionJson(session));
      } on Object {}
      state = state.copyWith(isLoading: false);
    }
  }

  void _bindMediaHandler(SessionState currentState) {
    final handler = flundelAudioHandler;
    _audioEngine.setExternalPlaybackHandlers(
      onPause: pauseSession,
      onResume: resumeSession,
    );
    if (handler == null) return;
    handler.onPlay = resumeSession;
    handler.onPause = pauseSession;
    handler.onStop = stopSession;
    handler.publish(playing: currentState.isActive && !currentState.isPaused);
  }

  Future<void> _restoreAudioSession(
    FocusSession session,
    SessionPhase phase,
  ) async {
    final epoch = _sessionEpoch;
    try {
      await _audioEngine.start(
        session.preset.config,
        sessionSeed: session.sessionSeed,
        context: _audioContext(session, phase: phase),
        checkpoint: _audioCheckpoint,
        startPaused: true,
      );
      await _saveSessionJson(_sessionJson(session));
    } on Object {
      if (!_disposed &&
          epoch == _sessionEpoch &&
          state.currentSession?.id == session.id) {
        _restoreNeedsRetry = true;
        state = state.copyWith(isActive: true, isPaused: true);
        flundelAudioHandler?.publish(playing: false);
      }
    }
  }

  Future<void> _serializeLifecycle(Future<void> Function() operation) {
    final previous = _lifecycleTail;
    final done = Completer<void>();
    _lifecycleTail = done.future;
    return previous.catchError((_) {}).then((_) => operation()).whenComplete(
      () {
        if (!done.isCompleted) done.complete();
      },
    );
  }
}

class _ConfigWaiter {
  const _ConfigWaiter(this.revision, this.completer);
  final int revision;
  final Completer<bool> completer;
}
