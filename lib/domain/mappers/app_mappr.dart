import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';

import 'app_mappr.auto_mappr.dart';

class CustomPresetDto {
  final String id;
  final String name;
  final double intensity;
  final double warmth;
  final double complexity;
  final double piano;
  final double noise;
  final double pad;
  final double nature;
  final double binaural;

  CustomPresetDto({
    required this.id,
    required this.name,
    required this.intensity,
    required this.warmth,
    required this.complexity,
    required this.piano,
    required this.noise,
    required this.pad,
    required this.nature,
    required this.binaural,
  });
}

@AutoMappr([
  MapType<CustomPresetDto, SoundscapePreset>(
    fields: [
      Field('config', custom: AppMappr.configFromDto),
      Field('visualPreset', custom: AppMappr.defaultVisual),
    ],
  ),
])
class AppMappr extends $AppMappr {
  static SoundscapeConfig configFromDto(CustomPresetDto dto) {
    return SoundscapeConfig(
      intensity: dto.intensity,
      warmth: dto.warmth,
      complexity: dto.complexity,
      piano: dto.piano,
      noise: dto.noise,
      pad: dto.pad,
      nature: dto.nature,
      binaural: dto.binaural,
    );
  }

  static String defaultVisual(CustomPresetDto dto) => 'waves_particles';
}
