// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'soundscape_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SoundscapeConfig _$SoundscapeConfigFromJson(Map<String, dynamic> json) =>
    _SoundscapeConfig(
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.5,
      warmth: (json['warmth'] as num?)?.toDouble() ?? 0.5,
      complexity: (json['complexity'] as num?)?.toDouble() ?? 0.5,
      piano: (json['piano'] as num?)?.toDouble() ?? 0.3,
      noise: (json['noise'] as num?)?.toDouble() ?? 0.5,
      pad: (json['pad'] as num?)?.toDouble() ?? 0.4,
      nature: (json['nature'] as num?)?.toDouble() ?? 0.2,
      binaural: (json['binaural'] as num?)?.toDouble() ?? 0.2,
      beats: (json['beats'] as num?)?.toDouble() ?? 0.0,
      bass: (json['bass'] as num?)?.toDouble() ?? 0.0,
      beatsBpm: (json['beatsBpm'] as num?)?.toInt() ?? 72,
    );

Map<String, dynamic> _$SoundscapeConfigToJson(_SoundscapeConfig instance) =>
    <String, dynamic>{
      'intensity': instance.intensity,
      'warmth': instance.warmth,
      'complexity': instance.complexity,
      'piano': instance.piano,
      'noise': instance.noise,
      'pad': instance.pad,
      'nature': instance.nature,
      'binaural': instance.binaural,
      'beats': instance.beats,
      'bass': instance.bass,
      'beatsBpm': instance.beatsBpm,
    };
