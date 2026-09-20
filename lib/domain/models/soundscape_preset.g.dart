// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'soundscape_preset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SoundscapePreset _$SoundscapePresetFromJson(Map<String, dynamic> json) =>
    _SoundscapePreset(
      id: json['id'] as String,
      name: json['name'] as String,
      config: SoundscapeConfig.fromJson(json['config'] as Map<String, dynamic>),
      visualPreset: json['visualPreset'] as String? ?? 'particles_waves',
    );

Map<String, dynamic> _$SoundscapePresetToJson(_SoundscapePreset instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'config': instance.config,
      'visualPreset': instance.visualPreset,
    };
