import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'soundscape_config.freezed.dart';
part 'soundscape_config.g.dart';

@freezed
@HiveType(typeId: 0)
abstract class SoundscapeConfig with _$SoundscapeConfig {
  const factory SoundscapeConfig({
    @HiveField(0) @Default(0.5) double intensity,
    @HiveField(1) @Default(0.5) double warmth,
    @HiveField(2) @Default(0.5) double complexity,
    @HiveField(3) @Default(0.3) double piano,
    @HiveField(4) @Default(0.5) double noise,
    @HiveField(5) @Default(0.4) double pad,
    @HiveField(6) @Default(0.2) double nature,
    @HiveField(7) @Default(0.2) double binaural,
    @HiveField(8) @Default(0.0) double beats,
    @HiveField(9) @Default(0.0) double bass,
    @HiveField(10) @Default(72) int beatsBpm,
  }) = _SoundscapeConfig;

  factory SoundscapeConfig.fromJson(Map<String, dynamic> json) =>
      _$SoundscapeConfigFromJson(json);
}
