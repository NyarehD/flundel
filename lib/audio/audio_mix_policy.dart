import 'dart:math' as math;

import 'package:flundel/audio/procedural/harmony_controller.dart';
import 'package:flundel/domain/models/soundscape_config.dart';

/// Shared production gain staging for source-calibrated -24 dBFS bed assets.
class AudioMixPolicy {
  static const double textureNoiseGain = 0.22;
  static const double natureGain = 0.28;
  static const double padGain = 0.90;
  static const double pianoVoiceGain = 0.9;
  static const double beatsGain = 0.66;
  static const double bassGain = 0.72;
  static const int maxPianoVoices = 8;

  static double noiseLevel(SoundscapeConfig config) =>
      config.noise * textureNoiseGain;

  static double natureLevel(SoundscapeConfig config) =>
      config.nature * natureGain;

  static double padLevel(SoundscapeConfig config) => config.pad * padGain;

  static double pianoLevel(SoundscapeConfig config) =>
      config.piano * config.intensity * pianoVoiceGain;

  static double binauralBeatHz(SoundscapeConfig config) {
    if (config.warmth >= 0.85 && config.intensity <= 0.3) return 2.0; // Delta
    if (config.warmth >= 0.75 || (config.binaural >= 0.5 && config.intensity <= 0.5)) return 6.0; // Theta
    if (config.complexity >= 0.55 && config.intensity >= 0.55) return 14.0; // Beta
    return 10.0; // Alpha
  }

  static Duration phraseSpacing(math.Random random, SoundscapeConfig config) {
    final baseMs = config.piano >= 0.65 ? 520 : 650;
    final pianoVariation = ((1 - config.piano.clamp(0.0, 1.0)) * 100).round();
    return Duration(milliseconds: baseMs + random.nextInt(pianoVariation + 1));
  }

  static double pianoPhraseVelocity(int noteIndex, int phraseLength) {
    if (phraseLength <= 1) return 0.75;
    final position = noteIndex / (phraseLength - 1);
    return 0.68 + 0.30 * math.sin(position * math.pi);
  }

  static int phraseNoteCount(SoundscapeConfig config) {
    if (config.piano >= 0.65) return 5;
    if (config.piano <= 0.12 && config.noise >= 0.75) return 3;
    return 4;
  }

  static List<double> createPhraseFrequencies({
    required ChordInfo chord,
    required math.Random random,
    required int noteCount,
  }) {
    final pool =
        <double>{...chord.chordFrequencies, ...chord.passingFrequencies}.map((
          frequency,
        ) {
          var result = frequency;
          while (result < 390) {
            result *= 2;
          }
          while (result > 988) {
            result /= 2;
          }
          return result;
        }).toList()..sort();
    if (pool.isEmpty) return const [];
    var index = random.nextInt(pool.length);
    final notes = <double>[pool[index]];
    for (var i = 1; i < noteCount; i++) {
      final movement = random.nextInt(4) - 2;
      index = (index + (movement == 0 ? 1 : movement)).clamp(
        0,
        pool.length - 1,
      );
      notes.add(pool[index]);
    }
    return notes;
  }

  static Duration nextPianoDelay({
    required math.Random random,
    required bool firstNote,
    required SoundscapeConfig config,
    required double focusDepth,
  }) {
    if (firstNote) return Duration(seconds: 2 + random.nextInt(3));
    final complexity = config.complexity.clamp(0.0, 1.0);
    final focus = focusDepth.clamp(0.0, 1.0);
    final minimum = config.piano <= 0.12 && config.noise >= 0.75
        ? 22 + (focus * 4).round()
        : config.piano >= 0.65
        ? 5 + (focus * 2).round()
        : 7 + (focus * 4).round() - (complexity * 2).round();
    final maximum = minimum + (config.piano >= 0.65 ? 2 : 4);
    return Duration(
      seconds: minimum + random.nextInt(math.max(1, maximum - minimum + 1)),
    );
  }
}
