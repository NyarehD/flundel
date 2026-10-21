import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flundel/audio/dsp/smoothed_value.dart';

/// Independent stereo generator for binaural focus beats with warm harmonic layering and isochronic modulation.
class BinauralGenerator {
  final SmoothedValue volume = SmoothedValue(0.0, smoothingDurationSeconds: 0.2);
  final SmoothedValue carrierHz = SmoothedValue(180.0, smoothingDurationSeconds: 0.5);
  final SmoothedValue beatHz = SmoothedValue(10.0, smoothingDurationSeconds: 0.5);

  bool isMuted = false;
  bool isSolo = false;

  void updateParameters({
    required double level,
    required double carrierFrequency,
    required double differenceHz,
  }) {
    volume.setTarget(level);
    carrierHz.setTarget(carrierFrequency);
    beatHz.setTarget(differenceHz);
  }

  /// Generates binaural stereo tone WAV bytes with warm harmonic overtones.
  Uint8List generateBinauralWavBytes({
    double durationSeconds = 3.0,
    int sampleRate = 48000,
  }) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final dataSize = numSamples * 4;
    final fileSize = 36 + dataSize;

    final bytes = Uint8List(44 + dataSize);
    final bd = ByteData.sublistView(bytes);

    _writeWavHeader(bd, bytes, fileSize, dataSize, channels: 2, sampleRate: sampleRate);

    final leftFreq = carrierHz.value;
    final rightFreq = carrierHz.value + beatHz.value;
    final bHz = beatHz.value;

    final fadeSamples = (sampleRate * 0.15).toInt();
    int offset = 44;

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;

      // Soft isochronic pulse envelope modulation at beat frequency (gentle 15% pulse)
      final isoPulse = 0.85 + 0.15 * (0.5 + 0.5 * sin(2 * pi * bHz * t));

      // Left Channel: Fundamental + subtle 2nd overtone
      final leftFundamental = sin(2 * pi * leftFreq * t);
      final leftHarmonic = 0.12 * sin(2 * pi * (leftFreq * 2.0) * t);
      final leftSig = (leftFundamental + leftHarmonic) * isoPulse;

      // Right Channel: Fundamental + subtle 2nd overtone
      final rightFundamental = sin(2 * pi * rightFreq * t);
      final rightHarmonic = 0.12 * sin(2 * pi * (rightFreq * 2.0) * t);
      final rightSig = (rightFundamental + rightHarmonic) * isoPulse;

      double loopFade = 1.0;
      if (i < fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * i / fadeSamples));
      } else if (i > numSamples - fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * (numSamples - i) / fadeSamples));
      }

      final gainFactor = 1800.0 * loopFade;
      final leftVal = (leftSig * gainFactor).toInt().clamp(-32768, 32767);
      final rightVal = (rightSig * gainFactor).toInt().clamp(-32768, 32767);

      bd.setInt16(offset, leftVal, Endian.little);
      bd.setInt16(offset + 2, rightVal, Endian.little);
      offset += 4;
    }

    return bytes;
  }

  /// Generates binaural stereo tone WAV URI with crossfaded loop ends.
  String generateBinauralWavUri({
    double durationSeconds = 3.0,
    int sampleRate = 44100,
  }) {
    return 'data:audio/wav;base64,${base64Encode(generateBinauralWavBytes(durationSeconds: durationSeconds, sampleRate: sampleRate))}';
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
