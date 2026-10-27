import 'dart:math';
import 'dart:typed_data';

/// Deterministic, locally synthesized ambience beds for soundscape profiles.
class AmbienceGenerator {
  const AmbienceGenerator._();

  static Uint8List generateWindLoopWavBytes({
    int durationSeconds = 6,
    int sampleRate = 48000,
    int seed = 421,
  }) {
    final random = Random(seed);
    var lowLeft = 0.0;
    var midLeft = 0.0;
    var lowRight = 0.0;
    var midRight = 0.0;
    return _generateStereoWav(durationSeconds, sampleRate, (frame) {
      final time = frame / sampleRate;
      final gust =
          0.76 +
          0.16 * sin(2 * pi * 0.09 * time) +
          0.08 * cos(2 * pi * 0.17 * time);
      final whiteLeft = random.nextDouble() * 2 - 1;
      final whiteRight = random.nextDouble() * 2 - 1;
      lowLeft += (whiteLeft - lowLeft) * 0.018;
      midLeft += (whiteLeft - midLeft) * 0.095;
      lowRight += (whiteRight - lowRight) * 0.018;
      midRight += (whiteRight - midRight) * 0.095;
      return (
        gust * (lowLeft * 0.68 + midLeft * 0.20),
        gust * (lowRight * 0.68 + midRight * 0.20),
      );
    });
  }

  static Uint8List generateWaterLoopWavBytes({
    int durationSeconds = 6,
    int sampleRate = 48000,
    int seed = 882,
  }) {
    final random = Random(seed);
    var lowLeft = 0.0;
    var lowRight = 0.0;
    var smoothLeft = 0.0;
    var smoothRight = 0.0;
    return _generateStereoWav(durationSeconds, sampleRate, (frame) {
      final time = frame / sampleRate;
      final swell = 0.78 + 0.22 * sin(2 * pi * 0.11 * time).abs();
      final whiteLeft = random.nextDouble() * 2 - 1;
      final whiteRight = random.nextDouble() * 2 - 1;
      lowLeft += (whiteLeft - lowLeft) * 0.025;
      lowRight += (whiteRight - lowRight) * 0.025;
      smoothLeft += (whiteLeft - smoothLeft) * 0.14;
      smoothRight += (whiteRight - smoothRight) * 0.14;
      final rippleLeft = smoothLeft - lowLeft;
      final rippleRight = smoothRight - lowRight;
      return (
        swell * (lowLeft * 0.56 + rippleLeft * 0.13),
        swell * (lowRight * 0.56 + rippleRight * 0.13),
      );
    });
  }

  static Uint8List generateBirdsLoopWavBytes({
    int durationSeconds = 8,
    int sampleRate = 48000,
    int seed = 1729,
  }) {
    final random = Random(seed);
    final frameCount = durationSeconds * sampleRate;
    final left = Float64List(frameCount);
    final right = Float64List(frameCount);
    final eventCount = (durationSeconds * 0.75).round();

    for (var event = 0; event < eventCount; event++) {
      final groupStart =
          ((event + 0.5) * durationSeconds / eventCount +
                  (random.nextDouble() - 0.5) * 0.32)
              .clamp(0.2, durationSeconds - 0.65);
      final callCount = random.nextInt(2) + 1;
      for (var call = 0; call < callCount; call++) {
        final startSeconds =
            groupStart + call * (0.16 + random.nextDouble() * 0.08);
        final lengthSeconds = 0.13 + random.nextDouble() * 0.15;
        final startFrequency = 1900 + random.nextDouble() * 900;
        final endFrequency = 1500 + random.nextDouble() * 900;
        final pan = random.nextDouble() * 0.7 - 0.35;
        final amplitude = 0.22 + random.nextDouble() * 0.12;
        final startFrame = (startSeconds * sampleRate).round();
        final callFrames = (lengthSeconds * sampleRate).round();

        for (var index = 0; index < callFrames; index++) {
          final frame = startFrame + index;
          if (frame >= frameCount) break;
          final progress = index / callFrames;
          final seconds = progress * lengthSeconds;
          final phase =
              2 *
              pi *
              (startFrequency * seconds +
                  (endFrequency - startFrequency) *
                      seconds *
                      seconds /
                      (2 * lengthSeconds));
          final envelope = pow(sin(pi * progress), 1.5).toDouble();
          final tone =
              (sin(phase) + 0.18 * sin(phase * 2.03)) * amplitude * envelope;
          left[frame] += tone * (1 - pan);
          right[frame] += tone * (1 + pan);
        }
      }
    }

    return _generateStereoWav(
      durationSeconds,
      sampleRate,
      (frame) => (left[frame], right[frame]),
    );
  }

  static Uint8List _generateStereoWav(
    int durationSeconds,
    int sampleRate,
    (double, double) Function(int frame) sampleAt,
  ) {
    final frameCount = durationSeconds * sampleRate;
    final dataSize = frameCount * 4;
    final bytes = Uint8List(44 + dataSize);
    final data = ByteData.sublistView(bytes);
    bytes.setRange(0, 4, [82, 73, 70, 70]); // RIFF
    data.setUint32(4, bytes.length - 8, Endian.little);
    bytes.setRange(8, 12, [87, 65, 86, 69]); // WAVE
    bytes.setRange(12, 16, [102, 109, 116, 32]); // fmt
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 2, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 4, Endian.little);
    data.setUint16(32, 4, Endian.little);
    data.setUint16(34, 16, Endian.little);
    bytes.setRange(36, 40, [100, 97, 116, 97]); // data
    data.setUint32(40, dataSize, Endian.little);

    for (var frame = 0; frame < frameCount; frame++) {
      final (left, right) = sampleAt(frame);
      data.setInt16(
        44 + frame * 4,
        (left * 32767).round().clamp(-32768, 32767),
        Endian.little,
      );
      data.setInt16(
        46 + frame * 4,
        (right * 32767).round().clamp(-32768, 32767),
        Endian.little,
      );
    }
    return bytes;
  }
}
