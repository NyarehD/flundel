import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:flundel/domain/models/soundscape_config.dart';

part 'soundscape_preset.freezed.dart';
part 'soundscape_preset.g.dart';

@freezed
@HiveType(typeId: 1)
abstract class SoundscapePreset with _$SoundscapePreset {
  // json_serializable applies nested toJson calls through Freezed's factory.
  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true)
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
        beats: 0.40,
        bass: 0.28,
        beatsBpm: 72,
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
        beats: 0.45,
        bass: 0.32,
        beatsBpm: 84,
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
        beats: 0.20,
        bass: 0.18,
        beatsBpm: 68,
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
        beats: 0.0,
        bass: 0.0,
        beatsBpm: 72,
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
        beats: 0.25,
        bass: 0.22,
        beatsBpm: 76,
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
        beats: 0.0,
        bass: 0.0,
        beatsBpm: 72,
      ),
      visualPreset: 'starfield',
    ),
    SoundscapePreset(
      id: 'ocean_drift',
      name: 'Ocean Drift',
      config: SoundscapeConfig(
        intensity: 0.5,
        warmth: 0.8,
        complexity: 0.3,
        noise: 0.4,
        pad: 0.7,
        piano: 0.1,
        binaural: 0.5,
        nature: 0.6,
        beats: 0.0,
        bass: 0.0,
        beatsBpm: 60,
      ),
      visualPreset: 'waves',
    ),
    SoundscapePreset(
      id: 'zen_meditation',
      name: 'Zen Meditation',
      config: SoundscapeConfig(
        intensity: 0.3,
        warmth: 0.9,
        complexity: 0.2,
        noise: 0.3,
        pad: 0.6,
        piano: 0.4,
        binaural: 0.6,
        nature: 0.4,
        beats: 0.15,
        bass: 0.12,
        beatsBpm: 60,
      ),
      visualPreset: 'blobs',
    ),
    SoundscapePreset(
      id: 'lofi_study',
      name: 'Lo-Fi Study',
      config: SoundscapeConfig(
        intensity: 0.6,
        warmth: 0.7,
        complexity: 0.5,
        noise: 0.6,
        pad: 0.5,
        piano: 0.4,
        binaural: 0.2,
        nature: 0.1,
        beats: 0.50,
        bass: 0.38,
        beatsBpm: 76,
      ),
      visualPreset: 'geometric_particles',
    ),
    SoundscapePreset(
      id: 'forest_stream',
      name: 'Forest Stream',
      config: SoundscapeConfig(
        intensity: 0.4,
        warmth: 0.6,
        complexity: 0.4,
        noise: 0.3,
        pad: 0.4,
        piano: 0.3,
        binaural: 0.2,
        nature: 0.8,
        beats: 0.10,
        bass: 0.10,
        beatsBpm: 64,
      ),
      visualPreset: 'waves_particles',
    ),
  ];
}
