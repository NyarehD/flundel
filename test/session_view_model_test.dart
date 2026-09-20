import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flundel/audio/audio_analysis.dart';
import 'package:flundel/audio/audio_engine.dart';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';
import 'package:flundel/session/session_phase.dart';
import 'package:flundel/session/session_view_model.dart';
import 'package:flundel/storage/local_storage.dart';

class FakeLocalStorageRepository implements LocalStorageRepository {
  String _presetId = 'deep_work';
  int? _durationSeconds = 1500;
  bool _pomodoro = false;
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

  @override
  Future<void> initialize() async {}

  @override
  Future<void> start(SoundscapeConfig config) async {
    _stateController.add(AudioEngineState.playing);
  }

  @override
  Future<void> updateConfig(SoundscapeConfig config) async {}

  @override
  Future<void> stop() async {
    _stateController.add(AudioEngineState.stopped);
  }

  @override
  Stream<AudioAnalysis> get analysisStream => _analysisController.stream;

  @override
  Stream<AudioEngineState> get stateStream => _stateController.stream;
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
      final codingPreset = SoundscapePreset.builtInPresets
          .firstWhere((p) => p.id == 'coding');

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
  });
}
