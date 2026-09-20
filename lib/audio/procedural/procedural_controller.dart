import 'dart:math';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flundel/audio/dsp/smoothed_value.dart';
import 'package:flundel/audio/procedural/harmony_controller.dart';
import 'package:flundel/audio/procedural/piano_scheduler.dart';
import 'package:flundel/audio/procedural/variation_budget.dart';

class ProceduralController {
  late Random _random;
  int _sessionSeed = 42;

  final HarmonyController harmonyController = HarmonyController();
  final PianoScheduler pianoScheduler = PianoScheduler();
  final VariationBudget variationBudget = VariationBudget();

  final SmoothedValue focusDepth = SmoothedValue(0.30, smoothingDurationSeconds: 5.0);

  double _timeSinceLastChordChange = 0.0;

  // Micro-variation parameter states
  double padDetuneCents = 2.0;
  double noiseCutoffHz = 1200.0;
  double stereoWidth = 0.8;

  void initialize(int sessionSeed, SoundscapeConfig initialConfig) {
    _sessionSeed = sessionSeed;
    _random = Random(_sessionSeed);
    pianoScheduler.reset();
    variationBudget.reset();
    _timeSinceLastChordChange = 0.0;

    // Set initial focus depth based on config / phase default
    focusDepth.setImmediate((0.3 + initialConfig.intensity * 0.2).clamp(0.0, 1.0));
  }

  void setFocusDepth(double depth) {
    focusDepth.setTarget(depth.clamp(0.0, 1.0), durationSeconds: 4.0);
  }

  /// Process procedural tick at control rate (e.g. deltaTimeSeconds = 0.02 - 0.10s).
  void tick(double deltaTimeSeconds, SoundscapeConfig config) {
    focusDepth.tick(deltaTimeSeconds);

    // 1. Harmony progression timing (Deep Focus -> longer chord hold time 16-30s)
    _timeSinceLastChordChange += deltaTimeSeconds;
    final targetChordHold = 10.0 + (focusDepth.value * 18.0) + (_random.nextDouble() * 4.0);

    if (_timeSinceLastChordChange >= targetChordHold) {
      if (variationBudget.requestTransition('harmony')) {
        harmonyController.transitionNextChord(_random);
        _timeSinceLastChordChange = 0.0;
        variationBudget.releaseTransition('harmony');
      }
    }

    // 2. Micro-variations (slow continuous parameter drifting)
    final depth = focusDepth.value;
    stereoWidth = (0.9 - depth * 0.4).clamp(0.3, 0.95); // Deep focus reduces stereo movement
    noiseCutoffHz = 800.0 + (config.warmth * 600.0) + (sin(deltaTimeSeconds * 0.1) * 50.0);
    padDetuneCents = 1.0 + (1.0 - depth) * 3.0; // Less detune modulation in deep focus
  }

  PianoNoteEvent? checkAndGeneratePianoEvent({
    required double currentTimeSeconds,
    required SoundscapeConfig config,
  }) {
    final shouldPlay = pianoScheduler.shouldTriggerNote(
      currentTimeSeconds: currentTimeSeconds,
      pianoLevel: config.piano,
      focusDepth: focusDepth.value,
      random: _random,
    );

    if (!shouldPlay) return null;

    return pianoScheduler.generateNote(
      harmonyController: harmonyController,
      focusDepth: focusDepth.value,
      pianoLevel: config.piano,
      random: _random,
      currentTimeSeconds: currentTimeSeconds,
    );
  }
}
