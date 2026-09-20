import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flundel/domain/models/focus_session.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';
import 'package:flundel/session/session_phase.dart';

part 'session_state.freezed.dart';

@freezed
abstract class SessionState with _$SessionState {
  const factory SessionState({
    @Default(false) bool isActive,
    @Default(false) bool isLoading,
    FocusSession? currentSession,
    @Default(0) int elapsedSeconds,
    int? remainingSeconds, // null if "No End"
    @Default(SessionPhase.settling) SessionPhase phase,
    required SoundscapePreset selectedPreset,
    int? selectedDurationSeconds, // null if "No End"
    @Default(false) bool pomodoroEnabled,
  }) = _SessionState;
}
