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
@JsonSerializable(explicitToJson: true)
class FocusSession with _$FocusSession {
  const FocusSession({
    @HiveField(0) required this.id,
    @HiveField(1) required this.startedAt,
    @HiveField(2) this.durationSeconds,
    @HiveField(3) required this.preset,
    @HiveField(4) this.sessionSeed = 12345,
    @HiveField(5) this.status = SessionStatus.active,
    @HiveField(6) this.isPomodoro = false,
    @HiveField(7) this.pausedAt,
    @HiveField(8) this.totalPausedSeconds = 0,
    @HiveField(9) this.completionCueEnabled = true,
  });

  final String id;
  final DateTime startedAt;
  final int? durationSeconds;
  final SoundscapePreset preset;
  final int sessionSeed;
  final SessionStatus status;
  final bool isPomodoro;
  final DateTime? pausedAt;
  final int totalPausedSeconds;
  final bool completionCueEnabled;

  factory FocusSession.fromJson(Map<String, dynamic> json) =>
      _$FocusSessionFromJson(json);

  Map<String, dynamic> toJson() => _$FocusSessionToJson(this);
}
