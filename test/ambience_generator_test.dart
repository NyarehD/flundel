import 'dart:typed_data';

import 'package:flundel/audio/dsp/ambience_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ambience generators produce deterministic stereo PCM WAVs', () {
    final generators = <Uint8List Function()>[
      AmbienceGenerator.generateWindLoopWavBytes,
      AmbienceGenerator.generateWaterLoopWavBytes,
      AmbienceGenerator.generateBirdsLoopWavBytes,
    ];

    for (final generate in generators) {
      final first = generate();
      final second = generate();
      expect(first, equals(second));
      expect(String.fromCharCodes(first.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(first.sublist(8, 12)), 'WAVE');

      final data = ByteData.sublistView(first);
      expect(data.getUint16(22, Endian.little), 2);
      expect(data.getUint32(24, Endian.little), 48000);
      expect(data.getUint16(34, Endian.little), 16);
      expect(first.skip(44).any((sample) => sample != 0), isTrue);
    }
  });
}
