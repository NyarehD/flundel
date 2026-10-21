import 'package:flutter_test/flutter_test.dart';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';

void main() {
  test('legacy config JSON defaults new layers to silent at default tempo', () {
    final config = SoundscapeConfig.fromJson({
      'intensity': 0.7,
      'warmth': 0.6,
      'complexity': 0.3,
      'piano': 0.2,
      'noise': 0.7,
      'pad': 0.5,
      'nature': 0.2,
      'binaural': 0.4,
    });

    expect(config.beats, 0.0);
    expect(config.bass, 0.0);
    expect(config.beatsBpm, 72);
  });

  test('built-in presets carry the agreed lo-fi groove defaults', () {
    final expected = <String, (int, double, double)>{
      'deep_work': (72, 0.40, 0.28),
      'coding': (84, 0.45, 0.32),
      'reading': (68, 0.20, 0.18),
      'piano_focus': (76, 0.25, 0.22),
      'quiet_focus': (72, 0.0, 0.0),
      'night_focus': (72, 0.0, 0.0),
      'ocean_drift': (60, 0.0, 0.0),
      'zen_meditation': (60, 0.15, 0.12),
      'lofi_study': (76, 0.50, 0.38),
      'forest_stream': (64, 0.10, 0.10),
    };

    for (final preset in SoundscapePreset.builtInPresets) {
      final (bpm, beats, bass) = expected[preset.id]!;
      expect(preset.config.beatsBpm, bpm, reason: preset.id);
      expect(preset.config.beats, beats, reason: preset.id);
      expect(preset.config.bass, bass, reason: preset.id);
    }
  });

  test('new sound controls survive JSON round trips', () {
    const config = SoundscapeConfig(beats: 0.63, bass: 0.41, beatsBpm: 84);

    expect(SoundscapeConfig.fromJson(config.toJson()), config);
  });
}
