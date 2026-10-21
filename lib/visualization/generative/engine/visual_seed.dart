import 'dart:math' as math;

import 'package:flundel/visualization/generative/engine/noise.dart';

/// Seed object ensuring reproducible generative patterns across sessions.
class GenerativeVisualSeed {
  final int sessionSeed;
  final int patternSeed;

  const GenerativeVisualSeed({
    required this.sessionSeed,
    required this.patternSeed,
  });

  factory GenerativeVisualSeed.random([math.Random? random]) {
    final rand = random ?? math.Random();
    return GenerativeVisualSeed(
      sessionSeed: rand.nextInt(1000000),
      patternSeed: rand.nextInt(1000000),
    );
  }

  factory GenerativeVisualSeed.fromPreset(String presetId, [int session = 42]) {
    final pattern = presetId.hashCode.abs() % 100000;
    return GenerativeVisualSeed(
      sessionSeed: session,
      patternSeed: pattern,
    );
  }

  int get combinedSeed => (sessionSeed * 31 + patternSeed) & 0x7FFFFFFF;

  GenerativeNoise createNoise([int offset = 0]) {
    return GenerativeNoise((combinedSeed + offset) & 0x7FFFFFFF);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenerativeVisualSeed &&
          runtimeType == other.runtimeType &&
          sessionSeed == other.sessionSeed &&
          patternSeed == other.patternSeed;

  @override
  int get hashCode => sessionSeed.hashCode ^ patternSeed.hashCode;
}
