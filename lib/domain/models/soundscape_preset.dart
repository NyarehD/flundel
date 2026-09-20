import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:flundel/domain/models/soundscape_config.dart';

part 'soundscape_preset.freezed.dart';
part 'soundscape_preset.g.dart';

@freezed
@HiveType(typeId: 1)
abstract class SoundscapePreset with _$SoundscapePreset {
  const factory SoundscapePreset({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required SoundscapeConfig config,
    @HiveField(3) @Default('particles_waves') String visualPreset,
  }) = _SoundscapePreset;

  factory SoundscapePreset.fromJson(Map<String, dynamic> json) =>
      _$SoundscapePresetFromJson(json);

  static List<SoundscapePreset> get builtInPresets => const [
        SoundscapePreset(
          id: 'deep_work',
          name: 'Deep Work',
          config: SoundscapeConfig(
            intensity: 0.7,
            warmth: 0.6,
            complexity: 0.3,
            noise: 0.7,
            pad: 0.5,
            piano: 0.2,
            binaural: 0.4,
            nature: 0.2,
          ),
          visualPreset: 'waves_particles',
        ),
        SoundscapePreset(
          id: 'coding',
          name: 'Coding',
          config: SoundscapeConfig(
            intensity: 0.6,
            warmth: 0.5,
            complexity: 0.6,
            noise: 0.5,
            pad: 0.6,
            piano: 0.3,
            binaural: 0.3,
            nature: 0.1,
          ),
          visualPreset: 'geometric_particles',
        ),
        SoundscapePreset(
          id: 'reading',
          name: 'Reading',
          config: SoundscapeConfig(
            intensity: 0.4,
            warmth: 0.7,
            complexity: 0.4,
            noise: 0.4,
            pad: 0.4,
            piano: 0.5,
            binaural: 0.1,
            nature: 0.5,
          ),
          visualPreset: 'blobs',
        ),
        SoundscapePreset(
          id: 'quiet_focus',
          name: 'Quiet Focus',
          config: SoundscapeConfig(
            intensity: 0.3,
            warmth: 0.5,
            complexity: 0.1,
            noise: 0.8,
            pad: 0.2,
            piano: 0.1,
            binaural: 0.1,
            nature: 0.1,
          ),
          visualPreset: 'waves',
        ),
        SoundscapePreset(
          id: 'piano_focus',
          name: 'Piano Focus',
          config: SoundscapeConfig(
            intensity: 0.5,
            warmth: 0.8,
            complexity: 0.5,
            noise: 0.2,
            pad: 0.5,
            piano: 0.8,
            binaural: 0.1,
            nature: 0.2,
          ),
          visualPreset: 'blobs',
        ),
        SoundscapePreset(
          id: 'night_focus',
          name: 'Night Focus',
          config: SoundscapeConfig(
            intensity: 0.2,
            warmth: 0.9,
            complexity: 0.2,
            noise: 0.5,
            pad: 0.7,
            piano: 0.2,
            binaural: 0.2,
            nature: 0.1,
          ),
          visualPreset: 'starfield',
        ),
      ];
}
