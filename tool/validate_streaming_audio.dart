// dart run tool/validate_streaming_audio.dart [seconds-per-preset] [output-dir]
// Append --max-levels to stress every source at maximum user gain.
// Bounded memory: write one production block at a time, including a WAV preview.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flundel/audio/audio_session_context.dart';
import 'package:flundel/audio/generative/soundscape_renderer.dart';
import 'package:flundel/audio/tools/offline_renderer.dart';
import 'package:flundel/audio/tools/pcm_wav.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';

void main(List<String> args) {
  final seconds = args.isEmpty ? 180 : int.parse(args[0]);
  if (seconds < 60) throw ArgumentError('Use at least one minute per preset');
  final dir = Directory(args.length > 1 ? args[1] : 'build/audio-validation')
    ..createSync(recursive: true);
  final report = <Map<String, dynamic>>[];
  final maxLevels = args.contains('--max-levels');
  for (final preset in SoundscapePreset.builtInPresets) {
    final config = maxLevels
        ? preset.config.copyWith(
            intensity: 1,
            complexity: 1,
            pad: 1,
            piano: 1,
            noise: 1,
            nature: 1,
            wind: 1,
            water: 1,
            birds: 1,
            chimes: 1,
            beats: 1,
            bass: 1,
            binaural: 1,
          )
        : preset.config;
    final r = SoundscapeRenderer(
      seed: 42,
      config: config,
      context: AudioSessionContext(
        presetId: preset.id,
        duration: Duration(seconds: seconds),
      ),
    );
    final out = File('${dir.path}/${preset.id}.wav')
        .openSync(mode: FileMode.write);
    final header = PcmWav.encode(Float32List(0));
    final length = seconds * 48000;
    final h = ByteData.sublistView(header);
    h.setUint32(4, 36 + length * 4, Endian.little);
    h.setUint32(40, length * 4, Endian.little);
    out.writeFromSync(header);
    var peak = 0.0;
    var power = 0.0;
    var mono = 0.0;
    var dc = 0.0;
    var boundary = 0.0;
    var last = 0.0;
    var maxVoices = 0;
    var events = 0;
    final eventCounts = <String, int>{};
    final costs = <int>[];
    final watch = Stopwatch()..start();
    while (r.frame < length) {
      final block = r.render(min(4096, length - r.frame));
      costs.add(block.renderMicros);
      events += block.events.length;
      for (final event in block.events) {
        eventCounts.update(event.kind, (count) => count + 1, ifAbsent: () => 1);
      }
      final mix = OfflineRenderer.mixBlock(
        block,
        config,
        master: maxLevels ? 1 : .9,
      );
      boundary = max(boundary, (mix.first - last).abs());
      last = mix[mix.length - 2];
      for (var i = 0; i < mix.length; i += 2) {
        final l = mix[i];
        final right = mix[i + 1];
        if (!l.isFinite || !right.isFinite) {
          throw StateError('Nonfinite ${preset.id}');
        }
        peak = max(peak, max(l.abs(), right.abs()));
        power += l * l + right * right;
        dc += l + right;
        mono += pow((l + right) * .5, 2).toDouble();
      }
      out.writeFromSync(PcmWav.encode(mix), 44);
      if (r.frame % (4096 * 48) == 0) {
        final snap = r.snapshot();
        maxVoices = max(maxVoices, (snap['voices'] as List).length);
        // JSON persistence must retain the exact continuation even mid-transition.
        final restored = SoundscapeRenderer.restore(
          jsonDecode(jsonEncode(snap)) as Map<String, dynamic>,
        );
        final a = SoundscapeRenderer.restore(snap).render(257);
        final b = restored.render(257);
        for (var stem = 0; stem < a.stems.length; stem++) {
          for (var i = 0; i < a.stems[stem].length; i++) {
            if (a.stems[stem][i] != b.stems[stem][i]) {
              throw StateError('Checkpoint mismatch');
            }
          }
        }
      }
    }
    out.closeSync();
    costs.sort();
    final monoRatio = sqrt(mono / (power / 2));
    if (peak >= .89 || maxVoices > 24 || monoRatio < .5) {
      throw StateError('Mix validation failed: ${preset.id}');
    }
    final entry = <String, dynamic>{
      'preset': preset.id,
      'maxLevels': maxLevels,
      'seconds': seconds,
      'peak': peak,
      'rms': sqrt(power / (length * 2)),
      'dc': dc / (length * 2),
      'monoRmsRatio': monoRatio,
      'largestBlockBoundaryStep': boundary,
      'maxProceduralVoices': maxVoices,
      'events': events,
      'eventCounts': eventCounts,
      'chordChanges': r.planner.changes,
      'renderP50Ms': costs[costs.length ~/ 2] / 1000,
      'renderP99Ms': costs[(costs.length * .99).floor()] / 1000,
      'renderMaxMs': costs.last / 1000,
      'wallSeconds': watch.elapsedMilliseconds / 1000,
    };
    report.add(entry);
    stdout.writeln(jsonEncode(entry));
  }
  File('${dir.path}/report.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
}
