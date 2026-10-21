import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flundel/audio/audio_analysis.dart';
import 'package:flundel/audio/audio_engine.dart';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flundel/domain/models/focus_session.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';
import 'package:flundel/session/session_phase.dart';
import 'package:flundel/session/session_view_model.dart';
import 'package:flundel/storage/local_storage.dart';

class FakeLocalStorageRepository implements LocalStorageRepository {
  String _presetId = 'deep_work';
  int? _durationSeconds = 1500;
  bool _pomodoro = false;
  bool _completionCueEnabled = true;
  Map<String, dynamic>? _activeSession;

  @override
  String getLastPresetId() => _presetId;

  @override
  Future<void> setLastPresetId(String presetId) async => _presetId = presetId;

  @override
  int? getLastDurationSeconds() => _durationSeconds;

  @override
  Future<void> setLastDurationSeconds(int? seconds) async =>
      _durationSeconds = seconds;

  @override
  bool isPomodoroEnabled() => _pomodoro;

  @override
  Future<void> setPomodoroEnabled(bool enabled) async => _pomodoro = enabled;

  @override
  bool isCompletionCueEnabled() => _completionCueEnabled;

  @override
  Future<void> setCompletionCueEnabled(bool enabled) async =>
      _completionCueEnabled = enabled;

  @override
  Map<String, dynamic>? getActiveSession() => _activeSession;

  @override
  Future<void> saveActiveSession(Map<String, dynamic> sessionJson) async =>
      _activeSession = sessionJson;

  @override
  Future<void> clearActiveSession() async => _activeSession = null;
}

class FakeAudioEngine implements AudioEngine {
  final _analysisController = StreamController<AudioAnalysis>.broadcast();
  final _stateController = StreamController<AudioEngineState>.broadcast();
  final configs = <SoundscapeConfig>[];
  bool failConfigUpdates = false;
  bool failStart = false;
  bool failResume = false;
  Completer<void>? updateGate;
  int concurrentConfigUpdates = 0;
  int maxConcurrentConfigUpdates = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> start(SoundscapeConfig config, {int sessionSeed = 42}) async {
    if (failStart) throw StateError('audio startup failed');
    _stateController.add(AudioEngineState.playing);
  }

  @override
  Future<void> updateConfig(SoundscapeConfig config) async {
    concurrentConfigUpdates++;
    if (concurrentConfigUpdates > maxConcurrentConfigUpdates) {
      maxConcurrentConfigUpdates = concurrentConfigUpdates;
    }
    try {
      await updateGate?.future;
      if (failConfigUpdates) throw StateError('config update failed');
      configs.add(config);
    } finally {
      concurrentConfigUpdates--;
    }
  }

  @override
  Future<void> setFocusDepth(double value) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {
    if (failResume) throw StateError('audio focus denied');
  }

  @override
  Future<void> playCompletionCue() async {}

  @override
  Future<Uint8List> captureOutputPreview(Duration duration) async =>
      Uint8List(0);

  @override
  void setMasterVolume(double value) {}

  @override
  void setLayerMuted(String layer, bool muted) {}

  @override
  void setLayerSolo(String layer, bool solo) {}

  @override
  void setFilterCutoff(double value) {}

  @override
  void setReverbMix(double value) {}

  @override
  void setExternalPlaybackHandlers({
    required Future<void> Function() onPause,
    required Future<void> Function() onResume,
  }) {}

  @override
  Future<void> stop() async {
    _stateController.add(AudioEngineState.stopped);
  }

  @override
  Stream<AudioAnalysis> get analysisStream => _analysisController.stream;

  @override
  Stream<AudioEngineState> get stateStream => _stateController.stream;

  @override
  Map<String, dynamic> getDiagnostics() => {};
}

