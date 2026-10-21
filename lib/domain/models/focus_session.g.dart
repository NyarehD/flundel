// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FocusSession _$FocusSessionFromJson(Map<String, dynamic> json) =>
    _FocusSession(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      preset: SoundscapePreset.fromJson(json['preset'] as Map<String, dynamic>),
      sessionSeed: (json['sessionSeed'] as num?)?.toInt() ?? 12345,
      status:
          $enumDecodeNullable(_$SessionStatusEnumMap, json['status']) ??
          SessionStatus.active,
      isPomodoro: json['isPomodoro'] as bool? ?? false,
      pausedAt: json['pausedAt'] == null
          ? null
          : DateTime.parse(json['pausedAt'] as String),
      totalPausedSeconds: (json['totalPausedSeconds'] as num?)?.toInt() ?? 0,
      completionCueEnabled: json['completionCueEnabled'] as bool? ?? true,
    );

Map<String, dynamic> _$FocusSessionToJson(_FocusSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startedAt': instance.startedAt.toIso8601String(),
      'durationSeconds': instance.durationSeconds,
      'preset': instance.preset.toJson(),
      'sessionSeed': instance.sessionSeed,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'isPomodoro': instance.isPomodoro,
      'pausedAt': instance.pausedAt?.toIso8601String(),
      'totalPausedSeconds': instance.totalPausedSeconds,
      'completionCueEnabled': instance.completionCueEnabled,
    };

const _$SessionStatusEnumMap = {
  SessionStatus.active: 'active',
  SessionStatus.completed: 'completed',
  SessionStatus.stopped: 'stopped',
};
