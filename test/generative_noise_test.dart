import 'package:flutter_test/flutter_test.dart';
import 'package:flundel/visualization/generative/engine/noise.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/engine/visual_seed.dart';
import 'package:flundel/visualization/generative/engine/visual_state.dart';

void main() {
  group('GenerativeNoise Determinism Tests', () {
    test('same noise seed produces same value', () {
      final a = GenerativeNoise(42);
      final b = GenerativeNoise(42);

      expect(
        a.eval3D(1.25, 2.5, 3.75),
        equals(b.eval3D(1.25, 2.5, 3.75)),
      );
      expect(
        a.eval2D(0.5, 0.8),
        equals(b.eval2D(0.5, 0.8)),
      );
    });

    test('different seeds change noise field', () {
      final a = GenerativeNoise(42);
      final b = GenerativeNoise(43);

      expect(
        a.eval3D(1.25, 2.5, 3.75),
        isNot(equals(b.eval3D(1.25, 2.5, 3.75))),
      );
    });

    test('noise fields exhibit spatial continuity', () {
      final noise = GenerativeNoise(42);
      final val1 = noise.eval2D(1.0, 1.0);
      final val2 = noise.eval2D(1.01, 1.01);

      expect((val1 - val2).abs(), lessThan(0.05));
    });
  });

  group('Visual Seed & Parameter Interpolation Tests', () {
    test('GenerativeVisualSeed generates identical noise instances', () {
      const seed1 = GenerativeVisualSeed(sessionSeed: 100, patternSeed: 200);
      const seed2 = GenerativeVisualSeed(sessionSeed: 100, patternSeed: 200);

      final n1 = seed1.createNoise();
      final n2 = seed2.createNoise();

      expect(n1.eval2D(2.0, 3.0), equals(n2.eval2D(2.0, 3.0)));
    });

    test('VisualParameters lerp interpolates smoothly', () {
      const p1 = VisualParameters(energy: 0.2, speed: 0.2);
      const p2 = VisualParameters(energy: 0.8, speed: 0.8);

      final interpolated = p1.lerp(p2, 0.5);

      expect(interpolated.energy, closeTo(0.5, 0.001));
      expect(interpolated.speed, closeTo(0.5, 0.001));
    });

    test('AudioVisualState applies metrics to parameters', () {
      const audioState = AudioVisualState(
        intensity: 0.8,
        density: 0.7,
        brightness: 0.9,
      );

      final adjusted = audioState.applyToParameters(VisualParameters.focus);

      expect(adjusted.energy, greaterThan(VisualParameters.focus.energy));
      expect(adjusted.brightness, greaterThan(VisualParameters.focus.brightness));
    });
  });
}
