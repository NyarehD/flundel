import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flundel/audio/dsp/audio_bus.dart';
import 'package:flundel/audio/dsp/binaural_generator.dart';
import 'package:flundel/audio/dsp/environmental_layer.dart';
import 'package:flundel/audio/dsp/noise_engine.dart';
import 'package:flundel/audio/dsp/pad_synth.dart';
import 'package:flundel/audio/dsp/smoothed_value.dart';
import 'package:flundel/audio/audio_mix_policy.dart';
import 'package:flundel/audio/procedural/harmony_controller.dart';
import 'package:flundel/audio/procedural/piano_scheduler.dart';
import 'package:flundel/audio/procedural/piano_phrase_scheduler.dart';
import 'package:flundel/audio/procedural/procedural_controller.dart';
import 'package:flundel/audio/procedural/variation_budget.dart';
import 'package:flundel/audio/rhythm_transport_clock.dart';
import 'package:flundel/audio/synthetic_audio.dart';
import 'package:flundel/audio/tools/offline_renderer.dart';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';

void main() {
  test(
    'default Deep Work mix favors tonal foreground over broadband layers',
    () {
      final config = SoundscapePreset.builtInPresets
          .singleWhere((preset) => preset.id == 'deep_work')
          .config;
      final padGain = AudioMixPolicy.padLevel(config) * config.intensity;
      final textureGain = AudioMixPolicy.noiseLevel(config) * config.intensity;

      expect(padGain / textureGain, greaterThan(2.0));
      expect(AudioMixPolicy.natureLevel(config), lessThan(padGain));
    },
  );

  test('first piano note is scheduled within the first four seconds', () {
    for (var seed = 0; seed < 100; seed++) {
      final delay = AudioMixPolicy.nextPianoDelay(
        random: Random(seed),
        firstNote: true,
        config: const SoundscapeConfig(),
        focusDepth: 1.0,
      );
      expect(delay.inSeconds, inInclusiveRange(2, 4));
    }
  });

  test(
    'seeded piano phrases are chord-aware and move by at most two tones',
    () {
      final chord = HarmonyController.chords[ChordType.fMaj7Sharp11]!;
      final phraseA = AudioMixPolicy.createPhraseFrequencies(
        chord: chord,
        random: Random(912),
        noteCount: 4,
      );
      final phraseB = AudioMixPolicy.createPhraseFrequencies(
        chord: chord,
        random: Random(912),
        noteCount: 4,
      );
      expect(phraseA, equals(phraseB));
      expect(phraseA, hasLength(4));
      expect(phraseA.length, lessThanOrEqualTo(AudioMixPolicy.maxPianoVoices));

      final sourceTones = <double>{
        ...chord.chordFrequencies,
        ...chord.passingFrequencies,
      }.map(_toPianoRegister).toSet();
      expect(phraseA.every(sourceTones.contains), isTrue);
      final sorted = sourceTones.toList()..sort();
      for (var i = 1; i < phraseA.length; i++) {
        final previousIndex = sorted.indexOf(phraseA[i - 1]);
        final currentIndex = sorted.indexOf(phraseA[i]);
        expect((currentIndex - previousIndex).abs(), lessThanOrEqualTo(2));
      }
    },
  );

  test(
    'phrase interval exceeds the prior phrase duration for every preset',
    () {
      for (final preset in SoundscapePreset.builtInPresets) {
        final config = preset.config;
        final noteCount = AudioMixPolicy.phraseNoteCount(config);
        final phraseMs =
            (noteCount - 1) *
            AudioMixPolicy.phraseSpacing(Random(7), config).inMilliseconds;
        for (var seed = 0; seed < 30; seed++) {
          final interval = AudioMixPolicy.nextPianoDelay(
            random: Random(seed),
            firstNote: false,
            config: config,
            focusDepth: 1,
          );
          expect(interval.inMilliseconds, greaterThan(phraseMs));
        }
      }
    },
  );

  test(
    'phrase scheduler cancels every remaining note on lifecycle stop',
    () async {
      final scheduler = PianoPhraseScheduler();
      var played = 0;
      scheduler.schedule(
        frequencies: [440, 493.88, 523.25, 587.33],
        spacing: const Duration(milliseconds: 30),
        onNote: (frequency, index) {
          if (frequency > 0 && index >= 0) played++;
        },
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(played, 1);
      scheduler.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(played, 1);
    },
  );

  test('Fmaj7 sharp eleven uses B4 as its raised eleventh', () {
    expect(
      HarmonyController.chords[ChordType.fMaj7Sharp11]!.chordFrequencies,
      contains(493.88),
    );
  });

  test('authored beat presets keep quiet presets beat-free', () {
    final presets = {
      for (final preset in SoundscapePreset.builtInPresets) preset.id: preset,
    };
    expect(presets['deep_work']!.config.beatsBpm, 72);
    expect(presets['coding']!.config.beatsBpm, 84);
    expect(presets['reading']!.config.beatsBpm, 68);
    expect(presets['piano_focus']!.config.beatsBpm, 76);
    expect(presets['quiet_focus']!.config.beats, 0);
    expect(presets['quiet_focus']!.config.bass, 0);
    expect(presets['night_focus']!.config.beats, 0);
    expect(presets['night_focus']!.config.bass, 0);
    for (final id in ['deep_work', 'coding', 'reading', 'piano_focus']) {
      expect(presets[id]!.config.beats, greaterThan(0));
      expect(presets[id]!.config.bass, greaterThan(0));
    }
  });

  test('native rhythm transport wraps phase and preserves pause phase', () {
    final transport = RhythmTransportClock()
      ..reset(const Duration(seconds: 10));
    transport.anchor(const Duration(seconds: 100));
    expect(transport.phaseAt(const Duration(seconds: 99)), Duration.zero);
    expect(
      transport.phaseAt(const Duration(seconds: 104)),
      const Duration(seconds: 4),
    );
    expect(
      transport.phaseAt(const Duration(seconds: 111)),
      const Duration(seconds: 1),
    );

    final pausedPhase = transport.phaseAt(const Duration(seconds: 107));
    transport.anchor(const Duration(seconds: 200), phase: pausedPhase);
    expect(transport.phaseAt(const Duration(seconds: 199)), pausedPhase);
    expect(
      transport.phaseAt(const Duration(seconds: 204)),
      const Duration(seconds: 1),
    );
  });

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

    test(
      'HarmonyController transitions only among valid harmonic vocabulary',
      () {
        final harmony = HarmonyController();
        final random = Random(42);

        final validChords = {
          'Am7',
          'Cmaj7',
          'Fmaj7',
          'Em7',
          'Dm7',
          'Am9',
          'Cmaj9',
          'Fmaj7#11',
        };

        for (int i = 0; i < 50; i++) {
          final next = harmony.transitionNextChord(random);
          expect(validChords.contains(next.name), isTrue);
          expect(next.chordFrequencies.isNotEmpty, isTrue);
        }
      },
    );

    test('PadSynth generates valid multi-harmonic stereo WAV bytes', () {
      final pad = PadSynth();
      pad.updateParameters(
        padLevel: 0.8,
        detune: 3.0,
        reverbSendLevel: 0.4,
        cutoffFrequencyHz: 1500.0,
      );

      final wavBytes = pad.generatePadWavBytes(
        baseFrequencies: [220.0, 261.63, 329.63, 392.00],
        durationSeconds: 1.0,
        sampleRate: 48000,
      );

      expect(
        wavBytes.length,
        equals(44 + 48000 * 4),
      ); // Header + 1s stereo 16-bit
    });

    test('NoiseEngine generates resonant biquad filtered noise WAV bytes', () {
      final noise = NoiseEngine();
      noise.updateParameters(
        noiseLevel: 0.5,
        warmthValue: 0.7,
        cutoffFrequencyHz: 1000.0,
      );

      final wavBytes = noise.generateWavBytes(
        durationSeconds: 1.0,
        sampleRate: 48000,
      );
      expect(wavBytes.length, equals(44 + 48000 * 4));
    });

    test('BinauralGenerator generates stereo binaural WAV bytes', () {
      final binaural = BinauralGenerator();
      binaural.updateParameters(
        level: 0.6,
        carrierFrequency: 180.0,
        differenceHz: 10.0,
      );

      final wavBytes = binaural.generateBinauralWavBytes(
        durationSeconds: 1.0,
        sampleRate: 48000,
      );
      expect(wavBytes.length, equals(44 + 48000 * 4));
    });

    test(
      'EnvironmentalLayer generates realistic rain/wind ambience WAV bytes',
      () {
        final env = EnvironmentalLayer();
        env.updateParameters(natureLevel: 0.8);

        final wavBytes = env.generateRainWavBytes(
          durationSeconds: 1.0,
          sampleRate: 48000,
        );
        expect(wavBytes.length, equals(44 + 48000 * 4));
      },
    );

    test('SyntheticAudio generates physical modeling chime WAV bytes', () {
      final chimeBytes = SyntheticAudio.createTranquilChimeWavBytes(
        freqHz: 523.25,
        durationSeconds: 1.5,
        sampleRate: 48000,
      );

      expect(chimeBytes.length, equals(44 + (48000 * 1.5).toInt() * 4));
    });

    test(
      'soft piano source has a lower upper-harmonic ratio than the cue chime',
      () {
        final piano = SyntheticAudio.createTranquilChimeWavBytes(
          freqHz: 659.25,
          durationSeconds: 1,
          sampleRate: 48000,
          softPiano: true,
        );
        final chime = SyntheticAudio.createTranquilChimeWavBytes(
          freqHz: 659.25,
          durationSeconds: 1,
          sampleRate: 48000,
        );
        expect(piano.length, 44 + 48000 * 4);
        expect(
          _secondHarmonicRatio(piano, 659.25),
          lessThan(_secondHarmonicRatio(chime, 659.25)),
        );
        expect(piano, isNot(chime));
      },
    );

    test(
      'PianoScheduler enforces minimum silence gap and polyphony limits',
      () {
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
      },
    );

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
      expect(
        extremePeak,
        lessThanOrEqualTo(AudioBus.masterLimiterCeiling),
      ); // Safe ceiling!
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

double _secondHarmonicRatio(Uint8List wav, double frequencyHz) {
  final bytes = ByteData.sublistView(wav);
  const rate = 48000;
  const frames = rate ~/ 4;
  var fundamental = 0.0;
  var second = 0.0;
  for (var i = 0; i < frames; i++) {
    final sample = bytes.getInt16(44 + i * 4, Endian.little) / 32768;
    final t = i / rate;
    fundamental += sample * sin(2 * pi * frequencyHz * t);
    second += sample * sin(2 * pi * frequencyHz * 2 * t);
  }
  return second.abs() / fundamental.abs();
}

double _toPianoRegister(double frequency) {
  var result = frequency;
  while (result < 390) {
    result *= 2;
  }
  while (result > 988) {
    result /= 2;
  }
  return result;
}
