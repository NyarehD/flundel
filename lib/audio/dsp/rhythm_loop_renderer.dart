import 'dart:math';
import 'dart:typed_data';

import 'package:flundel/audio/procedural/harmony_controller.dart';

/// A serializable, immutable set of loop stems rendered without Flutter APIs.
class RhythmLoopBank {
  final Uint8List drumsWav;
  final Map<ChordType, Uint8List> bassWavs;
  final int frameCount;
  final int sampleRate;

  const RhythmLoopBank({
    required this.drumsWav,
    required this.bassWavs,
    required this.frameCount,
    required this.sampleRate,
  });

  Duration get duration => Duration(
    microseconds: (frameCount * Duration.microsecondsPerSecond / sampleRate)
        .round(),
  );
}

/// Offline four-bar, swung lo-fi rhythm and bass renderer.
class RhythmLoopRenderer {
  static const _chordRoots = <ChordType, double>{
    ChordType.am7: 55.0,
    ChordType.am9: 55.0,
    ChordType.cMaj7: 65.406,
    ChordType.cMaj9: 65.406,
    ChordType.fMaj7: 43.654,
    ChordType.fMaj7Sharp11: 43.654,
    ChordType.em7: 41.203,
    ChordType.dMaj7: 73.416,
  };

  static RhythmLoopBank render({
    required int bpm,
    required int seed,
    int sampleRate = 48000,
  }) {
    if (bpm < 60 || bpm > 100 || sampleRate != 48000) {
      throw ArgumentError('bpm must be 60..100 and sampleRate must be 48000');
    }
    final frames = (sampleRate * 60 * 16 / bpm).round();
    final random = Random(seed);
    final events = _makeEvents(bpm, frames, sampleRate, random);
    final drums = _renderDrums(events, frames, sampleRate, seed);
    final bass = <ChordType, Uint8List>{};
    for (final chord in ChordType.values) {
      bass[chord] = _renderBass(
        events,
        frames,
        sampleRate,
        _chordRoots[chord]!,
      );
    }
    return RhythmLoopBank(
      drumsWav: drums,
      bassWavs: Map.unmodifiable(bass),
      frameCount: frames,
      sampleRate: sampleRate,
    );
  }

  static List<_Hit> _makeEvents(
    int bpm,
    int frames,
    int sampleRate,
    Random random,
  ) {
    final beatFrames = sampleRate * 60 / bpm;
    final hits = <_Hit>[];
    // Four bars, eight eighth-notes per bar. Place each event from rational
    // beat positions so rounding never accumulates across the loop.
    for (var eighth = 0; eighth < 32; eighth++) {
      final beat = eighth / 2 + (eighth.isOdd ? 0.12 : 0.0);
      final frame = (beat * beatFrames).round() % frames;
      final beatInBar = eighth % 8 ~/ 2;
      final bar = eighth ~/ 8;
      final isDownbeat = eighth % 8 == 0;
      final kick =
          isDownbeat ||
          eighth % 8 == 4 ||
          (eighth % 8 == 6 && (bar == 1 || bar == 3));
      final snare = eighth % 8 == 2 || eighth % 8 == 6;
      final hat = eighth % 2 == 0 || (eighth % 8 == 3 && bar.isOdd);
      final variation = bar == 3 && (eighth == 29 || eighth == 31);
      final variationKick = variation && eighth == 29;
      final timing = isDownbeat
          ? 0
          : random.nextInt((sampleRate * 0.004).round() + 1) -
                (sampleRate * 0.002).round();
      final velocity = isDownbeat ? 1.0 : 0.87 + random.nextDouble() * 0.13;
      hits.add(
        _Hit(
          frame: (frame + timing) % frames,
          kick: kick || variationKick,
          snare: snare,
          hat: hat || variation,
          velocity: velocity,
          beat: beatInBar,
        ),
      );
    }
    return hits;
  }

  static Uint8List _renderDrums(List<_Hit> hits, int frames, int sr, int seed) {
    final out = List<double>.filled(frames * 2, 0);
    for (var e = 0; e < hits.length; e++) {
      final hit = hits[e];
      if (hit.kick) {
        _addWrapped(out, frames, sr, hit.frame, (t, _) {
          final env = exp(-t * 8.8);
          final phase = 2 * pi * (48 * t + 92 * (1 - exp(-t * 24)) / 24);
          return sin(phase) *
              env *
              _terminalFade(t, 0.32, 0.024) *
              0.78 *
              hit.velocity;
        }, 0.32);
      }
      if (hit.snare) {
        final noise = Random(seed ^ (e * 0x9e3779b));
        final tonePhase = noise.nextDouble() * 2 * pi;
        _addWrapped(out, frames, sr, hit.frame, (t, _) {
          final n = noise.nextDouble() * 2 - 1;
          final env = exp(-t * 16);
          final body = sin(2 * pi * 185 * t + tonePhase) * exp(-t * 11) * 0.26;
          return (n * 0.22 + body) *
              env *
              _terminalFade(t, 0.22, 0.018) *
              hit.velocity;
        }, 0.22);
      }
      if (hit.hat) {
        final noise = Random(seed ^ (e * 0x27d4eb2d));
        var previous = 0.0;
        _addWrapped(out, frames, sr, hit.frame, (t, _) {
          final white = noise.nextDouble() * 2 - 1;
          final high = white - previous * 0.72;
          previous = white;
          return high *
              exp(-t * 62) *
              _terminalFade(t, 0.085, 0.012) *
              0.065 *
              hit.velocity;
        }, 0.085);
      }
    }
    return _wav(_normalize(out, -22, -6), sr);
  }

