import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract interface class LocalStorageRepository {
  String getLastPresetId();
  Future<void> setLastPresetId(String presetId);

  int? getLastDurationSeconds();
  Future<void> setLastDurationSeconds(int? seconds);

  bool isPomodoroEnabled();
  Future<void> setPomodoroEnabled(bool enabled);

  bool isCompletionCueEnabled();
  Future<void> setCompletionCueEnabled(bool enabled);

  Future<void> saveActiveSession(Map<String, dynamic> sessionJson);
  Map<String, dynamic>? getActiveSession();
  Future<void> clearActiveSession();
}

class HiveLocalStorageRepository implements LocalStorageRepository {
  static const String _settingsBoxName = 'flundel_settings';
  static const String _sessionBoxName = 'flundel_session';

  static const String _keyLastPresetId = 'last_preset_id';
  static const String _keyLastDuration = 'last_duration_seconds';
  static const String _keyPomodoroEnabled = 'pomodoro_enabled';
  static const String _keyCompletionCueEnabled = 'completion_cue_enabled';
  static const String _keyActiveSession = 'active_session_json';

  Box get _settingsBox => Hive.box(_settingsBoxName);
  Box get _sessionBox => Hive.box(_sessionBoxName);

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsBoxName);
    await Hive.openBox(_sessionBoxName);
  }

  @override
  String getLastPresetId() {
    return _settingsBox.get(_keyLastPresetId, defaultValue: 'deep_work');
  }

  @override
  Future<void> setLastPresetId(String presetId) async {
    await _settingsBox.put(_keyLastPresetId, presetId);
  }

  @override
  int? getLastDurationSeconds() {
    return _settingsBox.get(_keyLastDuration, defaultValue: 1500) as int?;
  }

  @override
  Future<void> setLastDurationSeconds(int? seconds) async {
    await _settingsBox.put(_keyLastDuration, seconds);
  }

  @override
  bool isPomodoroEnabled() {
    return _settingsBox.get(_keyPomodoroEnabled, defaultValue: false) as bool;
  }

  @override
  Future<void> setPomodoroEnabled(bool enabled) async {
    await _settingsBox.put(_keyPomodoroEnabled, enabled);
  }

  @override
  bool isCompletionCueEnabled() =>
      _settingsBox.get(_keyCompletionCueEnabled, defaultValue: true) as bool;

  @override
  Future<void> setCompletionCueEnabled(bool enabled) async {
    await _settingsBox.put(_keyCompletionCueEnabled, enabled);
  }

  @override
  Future<void> saveActiveSession(Map<String, dynamic> sessionJson) async {
    await _sessionBox.put(_keyActiveSession, jsonEncode(sessionJson));
  }

  @override
  Map<String, dynamic>? getActiveSession() {
    final jsonStr = _sessionBox.get(_keyActiveSession) as String?;
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearActiveSession() async {
    await _sessionBox.delete(_keyActiveSession);
  }
}

final localStorageRepositoryProvider = Provider<LocalStorageRepository>((ref) {
  return HiveLocalStorageRepository();
});
