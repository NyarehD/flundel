import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flundel/audio/dsp/audio_bus.dart';
import 'package:flundel/audio/dsp/binaural_generator.dart';
import 'package:flundel/audio/dsp/environmental_layer.dart';
import 'package:flundel/audio/dsp/noise_engine.dart';
import 'package:flundel/audio/dsp/pad_synth.dart';
import 'package:flundel/audio/dsp/smoothed_value.dart';
import 'package:flundel/audio/procedural/harmony_controller.dart';
import 'package:flundel/audio/procedural/piano_scheduler.dart';
import 'package:flundel/audio/procedural/procedural_controller.dart';
import 'package:flundel/audio/procedural/variation_budget.dart';
import 'package:flundel/audio/synthetic_audio.dart';
import 'package:flundel/audio/tools/offline_renderer.dart';
import 'package:flundel/domain/models/soundscape_config.dart';

void main() {
  group('Audio Engine Refinement Tests', () {
    test('SmoothedValue smoothly interpolates without instant jumps', () {
      final param = SmoothedValue(0.2, smoothingDurationSeconds: 1.0);
      expect(param.value, equals(0.2));

      param.setTarget(0.8);
      expect(param.value, equals(0.2)); // No instant jump!

      // Step halfway (0.5s)
      final valHalf = param.tick(0.5);
      expect(valHalf, greaterThan(0.2));
      expect(valHalf, lessThan(0.8));

      // Step to end (0.5s more)
      final valEnd = param.tick(0.5);
      expect(valEnd, equals(0.8));
      expect(param.isComplete, isTrue);
    });

    test('ProceduralController clamps and maps focusDepth correctly', () {
      final procedural = ProceduralController();
      procedural.initialize(12345, const SoundscapeConfig());

      procedural.setFocusDepth(1.5); // Should clamp to 1.0
      procedural.tick(10.0, const SoundscapeConfig());
      expect(procedural.focusDepth.value, lessThanOrEqualTo(1.0));

      procedural.setFocusDepth(-0.5); // Should clamp to 0.0
      procedural.tick(10.0, const SoundscapeConfig());
      expect(procedural.focusDepth.value, greaterThanOrEqualTo(0.0));
    });

    test('HarmonyController transitions only among valid harmonic vocabulary', () {
      final harmony = HarmonyController();
      final random = Random(42);

      final validChords = {'Am7', 'Cmaj7', 'Fmaj7', 'Em7', 'Dm7', 'Am9', 'Cmaj9', 'Fmaj7#11'};

      for (int i = 0; i < 50; i++) {
        final next = harmony.transitionNextChord(random);
        expect(validChords.contains(next.name), isTrue);
        expect(next.chordFrequencies.isNotEmpty, isTrue);
      }
    });

    test('PadSynth generates valid multi-harmonic stereo WAV bytes', () {
      final pad = PadSynth();
      pad.updateParameters(padLevel: 0.8, detune: 3.0, reverbSendLevel: 0.4, cutoffFrequencyHz: 1500.0);

      final wavBytes = pad.generatePadWavBytes(
        baseFrequencies: [220.0, 261.63, 329.63, 392.00],
        durationSeconds: 1.0,
        sampleRate: 48000,
      );

      expect(wavBytes.length, equals(44 + 48000 * 4)); // Header + 1s stereo 16-bit
    });

    test('NoiseEngine generates resonant biquad filtered noise WAV bytes', () {
      final noise = NoiseEngine();
      noise.updateParameters(noiseLevel: 0.5, warmthValue: 0.7, cutoffFrequencyHz: 1000.0);

      final wavBytes = noise.generateWavBytes(durationSeconds: 1.0, sampleRate: 48000);
      expect(wavBytes.length, equals(44 + 48000 * 4));
    });

    test('BinauralGenerator generates stereo binaural WAV bytes', () {
      final binaural = BinauralGenerator();
      binaural.updateParameters(level: 0.6, carrierFrequency: 180.0, differenceHz: 10.0);

      final wavBytes = binaural.generateBinauralWavBytes(durationSeconds: 1.0, sampleRate: 48000);
      expect(wavBytes.length, equals(44 + 48000 * 4));
    });

    test('EnvironmentalLayer generates realistic rain/wind ambience WAV bytes', () {
      final env = EnvironmentalLayer();
      env.updateParameters(natureLevel: 0.8);

      final wavBytes = env.generateRainWavBytes(durationSeconds: 1.0, sampleRate: 48000);
      expect(wavBytes.length, equals(44 + 48000 * 4));
    });

    test('SyntheticAudio generates physical modeling chime WAV bytes', () {
      final chimeBytes = SyntheticAudio.createTranquilChimeWavBytes(
        freqHz: 523.25,
        durationSeconds: 1.5,
        sampleRate: 48000,
      );

      expect(chimeBytes.length, equals(44 + (48000 * 1.5).toInt() * 4));
    });

    test('PianoScheduler enforces minimum silence gap and polyphony limits', () {
      final scheduler = PianoScheduler();
      final random = Random(99);

      // Trigger first note
      final play1 = scheduler.shouldTriggerNote(
        currentTimeSeconds: 0.0,
        pianoLevel: 0.5,
        focusDepth: 0.5,
        random: random,
      );
      expect(play1, isTrue);

      // Immediately checking 0.1s later should return false due to minimum gap rule
      final playImmediate = scheduler.shouldTriggerNote(
        currentTimeSeconds: 0.1,
        pianoLevel: 0.5,
        focusDepth: 0.5,
        random: random,
      );
      expect(playImmediate, isFalse);

      // Polyphony limit check
      for (int i = 0; i < 10; i++) {
        scheduler.onVoiceStarted();
      }
      expect(scheduler.activeVoiceCount, equals(8)); // Capped at max 8
    });

    test('VariationBudget restricts simultaneous macro transitions', () {
      final budget = VariationBudget(maxSimultaneousTransitions: 2);

      expect(budget.requestTransition('t1'), isTrue);
      expect(budget.requestTransition('t2'), isTrue);
      expect(budget.requestTransition('t3'), isFalse); // Budget exceeded!

      budget.releaseTransition('t1');
      expect(budget.requestTransition('t3'), isTrue); // Allowed now
    });

    test('AudioBus master limiter prevents clipping above ceiling', () {
      final bus = AudioBus();

      final normalPeak = bus.applyMasterLimiter(0.4);
      expect(normalPeak, closeTo(0.36, 1e-4)); // 0.4 * 0.9 master volume

      final extremePeak = bus.applyMasterLimiter(5.0); // Excessive raw peak
      expect(extremePeak, lessThanOrEqualTo(AudioBus.masterLimiterCeiling)); // Safe ceiling!
    });

    test('OfflineRenderer successfully generates valid WAV buffer', () {
      final result = OfflineRenderer.renderAudio(
        config: const SoundscapeConfig(piano: 0.8, intensity: 0.8),
        sessionSeed: 777,
        durationSeconds: 2.0,
      );

      expect(result.wavBytes.length, greaterThan(44));
      expect(result.durationSeconds, equals(2.0));
      expect(result.totalSamples, equals(88200));
    });
  });
}
