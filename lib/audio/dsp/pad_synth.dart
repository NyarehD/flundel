import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flundel/audio/dsp/smoothed_value.dart';

/// Ethereal multi-oscillator pad synth for tonal warmth.
class PadSynth {
  final SmoothedValue volume = SmoothedValue(0.0, smoothingDurationSeconds: 0.2);
  final SmoothedValue detuneCents = SmoothedValue(2.0, smoothingDurationSeconds: 0.5);
  final SmoothedValue reverbSend = SmoothedValue(0.4, smoothingDurationSeconds: 0.3);

  bool isMuted = false;
  bool isSolo = false;

  void updateParameters({
    required double padLevel,
    required double detune,
    required double reverbSendLevel,
  }) {
    volume.setTarget(padLevel);
    detuneCents.setTarget(detune);
    reverbSend.setTarget(reverbSendLevel);
  }

  /// Generates multi-oscillator chord pad WAV data URI.
  String generatePadWavUri({
    required List<double> baseFrequencies,
    double durationSeconds = 4.0,
    int sampleRate = 44100,
  }) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final dataSize = numSamples * 4; // Stereo 16-bit
    final fileSize = 36 + dataSize;

    final bytes = Uint8List(44 + dataSize);
    final bd = ByteData.sublistView(bytes);

    _writeWavHeader(bd, bytes, fileSize, dataSize, channels: 2, sampleRate: sampleRate);

    final fadeSamples = (sampleRate * 0.25).toInt();
    int offset = 44;

    final curVol = volume.value;
    final detuneRatio = 1.0 + (detuneCents.value * 0.0005);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;

      double sampleL = 0.0;
      double sampleR = 0.0;

      for (int k = 0; k < baseFrequencies.length; k++) {
        final f = baseFrequencies[k];
        // Multi-voice oscillators: Fundamental + detuned voice + fifth
        final lMod = sin(2 * pi * 0.15 * t + k);
        final rMod = cos(2 * pi * 0.18 * t + k);

        final voice1L = sin(2 * pi * f * t) * (0.22 + 0.04 * lMod);
        final voice1R = sin(2 * pi * (f * detuneRatio) * t) * (0.22 + 0.04 * rMod);

        final voice2L = sin(2 * pi * (f * 1.5) * t) * 0.10; // Soft fifth harmonic
        final voice2R = sin(2 * pi * (f * 1.5 * detuneRatio) * t) * 0.10;

        sampleL += voice1L + voice2L;
        sampleR += voice1R + voice2R;
      }

      double loopFade = 1.0;
      if (i < fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * i / fadeSamples));
      } else if (i > numSamples - fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * (numSamples - i) / fadeSamples));
      }

      final gain = 2600.0 * loopFade;
      final valL = (sampleL * gain).toInt().clamp(-32768, 32767);
      final valR = (sampleR * gain).toInt().clamp(-32768, 32767);

      bd.setInt16(offset, valL, Endian.little);
      bd.setInt16(offset + 2, valR, Endian.little);
      offset += 4;
    }

    return 'data:audio/wav;base64,${base64Encode(bytes)}';
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
