import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flundel/audio/dsp/smoothed_value.dart';

/// Environmental nature texture layer (organic rain, wind rumble, stream ripples) with parameter smoothing.
class EnvironmentalLayer {
  final SmoothedValue volume = SmoothedValue(0.0, smoothingDurationSeconds: 0.2);

  bool isMuted = false;
  bool isSolo = false;

  void updateParameters({required double natureLevel}) {
    volume.setTarget(natureLevel);
  }

  /// Generates soft rain, wind, and river stream nature ambience WAV bytes.
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

    // Rain drop impulse bandpass state
    double rainDropStateL = 0.0;
    double rainDropStateR = 0.0;

    // Wind low-pass rumble state
    double windRumbleL = 0.0;
    double windRumbleR = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;

      // 1. Rain drop Poisson impulses
      final impulseRollL = random.nextDouble();
      final impulseRollR = random.nextDouble();

      // Droplet density probability threshold (~120 drops/sec per channel)
      final dropL = impulseRollL < 0.0025 ? ((random.nextDouble() * 2.0) - 1.0) * 1.8 : 0.0;
      final dropR = impulseRollR < 0.0025 ? ((random.nextDouble() * 2.0) - 1.0) * 1.8 : 0.0;

      final whiteL = (random.nextDouble() * 2.0) - 1.0;
      final whiteR = (random.nextDouble() * 2.0) - 1.0;

      // Bandpass filtering for rain patter (1.5 kHz – 5.0 kHz response)
      rainDropStateL = (rainDropStateL * 0.88) + ((whiteL * 0.15 + dropL) * 0.12);
      rainDropStateR = (rainDropStateR * 0.88) + ((whiteR * 0.15 + dropR) * 0.12);

      // 2. Wind rumble (Low-pass filtered brown noise, 80 Hz – 250 Hz)
      final windLfo = 0.70 + 0.30 * sin(2 * pi * 0.15 * t);
      windRumbleL = (windRumbleL * 0.985) + (whiteL * 0.015);
      windRumbleR = (windRumbleR * 0.985) + (whiteR * 0.015);

      final combinedL = (rainDropStateL * 0.65) + (windRumbleL * windLfo * 1.8);
      final combinedR = (rainDropStateR * 0.65) + (windRumbleR * windLfo * 1.8);

      double loopFade = 1.0;
      if (i < fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * i / fadeSamples));
      } else if (i > numSamples - fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * (numSamples - i) / fadeSamples));
      }

      final gain = 2000.0 * loopFade;
      final valL = (combinedL * gain).toInt().clamp(-32768, 32767);
      final valR = (combinedR * gain).toInt().clamp(-32768, 32767);

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
