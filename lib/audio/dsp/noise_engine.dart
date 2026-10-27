import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flundel/audio/dsp/smoothed_value.dart';

/// Multi-tier filtered noise generator (Pink, Brown, Velvet noise) with resonant biquad filtering and slow LFO breathing.
class NoiseEngine {
  final SmoothedValue volume = SmoothedValue(
    0.0,
  );
  final SmoothedValue warmth = SmoothedValue(
    0.5,
    smoothingDurationSeconds: 0.25,
  );
  final SmoothedValue cutoffHz = SmoothedValue(
    1200.0,
    smoothingDurationSeconds: 0.5,
  );

  bool isMuted = false;
  bool isSolo = false;

  void updateParameters({
    required double noiseLevel,
    required double warmthValue,
    required double cutoffFrequencyHz,
  }) {
    volume.setTarget(noiseLevel);
    warmth.setTarget(warmthValue);
    cutoffHz.setTarget(cutoffFrequencyHz);
  }

  /// Generates seamless filtered multi-tier noise WAV bytes with resonant filtering.
  Uint8List generateWavBytes({
    double durationSeconds = 3.0,
    int sampleRate = 48000,
    double gainMultiplier = 1.0,
  }) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final dataSize = numSamples * 4; // Stereo 16-bit
    final fileSize = 36 + dataSize;

    final bytes = Uint8List(44 + dataSize);
    final bd = ByteData.sublistView(bytes);

    _writeWavHeader(
      bd,
      bytes,
      fileSize,
      dataSize,
      channels: 2,
      sampleRate: sampleRate,
    );

    // Pink noise state variables (Kellet filter)
    double b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
    double brownStateL = 0.0;
    double brownStateR = 0.0;

    // Resonant Biquad Low-Pass Filter state & coefficients
    double x1L = 0, x2L = 0, y1L = 0, y2L = 0;
    double x1R = 0;
    double x2R = 0;
    double y1R = 0;
    double y2R = 0;

    final currentCutoff = cutoffHz.value.clamp(200.0, 8000.0);
    const Q = 0.707; // Butterworth response
    final w0 = 2 * pi * currentCutoff / sampleRate;
    final alphaBiquad = sin(w0) / (2 * Q);
    final cosw0 = cos(w0);

    final b0Coeff = (1 - cosw0) / 2;
    final b1Coeff = 1 - cosw0;
    final b2Coeff = (1 - cosw0) / 2;
    final a0Coeff = 1 + alphaBiquad;
    final a1Coeff = -2 * cosw0;
    final a2Coeff = 1 - alphaBiquad;

    // Normalized biquad coefficients
    final nb0 = b0Coeff / a0Coeff;
    final nb1 = b1Coeff / a0Coeff;
    final nb2 = b2Coeff / a0Coeff;
    final na1 = a1Coeff / a0Coeff;
    final na2 = a2Coeff / a0Coeff;

    final random = Random(42);
    final fadeSamples = (sampleRate * 0.15).toInt();
    int offset = 44;

    final curWarmth = warmth.value;

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;

      // Slow LFO "oceanic breathing" (0.1 Hz)
      final lfoL = 0.85 + 0.15 * sin(2 * pi * 0.10 * t);
      final lfoR = 0.85 + 0.15 * cos(2 * pi * 0.08 * t + 0.5);

      final whiteL = (random.nextDouble() * 2.0) - 1.0;
      final whiteR = (random.nextDouble() * 2.0) - 1.0;

      // Kellet pink noise algorithm
      b0 = 0.99886 * b0 + whiteL * 0.0555179;
      b1 = 0.99332 * b1 + whiteL * 0.0750759;
      b2 = 0.96900 * b2 + whiteL * 0.1538520;
      b3 = 0.86650 * b3 + whiteL * 0.3104856;
      b4 = 0.55000 * b4 + whiteL * 0.5329522;
      b5 = -0.76160 * b5 - whiteL * 0.0168980;
      final pinkL = b0 + b1 + b2 + b3 + b4 + b5 + b6 + whiteL * 0.5362;
      b6 = whiteL * 0.115926;

      // Brown noise integration
      brownStateL = (brownStateL + (0.02 * whiteL)) / 1.02;
      brownStateR = (brownStateR + (0.02 * whiteR)) / 1.02;

      // Blend based on warmth: higher warmth -> brown noise, lower warmth -> pink noise
      final rawL =
          (pinkL * (1.0 - (curWarmth * 0.6))) +
          (brownStateL * (curWarmth * 2.5));
      final rawR =
          (pinkL * (1.0 - (curWarmth * 0.6))) +
          (brownStateR * (curWarmth * 2.5));

      // Biquad low-pass filter calculation
      final filteredL =
          nb0 * rawL + nb1 * x1L + nb2 * x2L - na1 * y1L - na2 * y2L;
      x2L = x1L;
      x1L = rawL;
      y2L = y1L;
      y1L = filteredL;

      final filteredR =
          nb0 * rawR + nb1 * x1R + nb2 * x2R - na1 * y1R - na2 * y2R;
      x2R = x1R;
      x1R = rawR;
      y2R = y1R;
      y1R = filteredR;

      double loopFade = 1.0;
      if (i < fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * i / fadeSamples));
      } else if (i > numSamples - fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * (numSamples - i) / fadeSamples));
      }

      final gainFactor = 300.0 * gainMultiplier * loopFade;
      final valL = (filteredL * lfoL * gainFactor).toInt().clamp(-32768, 32767);
      final valR = (filteredR * lfoR * gainFactor).toInt().clamp(-32768, 32767);

      bd.setInt16(offset, valL, Endian.little);
      bd.setInt16(offset + 2, valR, Endian.little);
      offset += 4;
    }

    return bytes;
  }

  /// Generates seamless filtered brown/pink noise WAV data URI.
  String generateWavUri({
    double durationSeconds = 3.0,
    int sampleRate = 44100,
  }) {
    return 'data:audio/wav;base64,${base64Encode(generateWavBytes(durationSeconds: durationSeconds, sampleRate: sampleRate))}';
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
