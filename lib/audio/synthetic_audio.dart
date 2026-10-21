import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

class SyntheticAudio {
  /// Generates a subtle, smooth binaural stereo wave (10 Hz Alpha beat for focus) with warm harmonics.
  static String createBinauralWavUri({
    double baseHz = 180.0,
    double beatHz = 10.0,
    double durationSeconds = 2.0,
    int sampleRate = 44100,
  }) {
    final leftHz = baseHz;
    final rightHz = baseHz + beatHz;
    final numSamples = (sampleRate * durationSeconds).toInt();
    final dataSize = numSamples * 4;
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

    final fadeSamples = (sampleRate * 0.1).toInt();
    int offset = 44;

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;

      double loopFade = 1.0;
      if (i < fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * i / fadeSamples));
      } else if (i > numSamples - fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * (numSamples - i) / fadeSamples));
      }

      final leftSig =
          sin(2 * pi * leftHz * t) + 0.12 * sin(2 * pi * leftHz * 2.0 * t);
      final rightSig =
          sin(2 * pi * rightHz * t) + 0.12 * sin(2 * pi * rightHz * 2.0 * t);

      final leftVal = (leftSig * 2000 * loopFade).toInt().clamp(-32768, 32767);
      final rightVal = (rightSig * 2000 * loopFade).toInt().clamp(
        -32768,
        32767,
      );

      bd.setInt16(offset, leftVal, Endian.little);
      bd.setInt16(offset + 2, rightVal, Endian.little);
      offset += 4;
    }

    return 'data:audio/wav;base64,${base64Encode(bytes)}';
  }

  /// Generates warm, low-passed filtered pink/brown noise (soft room/ambient background).
  static String createWarmNoiseWavUri({
    double durationSeconds = 3.0,
    int sampleRate = 44100,
  }) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final dataSize = numSamples * 2;
    final fileSize = 36 + dataSize;

    final bytes = Uint8List(44 + dataSize);
    final bd = ByteData.sublistView(bytes);

    _writeWavHeader(
      bd,
      bytes,
      fileSize,
      dataSize,
      channels: 1,
      sampleRate: sampleRate,
    );

    double b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
    final random = Random(42);
    final fadeSamples = (sampleRate * 0.15).toInt();
    int offset = 44;

    for (int i = 0; i < numSamples; i++) {
      final white = (random.nextDouble() * 2.0) - 1.0;

      // Kellet pink noise filter
      b0 = 0.99886 * b0 + white * 0.0555179;
      b1 = 0.99332 * b1 + white * 0.0750759;
      b2 = 0.96900 * b2 + white * 0.1538520;
      b3 = 0.86650 * b3 + white * 0.3104856;
      b4 = 0.55000 * b4 + white * 0.5329522;
      b5 = -0.7616 * b5 - white * 0.0168980;
      final pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362;
      b6 = white * 0.115926;

      double loopFade = 1.0;
      if (i < fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * i / fadeSamples));
      } else if (i > numSamples - fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * (numSamples - i) / fadeSamples));
      }

      final val = (pink * 350 * loopFade).toInt().clamp(-32768, 32767);

      bd.setInt16(offset, val, Endian.little);
      offset += 2;
    }

    return 'data:audio/wav;base64,${base64Encode(bytes)}';
  }

  /// Generates an ethereal, warm ambient pad chord (Fmaj9 / Cmaj7 Lush Drone).
  static String createEtherealPadWavUri({
    double durationSeconds = 4.0,
    int sampleRate = 44100,
  }) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final dataSize = numSamples * 4;
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

    final chordFreqs = [87.31, 130.81, 164.81, 220.00];
    final fadeSamples = (sampleRate * 0.2).toInt();
    int offset = 44;

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;

      double sampleL = 0.0;
      double sampleR = 0.0;

      for (int k = 0; k < chordFreqs.length; k++) {
        final f = chordFreqs[k];
        final lMod = sin(2 * pi * 0.25 * t + k);
        final rMod = cos(2 * pi * 0.22 * t + k);

        sampleL += sin(2 * pi * f * t) * (0.25 + 0.05 * lMod);
        sampleR += sin(2 * pi * (f * 1.003) * t) * (0.25 + 0.05 * rMod);
      }

      double loopFade = 1.0;
      if (i < fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * i / fadeSamples));
      } else if (i > numSamples - fadeSamples) {
        loopFade = 0.5 * (1 - cos(pi * (numSamples - i) / fadeSamples));
      }

      final valL = (sampleL * 2800 * loopFade).toInt().clamp(-32768, 32767);
      final valR = (sampleR * 2800 * loopFade).toInt().clamp(-32768, 32767);

      bd.setInt16(offset, valL, Endian.little);
      bd.setInt16(offset + 2, valR, Endian.little);
      offset += 4;
    }

    return 'data:audio/wav;base64,${base64Encode(bytes)}';
  }

  /// Generates a warm, tranquil chime/piano bell WAV bytes using physical modeling & FM synthesis.
  static Uint8List createTranquilChimeWavBytes({
    double freqHz = 523.25,
    double durationSeconds = 2.5,
    int sampleRate = 48000,
    bool softPiano = false,
  }) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final dataSize = numSamples * 4;
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

    final random = Random((freqHz * 100).toInt());
    int offset = 44;

    // Pitch-based stereo pan (-0.4 for low notes, +0.4 for high notes)
    final panOffset = ((freqHz - 260.0) / 600.0).clamp(-0.4, 0.4);
    final gainL = 1.0 - panOffset;
    final gainR = 1.0 + panOffset;

    const inharmonicityB = 0.00012; // Stiff string inharmonicity factor

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;

      // 1. Attack hammer transient noise (first 12ms)
      final hammerNoise = (t < 0.012)
          ? ((random.nextDouble() * 2.0) - 1.0) *
                exp(-t * 250.0) *
                (softPiano ? 0.12 : 0.35)
          : 0.0;

      // 2. Frequency-dependent decay rates per harmonic
      final decay1 = exp(-t * 1.8); // Fundamental
      final decay2 = exp(-t * 3.2); // 2nd Harmonic
      final decay3 = exp(-t * 5.0); // 3rd Harmonic
      final decay4 = exp(-t * 8.0); // 4th Harmonic

      // Inharmonic partial frequencies
      final f1 = freqHz * sqrt(1 + inharmonicityB * 1);
      final f2 = 2.0 * freqHz * sqrt(1 + inharmonicityB * 4);
      final f3 = 3.0 * freqHz * sqrt(1 + inharmonicityB * 9);
      final f4 = 4.0 * freqHz * sqrt(1 + inharmonicityB * 16);

      // FM modulator for bell/tine resonance
      final fmMod = softPiano
          ? 0.0
          : sin(2 * pi * (freqHz * 2.76) * t) * exp(-t * 6.0) * 0.20;

      final body =
          sin(2 * pi * f1 * t + fmMod) * decay1 * (softPiano ? 0.78 : 0.65) +
          sin(2 * pi * f2 * t) * decay2 * (softPiano ? 0.16 : 0.22) +
          sin(2 * pi * f3 * t) * decay3 * (softPiano ? 0.045 : 0.10) +
          sin(2 * pi * f4 * t) * decay4 * (softPiano ? 0.015 : 0.03) +
          hammerNoise;

      final sampleL = body * gainL;
      final sampleR = body * gainR;

      final valL = (sampleL * 4200).toInt().clamp(-32768, 32767);
      final valR = (sampleR * 4200).toInt().clamp(-32768, 32767);

      bd.setInt16(offset, valL, Endian.little);
      bd.setInt16(offset + 2, valR, Endian.little);
      offset += 4;
    }

    return bytes;
  }

  /// Generates a warm, tranquil chime/piano bell with physical modeling.
  static String createTranquilChimeWavUri({
    double freqHz = 523.25,
    double durationSeconds = 2.5,
    int sampleRate = 44100,
  }) {
    return 'data:audio/wav;base64,${base64Encode(createTranquilChimeWavBytes(freqHz: freqHz, durationSeconds: durationSeconds, sampleRate: sampleRate))}';
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
