import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flundel/audio/audio_mix_policy.dart';
import 'package:flundel/audio/dsp/pad_blend.dart';
import 'package:flundel/audio/dsp/pad_synth.dart';
import 'package:flundel/audio/dsp/rhythm_loop_renderer.dart';
import 'package:flundel/audio/procedural/harmony_controller.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled pads sustain through loop seams and survive mono playback', () {
    for (final chord in ChordType.values) {
      final bytes = File('assets/audio/pads/chords/${chord.name}.wav')
          .readAsBytesSync();
      final data = ByteData.sublistView(bytes);
      final frames = (bytes.length - 44) ~/ 4;
      expect(frames, 24 * 48000);
      var stereoPower = 0.0;
      var monoPower = 0.0;
      var edgePower = 0.0;
      var peak = 0.0;
      for (var i = 0; i < frames; i++) {
        final left = data.getInt16(44 + i * 4, Endian.little) / 32768;
        final right = data.getInt16(46 + i * 4, Endian.little) / 32768;
        final power = (left * left + right * right) / 2;
        stereoPower += power;
        monoPower += pow((left + right) / 2, 2);
        peak = max(peak, max(left.abs(), right.abs()));
        if (i < 12000 || i >= frames - 12000) edgePower += power;
      }
      expect(
        sqrt(edgePower / 24000),
        greaterThan(sqrt(stereoPower / frames) * 0.65),
        reason: chord.name,
      );
      expect(
        sqrt(monoPower / stereoPower),
        greaterThan(0.8),
        reason: chord.name,
      );
      expect(peak, lessThan(0.5));
      for (var channel = 0; channel < 2; channel++) {
        final first = data.getInt16(44 + channel * 2, Endian.little);
        final last = data.getInt16(
          44 + (frames - 1) * 4 + channel * 2,
          Endian.little,
        );
        expect((first - last).abs() / 32768, lessThan(0.01));
      }
    }
  });

  test('pad synthesis is deterministic and rejects invalid frequencies', () {
    final synth = PadSynth();
    final a = synth.generatePadWavBytes(
      baseFrequencies: [220, 330],
      durationSeconds: 1,
    );
    expect(
      a,
      orderedEquals(
        synth.generatePadWavBytes(
          baseFrequencies: [220, 330],
          durationSeconds: 1,
        ),
      ),
    );
    expect(
      () => synth.generatePadWavBytes(baseFrequencies: [double.nan]),
      throwsArgumentError,
    );
    expect(
      () =>
          synth.generatePadWavBytes(baseFrequencies: [220], durationSeconds: 0),
      throwsArgumentError,
    );
  });

  test(
    'focus pulses are softer than drums and retain exact transport length',
    () {
      final pulses = RhythmLoopRenderer.render(
        bpm: 84,
        seed: 42,
        gentlePulses: true,
      );
      final drums = RhythmLoopRenderer.render(bpm: 84, seed: 42);
      expect(pulses.frameCount, drums.frameCount);
      expect(
        pulses.drumsWav,
        orderedEquals(
          RhythmLoopRenderer.render(
            bpm: 84,
            seed: 42,
            gentlePulses: true,
          ).drumsWav,
        ),
      );
      expect(
        _differencePower(pulses.drumsWav),
        lessThan(_differencePower(drums.drumsWav) * 0.1),
      );
      final samples = _mono(pulses.drumsWav);
      final rms = sqrt(
        samples.fold<double>(0, (s, v) => s + v * v) / samples.length,
      );
      expect(20 * log(rms) / ln10, closeTo(-26, 0.2));
      expect(
        samples.map((v) => v.abs()).reduce(max),
        lessThanOrEqualTo(pow(10, -9 / 20) + 1 / 32768),
      );
      expect((samples.first - samples.last).abs(), lessThan(0.001));
      for (final chord in ChordType.values) {
        expect(pulses.bassWavs[chord]!.length, pulses.drumsWav.length);
      }
    },
  );

  test(
    'pad blends have no midpoint power dip and support retargeted levels',
    () {
      for (var i = 0; i <= 100; i++) {
        final weights = PadBlend.weights(i / 100);
        expect(
          pow(weights.incoming, 2) + pow(weights.outgoing, 2),
          closeTo(1, 1e-10),
        );
        final muted = weights.incoming * 0 + weights.outgoing * 0;
        expect(muted, 0);
      }
      expect(PadBlend.weights(-1).incoming, 0);
      expect(PadBlend.weights(2).incoming, 1);
    },
  );

  test('focus arrangements leave space between short phrases', () {
    for (final preset in SoundscapePreset.builtInPresets.where(
      (p) => p.config.gentlePulses,
    )) {
      expect(AudioMixPolicy.phraseNoteCount(preset.config), 2);
      for (var seed = 0; seed < 50; seed++) {
        final delay = AudioMixPolicy.nextPianoDelay(
          random: Random(seed),
          firstNote: false,
          config: preset.config,
          focusDepth: 1,
        );
        expect(delay.inSeconds, greaterThanOrEqualTo(24));
      }
    }
  });
}

List<double> _mono(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  return List.generate(
    (bytes.length - 44) ~/ 4,
    (i) => data.getInt16(44 + i * 4, Endian.little) / 32768,
  );
}

double _differencePower(Uint8List bytes) {
  final samples = _mono(bytes);
  var power = 0.0;
  for (var i = 1; i < samples.length; i++) {
    power += pow(samples[i] - samples[i - 1], 2);
  }
  return power / samples.length;
}
