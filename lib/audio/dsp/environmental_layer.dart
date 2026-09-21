import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flundel/audio/dsp/smoothed_value.dart';

/// Environmental nature texture layer (rain/wind/stream) with parameter smoothing.
class EnvironmentalLayer {
  final SmoothedValue volume = SmoothedValue(0.0, smoothingDurationSeconds: 0.2);

  bool isMuted = false;
  bool isSolo = false;

  void updateParameters({required double natureLevel}) {
    volume.setTarget(natureLevel);
  }

  /// Generates soft rain/wind nature ambience WAV bytes.
  Uint8List generateRainWavBytes({
    double durationSeconds = 3.0,
    int sampleRate = 48000,
  }) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final dataSize = numSamples * 4;
    final fileSize = 36 + dataSize;

    final bytes = Uint8List(44 + dataSize);
    final bd = ByteData.sublistView(bytes);

    _writeWavHeader(bd, bytes, fileSize, dataSize, channels: 2, sampleRate: sampleRate);

    final random = Random(88);
    final fadeSamples = (sampleRate * 0.15).toInt();
    int offset = 44;

    double rainDropStateL = 0.0;
    double rainDropStateR = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final whiteL = (random.nextDouble() * 2.0) - 1.0;
      final whiteR = (random.nextDouble() * 2.0) - 1.0;

      // Soft rain drop impulse simulation using bandpass filtering
      rainDropStateL = (rainDropStateL * 0.92) + (whiteL * 0.08);
      rainDropStateR = (rainDropStateR * 0.92) + (whiteR * 0.08);

      double loopFade = 1.0;
      if (i < fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * i / fadeSamples));
      } else if (i > numSamples - fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * (numSamples - i) / fadeSamples));
      }

      final gain = 1800.0 * loopFade;
      final valL = (rainDropStateL * gain).toInt().clamp(-32768, 32767);
      final valR = (rainDropStateR * gain).toInt().clamp(-32768, 32767);

      bd.setInt16(offset, valL, Endian.little);
      bd.setInt16(offset + 2, valR, Endian.little);
      offset += 4;
    }

    return bytes;
  }

  /// Generates soft rain/wind nature ambience WAV URI.
  String generateRainWavUri({
    double durationSeconds = 3.0,
    int sampleRate = 44100,
  }) {
    return 'data:audio/wav;base64,${base64Encode(generateRainWavBytes(durationSeconds: durationSeconds, sampleRate: sampleRate))}';
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