  static Uint8List _renderBass(
    List<_Hit> hits,
    int frames,
    int sr,
    double root,
  ) {
    final out = List<double>.filled(frames * 2, 0);
    for (var i = 0; i < hits.length; i++) {
      final h = hits[i];
      // Bass accents track the kick, with occasional fifth and octave pickups.
      if (!h.kick && !(h.beat == 2 && i % 4 == 0)) continue;
      final note = (i % 8 == 6) ? root * 1.5 : (i % 8 == 4 ? root * 2 : root);
      final amplitude = h.kick ? 0.72 : 0.44;
      _addWrapped(out, frames, sr, h.frame, (t, _) {
        final attack = min(1.0, t / 0.012);
        final release = exp(-t * 3.3) * _terminalFade(t, 0.43, 0.07);
        final envelope = attack * release;
        final p = 2 * pi * note * t;
        // Fundamental plus audible second/third harmonics for small speakers.
        return (sin(p) + 0.28 * sin(2 * p) + 0.09 * sin(3 * p)) *
            envelope *
            amplitude *
            h.velocity;
      }, 0.43);
    }
    return _wav(_normalize(out, -24, -6), sr);
  }

  static double _terminalFade(double t, double duration, double fadeSeconds) {
    final start = duration - fadeSeconds;
    if (t <= start) return 1;
    return 0.5 * (1 + cos(pi * ((t - start) / fadeSeconds).clamp(0.0, 1.0)));
  }

  static void _addWrapped(
    List<double> out,
    int frames,
    int sr,
    int start,
    double Function(double time, int sample) voice,
    double seconds,
  ) {
    final length = (sr * seconds).ceil();
    for (var i = 0; i < length; i++) {
      final t = i / sr;
      final frame = (start + i) % frames;
      final value = voice(t, i);
      out[frame * 2] += value;
      out[frame * 2 + 1] += value;
    }
  }

  static List<double> _normalize(
    List<double> data,
    double rmsDb,
    double peakDb,
  ) {
    // Remove DC from the mono-equivalent signal before level calibration.
    var mean = 0.0;
    for (var i = 0; i < data.length; i += 2) {
      mean += data[i];
    }
    mean /= data.length ~/ 2;
    var sumSquares = 0.0;
    var peak = 0.0;
    for (var i = 0; i < data.length; i += 2) {
      final v = data[i] -= mean;
      data[i + 1] = v;
      sumSquares += v * v;
      peak = max(peak, v.abs());
    }
    final rms = sqrt(sumSquares / (data.length ~/ 2));
    if (rms == 0) return data;
    final targetRms = pow(10, rmsDb / 20).toDouble();
    final maxPeak = pow(10, peakDb / 20).toDouble();
    final gain = min(targetRms / rms, maxPeak / peak);
    for (var i = 0; i < data.length; i++) {
      data[i] *= gain;
    }
    return data;
  }

  static Uint8List _wav(List<double> samples, int sr) {
    final bytes = Uint8List(44 + samples.length * 2);
    final bd = ByteData.sublistView(bytes);
    bytes.setRange(0, 4, 'RIFF'.codeUnits);
    bd.setUint32(4, bytes.length - 8, Endian.little);
    bytes.setRange(8, 12, 'WAVE'.codeUnits);
    bytes.setRange(12, 16, 'fmt '.codeUnits);
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, 2, Endian.little);
    bd.setUint32(24, sr, Endian.little);
    bd.setUint32(28, sr * 4, Endian.little);
    bd.setUint16(32, 4, Endian.little);
    bd.setUint16(34, 16, Endian.little);
    bytes.setRange(36, 40, 'data'.codeUnits);
    bd.setUint32(40, samples.length * 2, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      bd.setInt16(
        44 + i * 2,
        (samples[i] * 32767).round().clamp(-32768, 32767),
        Endian.little,
      );
    }
    return bytes;
  }
}

class _Hit {
  final int frame;
  final bool kick;
  final bool snare;
  final bool hat;
  final double velocity;
  final int beat;

  const _Hit({
    required this.frame,
    required this.kick,
    required this.snare,
    required this.hat,
    required this.velocity,
    required this.beat,
  });
}
