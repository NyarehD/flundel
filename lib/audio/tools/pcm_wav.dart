import 'dart:typed_data';

class PcmWav {
  static Uint8List encode(Float32List samples, {int sampleRate = 48000}) {
    final bytes = allocate(samples.length, sampleRate: sampleRate);
    final d = ByteData.sublistView(bytes);
    for (var i = 0; i < samples.length; i++) {
      d.setInt16(44 + i * 2, _pcm16(samples[i]), Endian.little);
    }
    return bytes;
  }

  /// One preallocated PCM16 buffer; native preview capture writes into it
  /// incrementally instead of retaining several copies of float PCM.
  static Uint8List allocate(int sampleCount, {int sampleRate = 48000}) {
    final bytes = Uint8List(44 + sampleCount * 2);
    final d = ByteData.sublistView(bytes);
    bytes.setRange(0, 4, 'RIFF'.codeUnits);
    d.setUint32(4, bytes.length - 8, Endian.little);
    bytes.setRange(8, 12, 'WAVE'.codeUnits);
    bytes.setRange(12, 16, 'fmt '.codeUnits);
    d.setUint32(16, 16, Endian.little);
    d.setUint16(20, 1, Endian.little);
    d.setUint16(22, 2, Endian.little);
    d.setUint32(24, sampleRate, Endian.little);
    d.setUint32(28, sampleRate * 4, Endian.little);
    d.setUint16(32, 4, Endian.little);
    d.setUint16(34, 16, Endian.little);
    bytes.setRange(36, 40, 'data'.codeUnits);
    d.setUint32(40, sampleCount * 2, Endian.little);
    return bytes;
  }

  static int _pcm16(double value) =>
      ((value.isFinite ? value : 0).clamp(-1.0, 1.0) * 32767).round();
}

/// Bounded native float-to-WAV capture. The final WAV is the sole retained PCM
/// allocation, including while completing a long listening preview.
class PcmWavCapture {
  PcmWavCapture(int sampleCount) : bytes = PcmWav.allocate(sampleCount);
  final Uint8List bytes;
  int _offset = 44;
  bool get complete => _offset == bytes.length;

  void addFloat32(Uint8List input) {
    final source = ByteData.sublistView(input);
    final target = ByteData.sublistView(bytes);
    for (var i = 0; i + 4 <= input.length && !complete; i += 4) {
      target.setInt16(
        _offset,
        PcmWav._pcm16(source.getFloat32(i, Endian.little)),
        Endian.little,
      );
      _offset += 2;
    }
  }
}
