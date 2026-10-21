import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flundel/audio/dsp/smoothed_value.dart';

/// Warm, analog-inspired multi-harmonic additive pad synth with dynamic low-pass filtering.
class PadSynth {
  final SmoothedValue volume = SmoothedValue(0.0, smoothingDurationSeconds: 0.2);
  final SmoothedValue detuneCents = SmoothedValue(2.0, smoothingDurationSeconds: 0.5);
  final SmoothedValue cutoffHz = SmoothedValue(1200.0, smoothingDurationSeconds: 0.5);
  final SmoothedValue reverbSend = SmoothedValue(0.4, smoothingDurationSeconds: 0.3);

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

  /// Helper for soft triangle wave folding (warm analog character).
  static double _triWave(double phase) {
    return (2.0 / pi) * asin(sin(phase));
  }

  /// Generates multi-oscillator chord pad WAV bytes with warm harmonics and low-pass filtering.
  Uint8List generatePadWavBytes({
    required List<double> baseFrequencies,
    double durationSeconds = 4.0,
    int sampleRate = 48000,
    double gainMultiplier = 1.0,
  }) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final dataSize = numSamples * 4; // Stereo 16-bit
    final fileSize = 36 + dataSize;

    final bytes = Uint8List(44 + dataSize);
    final bd = ByteData.sublistView(bytes);

    _writeWavHeader(bd, bytes, fileSize, dataSize, channels: 2, sampleRate: sampleRate);

    final fadeSamples = (sampleRate * 0.25).toInt();
    int offset = 44;

    final detuneRatioL = 1.0 - (detuneCents.value * 0.0003);
    final detuneRatioR = 1.0 + (detuneCents.value * 0.0003);

    // State-variable low-pass filter states
    double lpfL = 0.0;
    double lpfR = 0.0;
    final currentCutoff = cutoffHz.value.clamp(200.0, 4000.0);
    final rc = 1.0 / (2 * pi * currentCutoff);
    final dt = 1.0 / sampleRate;
    final alpha = dt / (rc + dt);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;

      double sampleL = 0.0;
      double sampleR = 0.0;

      // 1. Sub-bass oscillator based on fundamental frequency
      if (baseFrequencies.isNotEmpty) {
        final subFreq = baseFrequencies.first * 0.5;
        final subWave = sin(2 * pi * subFreq * t);
        sampleL += subWave * 0.18;
        sampleR += subWave * 0.18;
      }

      // 2. Multi-harmonic additive voices per chord note
      for (int k = 0; k < baseFrequencies.length; k++) {
        final f = baseFrequencies[k];
        final lMod = sin(2 * pi * 0.12 * t + k);
        final rMod = cos(2 * pi * 0.15 * t + k * 1.3);

        // Fundamental (sine + soft triangle blend)
        final pL = 2 * pi * (f * detuneRatioL) * t;
        final pR = 2 * pi * (f * detuneRatioR) * t;

        final fundamentalL = (sin(pL) * 0.75 + _triWave(pL) * 0.25) * (0.22 + 0.03 * lMod);
        final fundamentalR = (sin(pR) * 0.75 + _triWave(pR) * 0.25) * (0.22 + 0.03 * rMod);

        // 2nd Harmonic (Octave above)
        final harm2L = sin(2 * pL) * 0.08;
        final harm2R = sin(2 * pR) * 0.08;

        // 3rd Harmonic (Fifth above octave)
        final harm3L = sin(3 * pL) * 0.04;
        final harm3R = sin(3 * pR) * 0.04;

        // 5th Harmonic (Warm overtone)
        final harm5L = sin(5 * pL) * 0.015;
        final harm5R = sin(5 * pR) * 0.015;

        sampleL += fundamentalL + harm2L + harm3L + harm5L;
        sampleR += fundamentalR + harm2R + harm3R + harm5R;
      }

      // 3. Low-pass filtering to remove digital harshness
      lpfL += alpha * (sampleL - lpfL);
      lpfR += alpha * (sampleR - lpfR);

      // Loop crossfade envelope
      double loopFade = 1.0;
      if (i < fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * i / fadeSamples));
      } else if (i > numSamples - fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * (numSamples - i) / fadeSamples));
      }

      final gain = 2400.0 * gainMultiplier * loopFade;
      final valL = (lpfL * gain).toInt().clamp(-32768, 32767);
      final valR = (lpfR * gain).toInt().clamp(-32768, 32767);

      bd.setInt16(offset, valL, Endian.little);
      bd.setInt16(offset + 2, valR, Endian.little);
      offset += 4;
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
