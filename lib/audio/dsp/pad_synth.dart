import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flundel/audio/dsp/smoothed_value.dart';

/// Warm, analog-inspired multi-harmonic additive pad synth with dynamic low-pass filtering.
class PadSynth {
  final SmoothedValue volume = SmoothedValue(
    0.0,
    smoothingDurationSeconds: 0.2,
  );
  final SmoothedValue detuneCents = SmoothedValue(
    2.0,
    smoothingDurationSeconds: 0.5,
  );
  final SmoothedValue cutoffHz = SmoothedValue(
    1200.0,
    smoothingDurationSeconds: 0.5,
  );
  final SmoothedValue reverbSend = SmoothedValue(
    0.4,
    smoothingDurationSeconds: 0.3,
  );

  bool isMuted = false;
  bool isSolo = false;

  void updateParameters({
    required double padLevel,
    required double detune,
    required double reverbSendLevel,
    double cutoffFrequencyHz = 1200.0,
  }) {
    volume.setTarget(padLevel);
    detuneCents.setTarget(detune);
    reverbSend.setTarget(reverbSendLevel);
    cutoffHz.setTarget(cutoffFrequencyHz);
  }

  /// Periodic additive voices: every carrier and modulation completes a whole
  /// number of cycles. The loop has no fade-to-silence or filter startup seam.
  /// Shared center voices keep the stereo image stable when summed to mono.
  Uint8List generatePadWavBytes({
    required List<double> baseFrequencies,
    double durationSeconds = 24.0,
    int sampleRate = 48000,
    double gainMultiplier = 1.0,
  }) {
    if (!durationSeconds.isFinite ||
        durationSeconds <= 0 ||
        sampleRate < 8000 ||
        !gainMultiplier.isFinite ||
        gainMultiplier < 0 ||
        baseFrequencies.any(
          (f) => !f.isFinite || f <= 0 || f >= sampleRate / 2,
        )) {
      throw ArgumentError(
        'Expected positive duration, valid frequencies and gain',
      );
    }
    final frames = (sampleRate * durationSeconds).round();
    if (frames < 2) throw ArgumentError('Pad needs at least two frames');
    final duration = frames / sampleRate;
    final bytes = Uint8List(44 + frames * 4);
    final data = ByteData.sublistView(bytes);
    _writeWavHeader(
      data,
      bytes,
      bytes.length - 8,
      frames * 4,
      channels: 2,
      sampleRate: sampleRate,
    );
    final detune = pow(2, detuneCents.value.clamp(0.0, 12.0) / 1200);
    final cutoff = cutoffHz.value.clamp(200.0, 4000.0);
    final voices = <(int, int, int, double, double)>[];
    for (var note = 0; note < baseFrequencies.length; note++) {
      final frequency = baseFrequencies[note];
      for (final harmonic in [1, 2, 3, 5]) {
        final hz = frequency * harmonic;
        if (hz * detune >= sampleRate * 0.45) continue;
        final amplitude = switch (harmonic) {
          1 => 0.75,
          2 => 0.14,
          3 => 0.055,
          _ => 0.012,
        };
        // A smooth spectral rolloff without a transient filter state.
        final gain = amplitude / sqrt(1 + pow(hz / cutoff, 4));
        voices.add((
          (hz * duration).round(),
          (hz / detune * duration).round(),
          (hz * detune * duration).round(),
          gain,
          note * 1.71,
        ));
      }
    }
    final normalization =
        3000 * gainMultiplier / sqrt(max(1, baseFrequencies.length));
    for (var frame = 0; frame < frames; frame++) {
      final cycle = 2 * pi * frame / frames;
      var left = 0.0;
      var right = 0.0;
      for (final voice in voices) {
        final (center, low, high, gain, phase) = voice;
        final breath = 0.88 + 0.12 * sin(cycle + phase);
        final drift = 0.08 * sin(2 * cycle + phase);
        final middle = sin(center * cycle + phase + drift) * 0.72;
        left +=
            (middle + 0.28 * sin(low * cycle + phase + drift)) * gain * breath;
        right +=
            (middle + 0.28 * sin(high * cycle + phase + drift)) * gain * breath;
      }
      data.setInt16(
        44 + frame * 4,
        (left * normalization).round().clamp(-32768, 32767),
        Endian.little,
      );
      data.setInt16(
        46 + frame * 4,
        (right * normalization).round().clamp(-32768, 32767),
        Endian.little,
      );
    }
    return bytes;
  }

  /// Generates multi-oscillator chord pad WAV data URI.
  String generatePadWavUri({
    required List<double> baseFrequencies,
    double durationSeconds = 4.0,
    int sampleRate = 44100,
  }) {
    return 'data:audio/wav;base64,${base64Encode(generatePadWavBytes(baseFrequencies: baseFrequencies, durationSeconds: durationSeconds, sampleRate: sampleRate))}';
  }

  static void _writeWavHeader(
    ByteData bd,
    Uint8List bytes,
    int fileSize,
    int dataSize, {
    required int channels,
    required int sampleRate,
  }) {
    bytes.setRange(0, 4, ascii.encode('RIFF'));
    bd.setUint32(4, fileSize, Endian.little);
    bytes.setRange(8, 12, ascii.encode('WAVE'));

    bytes.setRange(12, 16, ascii.encode('fmt '));
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, channels, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * channels * 2, Endian.little);
    bd.setUint16(32, channels * 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);

    bytes.setRange(36, 40, ascii.encode('data'));
    bd.setUint32(40, dataSize, Endian.little);
  }
}
