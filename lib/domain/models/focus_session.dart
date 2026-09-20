import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';

part 'focus_session.freezed.dart';
part 'focus_session.g.dart';

@HiveType(typeId: 3)
enum SessionStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  completed,
  @HiveField(2)
  stopped,
}

@freezed
@HiveType(typeId: 2)
abstract class FocusSession with _$FocusSession {
  const factory FocusSession({
    @HiveField(0) required String id,
    @HiveField(1) required DateTime startedAt,
    @HiveField(2) int? durationSeconds,
    @HiveField(3) required SoundscapePreset preset,
    @HiveField(4) @Default(12345) int sessionSeed,
    @HiveField(5) @Default(SessionStatus.active) SessionStatus status,
    @HiveField(6) @Default(false) bool isPomodoro,
  }) = _FocusSession;

  factory FocusSession.fromJson(Map<String, dynamic> json) =>
      _$FocusSessionFromJson(json);
}