void main() {
  late ProviderContainer container;
  late FakeLocalStorageRepository fakeStorage;
  late FakeAudioEngine fakeAudioEngine;

  setUp(() {
    fakeStorage = FakeLocalStorageRepository();
    fakeAudioEngine = FakeAudioEngine();

    container = ProviderContainer(
      overrides: [
        localStorageRepositoryProvider.overrideWithValue(fakeStorage),
        audioEngineProvider.overrideWithValue(fakeAudioEngine),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('SessionViewModel UI State Tests', () {
    test('Initial UI state reflects default settings', () {
      final state = container.read(sessionViewModelProvider);

      expect(state.isActive, false);
      expect(state.currentSession, null);
      expect(state.selectedPreset.id, 'deep_work');
      expect(state.selectedDurationSeconds, 1500);
      expect(state.pomodoroEnabled, false);
      expect(state.phase, SessionPhase.settling);
    });

    test('selectPreset updates UI state', () {
      final viewModel = container.read(sessionViewModelProvider.notifier);
      final codingPreset = SoundscapePreset.builtInPresets.firstWhere(
        (p) => p.id == 'coding',
      );

      viewModel.selectPreset(codingPreset);

      final state = container.read(sessionViewModelProvider);
      expect(state.selectedPreset.id, 'coding');
      expect(fakeStorage.getLastPresetId(), 'coding');
    });

    test('selectDuration updates UI state', () {
      final viewModel = container.read(sessionViewModelProvider.notifier);

      viewModel.selectDuration(2700);

      final state = container.read(sessionViewModelProvider);
      expect(state.selectedDurationSeconds, 2700);
      expect(fakeStorage.getLastDurationSeconds(), 2700);
    });

    test('togglePomodoro updates UI state', () {
      final viewModel = container.read(sessionViewModelProvider.notifier);

      viewModel.togglePomodoro(true);

      final state = container.read(sessionViewModelProvider);
      expect(state.pomodoroEnabled, true);
      expect(fakeStorage.isPomodoroEnabled(), true);
    });

    test('startSession transitions state to active session', () async {
      final viewModel = container.read(sessionViewModelProvider.notifier);

      await viewModel.startSession();

      final state = container.read(sessionViewModelProvider);
      expect(state.isActive, true);
      expect(state.currentSession, isNotNull);
      expect(state.phase, SessionPhase.settling);
      expect(fakeStorage.getActiveSession(), isNotNull);
    });

    test('audio startup failure rolls back the active snapshot', () async {
      fakeAudioEngine.failStart = true;
      final viewModel = container.read(sessionViewModelProvider.notifier);

      await viewModel.startSession();

      final state = container.read(sessionViewModelProvider);
      expect(state.isActive, isFalse);
      expect(state.isLoading, isFalse);
      expect(fakeStorage.getActiveSession(), isNull);
    });

    test('pause and resume persist pause duration with the session', () async {
      final viewModel = container.read(sessionViewModelProvider.notifier);
      await viewModel.startSession();
      await viewModel.pauseSession();

      var state = container.read(sessionViewModelProvider);
      expect(state.isActive, isTrue);
      expect(state.isPaused, isTrue);
      expect(state.currentSession?.pausedAt, isNotNull);

      await viewModel.resumeSession();
      state = container.read(sessionViewModelProvider);
      expect(state.isPaused, isFalse);
      expect(state.currentSession?.pausedAt, isNull);
      expect(state.currentSession!.totalPausedSeconds, greaterThanOrEqualTo(0));
      expect(fakeStorage.getActiveSession(), isNotNull);
    });

    test(
      'denied audio focus leaves session paused and clears loading',
      () async {
        final viewModel = container.read(sessionViewModelProvider.notifier);
        await viewModel.startSession();
        await viewModel.pauseSession();
        final pausedAt = container
            .read(sessionViewModelProvider)
            .currentSession!
            .pausedAt;
        fakeAudioEngine.failResume = true;

        await viewModel.resumeSession();

        final state = container.read(sessionViewModelProvider);
        expect(state.isPaused, isTrue);
        expect(state.isLoading, isFalse);
        expect(state.currentSession?.pausedAt, pausedAt);
        expect(fakeStorage.getActiveSession()?['pausedAt'], isNotNull);
      },
    );

    test('completion cue preference persists for later sessions', () async {
      final viewModel = container.read(sessionViewModelProvider.notifier);
      await viewModel.setCompletionCueEnabled(false);
      expect(
        container.read(sessionViewModelProvider).completionCueEnabled,
        isFalse,
      );
      expect(fakeStorage.isCompletionCueEnabled(), isFalse);

      await viewModel.startSession();
      expect(
        container
            .read(sessionViewModelProvider)
            .currentSession!
            .completionCueEnabled,
        isFalse,
      );
    });

    test('stopSession resets UI state to inactive', () async {
      final viewModel = container.read(sessionViewModelProvider.notifier);

      await viewModel.startSession();
      expect(container.read(sessionViewModelProvider).isActive, true);

      await viewModel.stopSession();

      final state = container.read(sessionViewModelProvider);
      expect(state.isActive, false);
      expect(state.currentSession, null);
      expect(fakeStorage.getActiveSession(), null);
    });

    test(
      'live control changes preserve other config and persist the session',
      () async {
        final viewModel = container.read(sessionViewModelProvider.notifier);
        await viewModel.startSession();

        final original = container
            .read(sessionViewModelProvider)
            .selectedPreset
            .config;
        expect(await viewModel.updateSessionControls(intensity: 0.91), isTrue);
        expect(await viewModel.updateSessionControls(warmth: 0.27), isTrue);
        expect(await viewModel.updateSessionControls(piano: 0.73), isTrue);
        expect(
          await viewModel.updateSessionControls(beats: 0.61, bass: 0.47),
          isTrue,
        );

        final state = container.read(sessionViewModelProvider);
        final updated = state.currentSession!.preset.config;
        expect(updated.intensity, 0.91);
        expect(updated.warmth, 0.27);
        expect(updated.piano, 0.73);
        expect(updated.beats, 0.61);
        expect(updated.bass, 0.47);
        expect(updated.complexity, original.complexity);
        expect(updated.noise, original.noise);
        expect(updated.pad, original.pad);
        expect(updated.nature, original.nature);
        expect(updated.binaural, original.binaural);
        expect(updated.beatsBpm, original.beatsBpm);
        expect(state.selectedPreset.config, original);
        expect(fakeAudioEngine.configs.last, updated);

        final stored = FocusSession.fromJson(fakeStorage.getActiveSession()!);
        expect(stored.preset.id, state.selectedPreset.id);
        expect(stored.preset.config, updated);

        final restoredContainer = ProviderContainer(
          overrides: [
            localStorageRepositoryProvider.overrideWithValue(fakeStorage),
            audioEngineProvider.overrideWithValue(FakeAudioEngine()),
          ],
        );
        addTearDown(restoredContainer.dispose);
        final restoredState = restoredContainer.read(sessionViewModelProvider);
        expect(restoredState.selectedPreset.config, original);
        expect(restoredState.currentSession!.preset.config, updated);
      },
    );

    test('failed live update retains the last working config', () async {
      final viewModel = container.read(sessionViewModelProvider.notifier);
      await viewModel.startSession();
      final original = container.read(sessionViewModelProvider).selectedPreset;
      fakeAudioEngine.failConfigUpdates = true;

      expect(await viewModel.updateSessionControls(intensity: 0.99), isFalse);
      expect(container.read(sessionViewModelProvider).selectedPreset, original);
      final stored = FocusSession.fromJson(fakeStorage.getActiveSession()!);
      expect(stored.preset.config, original.config);
    });

    test('rapid control changes merge and serialize engine updates', () async {
      final viewModel = container.read(sessionViewModelProvider.notifier);
      await viewModel.startSession();
      fakeAudioEngine.updateGate = Completer<void>();

      final intensity = viewModel.updateSessionControls(intensity: 0.91);
      await Future<void>.delayed(Duration.zero);
      final warmth = viewModel.updateSessionControls(warmth: 0.27);
      final piano = viewModel.updateSessionControls(piano: 0.73);
      final beats = viewModel.updateSessionControls(beats: 0.61);
      final bass = viewModel.updateSessionControls(bass: 0.47);
      fakeAudioEngine.updateGate!.complete();

      expect(await intensity, isTrue);
      expect(await warmth, isTrue);
      expect(await piano, isTrue);
      expect(await beats, isTrue);
      expect(await bass, isTrue);
      expect(fakeAudioEngine.maxConcurrentConfigUpdates, 1);
      expect(fakeAudioEngine.configs, hasLength(2));
      expect(fakeAudioEngine.configs.last.intensity, 0.91);
      expect(fakeAudioEngine.configs.last.warmth, 0.27);
      expect(fakeAudioEngine.configs.last.piano, 0.73);
      expect(fakeAudioEngine.configs.last.beats, 0.61);
      expect(fakeAudioEngine.configs.last.bass, 0.47);
      expect(
        container.read(sessionViewModelProvider).selectedPreset.id,
        'deep_work',
      );
      expect(
        container
            .read(sessionViewModelProvider)
            .currentSession!
            .preset
            .config
            .piano,
        0.73,
      );
      expect(
        container
            .read(sessionViewModelProvider)
            .currentSession!
            .preset
            .config
            .beats,
        0.61,
      );
    });

    test(
      'stop waits for an in-flight control update before clearing snapshot',
      () async {
        final viewModel = container.read(sessionViewModelProvider.notifier);
        await viewModel.startSession();
        fakeAudioEngine.updateGate = Completer<void>();

        final update = viewModel.updateSessionControls(intensity: 0.88);
        await Future<void>.delayed(Duration.zero);
        final stop = viewModel.stopSession();
        expect(container.read(sessionViewModelProvider).isLoading, isTrue);

        fakeAudioEngine.updateGate!.complete();
        expect(await update, isTrue);
        await stop;
        await Future<void>.delayed(Duration.zero);

        expect(container.read(sessionViewModelProvider).isActive, isFalse);
        expect(fakeStorage.getActiveSession(), isNull);
      },
    );
  });
}
