import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'package:flundel/domain/models/focus_session.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';
import 'package:flundel/storage/local_storage.dart';
import 'package:flundel/audio/audio_engine.dart';
import 'package:flundel/session/session_phase.dart';
import 'package:flundel/session/session_state.dart';

final sessionViewModelProvider =
    NotifierProvider<SessionViewModel, SessionState>(SessionViewModel.new);

class SessionViewModel extends Notifier<SessionState> {
  Timer? _timer;

  LocalStorageRepository get _storage => ref.read(localStorageRepositoryProvider);
  AudioEngine get _audioEngine => ref.read(audioEngineProvider);

  @override
  SessionState build() {
    ref.onDispose(() => _timer?.cancel());

    final activeJson = _storage.getActiveSession();
    if (activeJson != null) {
      try {
        final session = FocusSession.fromJson(activeJson);
        final now = DateTime.now();
        final elapsed = now.difference(session.startedAt).inSeconds;

        if (session.durationSeconds == null || elapsed < session.durationSeconds!) {
          final initialPhase = SessionPhaseX.calculatePhase(
            elapsedSeconds: elapsed,
            totalDurationSeconds: session.durationSeconds,
          );
          _audioEngine.start(
            session.preset.config,
            sessionSeed: session.id.hashCode,
          );
          _audioEngine.setFocusDepth(_focusDepthForPhase(initialPhase));
          _startTimer();

          return SessionState(
            isActive: true,
            currentSession: session,
            elapsedSeconds: elapsed,
            remainingSeconds: session.durationSeconds != null
                ? session.durationSeconds! - elapsed
                : null,
            phase: SessionPhaseX.calculatePhase(
              elapsedSeconds: elapsed,
              totalDurationSeconds: session.durationSeconds,
            ),
            selectedPreset: session.preset,
            selectedDurationSeconds: session.durationSeconds,
            pomodoroEnabled: session.isPomodoro,
          );
        } else {
          _storage.clearActiveSession();
        }
      } catch (_) {
        _storage.clearActiveSession();
      }
    }

    return SessionState(
      selectedPreset: SoundscapePreset.builtInPresets.firstWhere(
        (p) => p.id == _storage.getLastPresetId(),
        orElse: () => SoundscapePreset.builtInPresets.first,
      ),
      selectedDurationSeconds: _storage.getLastDurationSeconds(),
      pomodoroEnabled: _storage.isPomodoroEnabled(),
    );
  }

  void selectPreset(SoundscapePreset preset) {
    if (state.isActive) return;
    _storage.setLastPresetId(preset.id);
    state = state.copyWith(selectedPreset: preset);
  }

  void selectDuration(int? durationSeconds) {
    if (state.isActive) return;
    _storage.setLastDurationSeconds(durationSeconds);
    state = state.copyWith(selectedDurationSeconds: durationSeconds);
  }

  void togglePomodoro(bool enabled) {
    _storage.setPomodoroEnabled(enabled);
    state = state.copyWith(pomodoroEnabled: enabled);
  }

  Future<void> startSession() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    final session = FocusSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startedAt: DateTime.now(),
      durationSeconds: state.selectedDurationSeconds,
      preset: state.selectedPreset,
      isPomodoro: state.pomodoroEnabled,
    );

    await _storage.saveActiveSession(session.toJson());
    await _audioEngine.start(
      session.preset.config,
      sessionSeed: session.id.hashCode,
    );
    await _audioEngine.setFocusDepth(_focusDepthForPhase(SessionPhase.settling));

    try {
      Vibration.hasVibrator().then((hasVibrator) {
        if (hasVibrator == true) {
          Vibration.vibrate(duration: 50).catchError((_) {});
        }
      }).catchError((_) {});
    } catch (_) {}

    state = state.copyWith(
      isActive: true,
      isLoading: false,
      currentSession: session,
      elapsedSeconds: 0,
      remainingSeconds: state.selectedDurationSeconds,
      phase: SessionPhase.settling,
    );

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  void _tick() {
    if (!state.isActive || state.currentSession == null) return;

    final newElapsed = state.elapsedSeconds + 1;
    final totalDuration = state.selectedDurationSeconds;

    if (totalDuration != null) {
      final newRemaining = totalDuration - newElapsed;
      if (newRemaining <= 0) {
        completeSession();
        return;
      }

      final newPhase = SessionPhaseX.calculatePhase(
        elapsedSeconds: newElapsed,
        totalDurationSeconds: totalDuration,
      );

      if (newPhase != state.phase) {
        _audioEngine.setFocusDepth(_focusDepthForPhase(newPhase));
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
        _audioEngine.setFocusDepth(_focusDepthForPhase(newPhase));
      }

      state = state.copyWith(
        elapsedSeconds: newElapsed,
        remainingSeconds: null,
        phase: newPhase,
      );
    }
  }

  double _focusDepthForPhase(SessionPhase phase) {
    switch (phase) {
      case SessionPhase.settling:
        return 0.30;
      case SessionPhase.enteringFocus:
        return 0.65;
      case SessionPhase.deepFocus:
        return 0.85;
      case SessionPhase.windDown:
        return 0.50;
      case SessionPhase.completion:
        return 0.0;
    }
  }

  Future<void> stopSession() async {
    state = state.copyWith(isLoading: true);
    _timer?.cancel();
    _timer = null;

    await _audioEngine.stop();
    await _storage.clearActiveSession();

    state = state.copyWith(
      isActive: false,
      isLoading: false,
      currentSession: null,
      elapsedSeconds: 0,
      remainingSeconds: state.selectedDurationSeconds,
      phase: SessionPhase.settling,
    );
  }

  Future<void> completeSession() async {
    _timer?.cancel();
    _timer = null;

    try {
      Vibration.hasVibrator().then((hasVibrator) {
        if (hasVibrator == true) {
          Vibration.vibrate(pattern: [0, 100, 100, 150]).catchError((_) {});
        }
      }).catchError((_) {});
    } catch (_) {}

    await _audioEngine.stop();
    await _storage.clearActiveSession();

    state = state.copyWith(
      isActive: false,
      currentSession: null,
      elapsedSeconds: 0,
      remainingSeconds: state.selectedDurationSeconds,
      phase: SessionPhase.completion,
    );
  }
}
