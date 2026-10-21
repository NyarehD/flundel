import 'dart:math';
import 'dart:typed_data';

import 'package:flundel/audio/dsp/rhythm_loop_renderer.dart';
import 'package:flundel/audio/procedural/harmony_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RhythmLoopRenderer', () {
    test('renders exact four-bar lengths for authored tempos', () {
      for (final bpm in [68, 72, 76, 84]) {
        final bank = RhythmLoopRenderer.render(bpm: bpm, seed: 17);
        final expected = (48000 * 60 * 16 / bpm).round();
        expect(bank.frameCount, expected);
        expect(bank.sampleRate, 48000);
        expect(bank.drumsWav.length, 44 + expected * 4);
        expect(bank.bassWavs.length, ChordType.values.length);
        for (final wav in bank.bassWavs.values) {
          expect(wav.length, 44 + expected * 4);
        }
      }
    });

    test('is deterministic for a seed and varies with another seed', () {
      final a = RhythmLoopRenderer.render(bpm: 72, seed: 42);
      final again = RhythmLoopRenderer.render(bpm: 72, seed: 42);
      final other = RhythmLoopRenderer.render(bpm: 72, seed: 43);
      expect(a.drumsWav, orderedEquals(again.drumsWav));
      expect(
        a.bassWavs[ChordType.am7],
        orderedEquals(again.bassWavs[ChordType.am7]!),
      );
      expect(a.drumsWav, isNot(orderedEquals(other.drumsWav)));
    });

    test('stems have controlled level, DC and safe peak', () {
      final bank = RhythmLoopRenderer.render(bpm: 72, seed: 9);
      for (final wav in [bank.drumsWav, ...bank.bassWavs.values]) {
        final samples = _samples(wav);
        final mean = samples.reduce((a, b) => a + b) / samples.length;
        final rms = sqrt(
          samples.fold<double>(0, (s, v) => s + v * v) / samples.length,
        );
        final peak = samples.map((v) => v.abs()).reduce(max);
        expect(mean.abs(), lessThan(0.0015));
        expect(rms, greaterThan(0.015));
        // -6 dBFS plus one PCM16 quantization step.
        expect(peak, lessThanOrEqualTo(pow(10, -6 / 20) + 1 / 32768));
        // A circular tail is present across the loop boundary; inspect for a
        // bounded endpoint jump rather than a hard, truncated sample tail.
        expect((samples.first - samples.last).abs(), lessThan(0.12));
      }
    });

    test('chord stems share onsets and render the configured bass roots', () {
      final bank = RhythmLoopRenderer.render(bpm: 72, seed: 3);
      const roots = <ChordType, double>{
        ChordType.am7: 55,
        ChordType.am9: 55,
        ChordType.cMaj7: 65.406,
        ChordType.cMaj9: 65.406,
        ChordType.fMaj7: 43.654,
        ChordType.fMaj7Sharp11: 43.654,
        ChordType.em7: 41.203,
        ChordType.dMaj7: 73.416,
      };
      final am = _samples(bank.bassWavs[ChordType.am7]!);
      for (final entry in roots.entries) {
        final samples = _samples(bank.bassWavs[entry.key]!);
        // Every chord attacks on the same first downbeat; allow two LSBs for
        // the global DC correction and PCM16 quantization.
        expect(samples.first.abs(), lessThanOrEqualTo(2 / 32768));
        expect(samples.length, am.length);
        expect(
          _dominantFrequency(samples, 48000, 0.38),
          closeTo(entry.value, 1.5),
          reason: '${entry.key} should begin on ${entry.value} Hz',
        );
      }
      expect(
        am,
        isNot(orderedEquals(_samples(bank.bassWavs[ChordType.cMaj7]!))),
      );

      // The first bass note fades to silence at 430 ms instead of stopping
      // with a nonzero oscillator value.
      final tailFrame = (48000 * 0.43).round();
      expect(am[tailFrame].abs(), lessThanOrEqualTo(2 / 32768));
      expect(am[tailFrame - 1].abs(), lessThan(0.001));
    });

    test('rejects unsupported tempo and output rate', () {
      expect(
        () => RhythmLoopRenderer.render(bpm: 59, seed: 1),
        throwsArgumentError,
      );
      expect(
        () => RhythmLoopRenderer.render(bpm: 101, seed: 1),
        throwsArgumentError,
      );
      expect(
        () => RhythmLoopRenderer.render(bpm: 72, seed: 1, sampleRate: 44100),
        throwsArgumentError,
      );
    });
  });
}

List<double> _samples(Uint8List wav) {
  final data = ByteData.sublistView(wav);
  return List<double>.generate((wav.length - 44) ~/ 4, (i) {
    return data.getInt16(44 + i * 4, Endian.little) / 32768;
  });
}

double _dominantFrequency(List<double> samples, int sr, double seconds) {
  final count = (sr * seconds).round();
  var bestFrequency = 0.0;
  var bestMagnitude = -1.0;
  // Search the bass fundamentals and nearby partials with a direct DFT.
  for (var quarterHz = 35 * 4; quarterHz <= 110 * 4; quarterHz++) {
    final hz = quarterHz / 4;
    var re = 0.0;
    var im = 0.0;
    for (var i = 0; i < count; i++) {
      final window = 0.5 - 0.5 * cos(2 * pi * i / (count - 1));
      final angle = 2 * pi * hz * i / sr;
      re += samples[i] * window * cos(angle);
      im -= samples[i] * window * sin(angle);
    }
    final magnitude = re * re + im * im;
    if (magnitude > bestMagnitude) {
      bestMagnitude = magnitude;
      bestFrequency = hz.toDouble();
    }
  }
  return bestFrequency;
}
