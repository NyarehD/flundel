import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'soundscape_config.freezed.dart';
part 'soundscape_config.g.dart';

@freezed
@HiveType(typeId: 0)
@JsonSerializable()
class SoundscapeConfig with _$SoundscapeConfig {
  const SoundscapeConfig({
    @HiveField(0) this.intensity = 0.5,
    @HiveField(1) this.warmth = 0.5,
    @HiveField(2) this.complexity = 0.5,
    @HiveField(3) this.piano = 0.3,
    @HiveField(4) this.noise = 0.5,
    @HiveField(5) this.pad = 0.4,
    @HiveField(6) this.nature = 0.2,
    @HiveField(7) this.binaural = 0.2,
    @HiveField(8) this.beats = 0.0,
    @HiveField(9) this.bass = 0.0,
    @HiveField(10) this.beatsBpm = 72,
    @HiveField(11) this.wind = 0.0,
    @HiveField(12) this.water = 0.0,
    @HiveField(13) this.birds = 0.0,
    @HiveField(14) this.chimes = 0.0,
    @HiveField(15) this.gentlePulses = false,
  });

  final double intensity;
  final double warmth;
  final double complexity;
  final double piano;
  final double noise;
  final double pad;
  final double nature;
  final double binaural;
  final double beats;
  final double bass;
  final int beatsBpm;
  final double wind;
  final double water;
  final double birds;
  final double chimes;
  final bool gentlePulses;

  factory SoundscapeConfig.fromJson(Map<String, dynamic> json) =>
      _$SoundscapeConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SoundscapeConfigToJson(this);
}
