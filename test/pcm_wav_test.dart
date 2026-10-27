import 'dart:typed_data';

import 'package:flundel/audio/tools/pcm_wav.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native capture preserves stereo samples across callback partitions',
    () {
      final samples = Float32List.fromList([.25, -.5, 0, 1, -.75, .125]);
      final raw = samples.buffer.asUint8List();
      final capture = PcmWavCapture(samples.length);
      capture.addFloat32(Uint8List.sublistView(raw, 0, 8));
      expect(capture.complete, isFalse);
      capture.addFloat32(Uint8List.sublistView(raw, 8, 12));
      capture.addFloat32(Uint8List.sublistView(raw, 12));
      expect(capture.complete, isTrue);
      expect(capture.bytes, orderedEquals(PcmWav.encode(samples)));
      final header = ByteData.sublistView(capture.bytes);
      expect(header.getUint32(24, Endian.little), 48000);
      expect(header.getUint32(40, Endian.little), samples.length * 2);
    },
  );

  test('capture stops at capacity and safely encodes invalid samples', () {
    final samples = Float32List.fromList([double.nan, 2, -2, double.infinity]);
    final capture = PcmWavCapture(4);
    final result = capture.bytes;
    capture.addFloat32(samples.buffer.asUint8List());
    capture.addFloat32(Float32List(100).buffer.asUint8List());
    expect(identical(capture.bytes, result), isTrue);
    final data = ByteData.sublistView(result);
    expect(
      [
        for (var i = 44; i < result.length; i += 2)
          data.getInt16(i, Endian.little),
      ],
      [0, 32767, -32767, 0],
    );
  });

  test('one-minute preview retains only its final PCM16 allocation', () {
    final capture = PcmWavCapture(60 * 48000 * 2);
    expect(capture.bytes.length, 11520044);
    expect(capture.complete, isFalse);
  });
}
