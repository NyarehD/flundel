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
    };
