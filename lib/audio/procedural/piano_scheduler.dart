import 'dart:math';

import 'package:flundel/audio/procedural/harmony_controller.dart';

class PianoNoteEvent {

  const PianoNoteEvent({
    required this.frequencyHz,
    required this.velocity,
    required this.durationSeconds,
  });
  final double frequencyHz;
  final double velocity;
  final double durationSeconds;
}

class PianoScheduler {
  static const int maxPolyphony = 8;
  static const double minSilenceGapSeconds = 1.2;

  double _lastNoteTimeSeconds = -10.0;
  double _lastFrequencyHz = 261.63;
  double _nextScheduledGapSeconds = 3.0;

  int _activeVoiceCount = 0;
  int get activeVoiceCount => _activeVoiceCount;

  void onVoiceStarted() {
    _activeVoiceCount = min(maxPolyphony, _activeVoiceCount + 1);
  }

  void onVoiceFinished() {
    _activeVoiceCount = max(0, _activeVoiceCount - 1);
  }

  void reset() {
    _activeVoiceCount = 0;
    _lastNoteTimeSeconds = -10.0;
  }

  /// Determines whether a new piano note should trigger at [currentTimeSeconds]
  /// based on piano gain, focusDepth, and musical density rules.
  bool shouldTriggerNote({
    required double currentTimeSeconds,
    required double pianoLevel,
    required double focusDepth,
    required Random random,
  }) {
    if (pianoLevel < 0.05) return false;

    final timeSinceLastNote = currentTimeSeconds - _lastNoteTimeSeconds;
    if (timeSinceLastNote < minSilenceGapSeconds) return false;

    if (timeSinceLastNote >= _nextScheduledGapSeconds) {
      // Calculate next gap interval: Deep focus -> sparse (4s - 14s), Settling -> active (2s - 6s)
      final minGap = 2.0 + (focusDepth * 4.0) / max(0.1, pianoLevel);
      final maxGap = 5.0 + (focusDepth * 10.0) / max(0.1, pianoLevel);
      _nextScheduledGapSeconds =
          minGap + random.nextDouble() * (maxGap - minGap);
      return true;
    }

    return false;
  }

  /// Generates a musically constrained piano note event.
  PianoNoteEvent generateNote({
    required HarmonyController harmonyController,
    required double focusDepth,
    required double pianoLevel,
    required Random random,
    required double currentTimeSeconds,
  }) {
    _lastNoteTimeSeconds = currentTimeSeconds;

    final chord = harmonyController.currentChord;
    final useChordTone = random.nextDouble() < 0.85;

    final candidates = useChordTone
        ? chord.chordFrequencies
        : chord.passingFrequencies;

    // Filter candidates to avoid large interval jumps (> 1.5 octaves) and repeated identical notes
    double chosenFreq = candidates[random.nextInt(candidates.length)];
    if ((chosenFreq / _lastFrequencyHz - 1.0).abs() > 0.8 &&
        candidates.length > 1) {
      final alternate = candidates
          .where(
            (f) =>
                (f - _lastFrequencyHz).abs() <
                (chosenFreq - _lastFrequencyHz).abs(),
          )
          .toList();
      if (alternate.isNotEmpty) {
        chosenFreq = alternate[random.nextInt(alternate.length)];
      }
    }

    // Octave shift variation (subtle)
    if (random.nextDouble() < 0.2) {
      chosenFreq *= (random.nextBool()
          ? 1.5
          : 0.75); // Perfect fifth or octave transition
    }

    _lastFrequencyHz = chosenFreq;

    // Velocity jitter (low & soft for focus soundscape: 0.20 - 0.38)
    final velocity = (0.20 + random.nextDouble() * 0.15 * pianoLevel).clamp(
      0.10,
      0.45,
    );
    final duration = 2.0 + random.nextDouble() * 2.5;

    return PianoNoteEvent(
      frequencyHz: chosenFreq,
      velocity: velocity,
      durationSeconds: duration,
    );
  }
}
