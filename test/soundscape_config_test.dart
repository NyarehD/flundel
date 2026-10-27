import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(config.wind, 0.0);
    expect(config.water, 0.0);
    expect(config.birds, 0.0);
    expect(config.chimes, 0.0);
    expect(config.gentlePulses, isFalse);
  });

  test('built-in presets retain tempo and independent rhythm levels', () {
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
      expect(
        preset.config.gentlePulses,
        {'deep_work', 'coding'}.contains(preset.id),
        reason: preset.id,
      );
      expect(preset.config.beatsBpm, bpm, reason: preset.id);
      expect(preset.config.beats, beats, reason: preset.id);
      expect(preset.config.bass, bass, reason: preset.id);
    }
  });

  test('new sound controls survive JSON round trips', () {
    const config = SoundscapeConfig(
      beats: 0.63,
      bass: 0.41,
      beatsBpm: 84,
      wind: 0.2,
      water: 0.3,
      birds: 0.15,
      chimes: 0.1,
      gentlePulses: true,
    );

    expect(SoundscapeConfig.fromJson(config.toJson()), config);
  });

  test('built-in soundscapes use the planned ambience palette', () {
    final presets = {
      for (final preset in SoundscapePreset.builtInPresets) preset.id: preset,
    };
    final expectedSources = <String, Set<String>>{
      'deep_work': {'wind', 'chimes'},
      'coding': {'wind', 'chimes'},
      'reading': {'water', 'birds'},
      'quiet_focus': {'wind'},
      'piano_focus': {'chimes'},
      'night_focus': {'wind', 'water'},
      'ocean_drift': {'wind', 'water'},
      'zen_meditation': {'water', 'chimes'},
      'lofi_study': {'wind', 'chimes'},
      'forest_stream': {'wind', 'water', 'birds'},
    };

    expect(presets.keys, unorderedEquals(expectedSources.keys));
    for (final entry in expectedSources.entries) {
      final config = presets[entry.key]!.config;
      final levels = {
        'wind': config.wind,
        'water': config.water,
        'birds': config.birds,
        'chimes': config.chimes,
      };
      expect(
        levels.entries.where((layer) => layer.value > 0).map((e) => e.key),
        unorderedEquals(entry.value),
        reason: entry.key,
      );
    }
  });
}
