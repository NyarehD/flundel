import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flundel/audio/dsp/smoothed_value.dart';

/// Filtered noise generator with brown and pink noise blending.
class NoiseEngine {
  final SmoothedValue volume = SmoothedValue(0.0, smoothingDurationSeconds: 0.15);
  final SmoothedValue warmth = SmoothedValue(0.5, smoothingDurationSeconds: 0.25);
  final SmoothedValue cutoffHz = SmoothedValue(1200.0, smoothingDurationSeconds: 0.5);

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

  /// Generates seamless filtered brown/pink noise WAV bytes.
  Uint8List generateWavBytes({
    double durationSeconds = 3.0,
    int sampleRate = 48000,
  }) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final dataSize = numSamples * 4; // Stereo 16-bit
    final fileSize = 36 + dataSize;

    final bytes = Uint8List(44 + dataSize);
    final bd = ByteData.sublistView(bytes);

    _writeWavHeader(bd, bytes, fileSize, dataSize, channels: 2, sampleRate: sampleRate);

    double b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
    double brownState = 0.0;
    final random = Random(42);

    final fadeSamples = (sampleRate * 0.15).toInt();
    int offset = 44;

    final curWarmth = warmth.value;

    for (int i = 0; i < numSamples; i++) {
      final white = (random.nextDouble() * 2.0) - 1.0;

      // Kellet pink noise algorithm
      b0 = 0.99886 * b0 + white * 0.0555179;
      b1 = 0.99332 * b1 + white * 0.0750759;
      b2 = 0.96900 * b2 + white * 0.1538520;
      b3 = 0.86650 * b3 + white * 0.3104856;
      b4 = 0.55000 * b4 + white * 0.5329522;
      b5 = -0.76160 * b5 - white * 0.0168980;
      final pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362;
      b6 = white * 0.115926;

      // Brown noise integration
      brownState = (brownState + (0.02 * white)) / 1.02;

      // Blend based on warmth: warmth -> brown noise, lower warmth -> pink noise
      final blended = (pink * (1.0 - (curWarmth * 0.6))) + (brownState * (curWarmth * 2.5));

      double loopFade = 1.0;
      if (i < fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * i / fadeSamples));
      } else if (i > numSamples - fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * (numSamples - i) / fadeSamples));
      }

      final gainFactor = 320.0 * loopFade;
      final valL = (blended * gainFactor).toInt().clamp(-32768, 32767);
      final valR = ((blended + (random.nextDouble() * 0.05)) * gainFactor).toInt().clamp(-32768, 32767);

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
