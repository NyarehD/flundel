// dart run tool/audio_balance_report.dart [seconds] [output-dir]
// Renders every built-in preset through the production renderer and reports
// bed/foreground balance, note-onset level, and per-stem gain. Also writes a
// stereo WAV per preset so before/after revisions can be compared by ear.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flundel/audio/audio_session_context.dart';
import 'package:flundel/audio/generative/soundscape_renderer.dart';
import 'package:flundel/audio/tools/offline_renderer.dart';
import 'package:flundel/audio/tools/pcm_wav.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';

const _bedStems = {
  AudioStem.pad,
  AudioStem.noise,
  AudioStem.nature,
  AudioStem.wind,
  AudioStem.water,
  AudioStem.birds,
};

const _foregroundStems = {
  AudioStem.piano,
  AudioStem.chimes,
  AudioStem.beats,
  AudioStem.bass,
};

const _onsetFrames = 19200; // 400 ms, long enough to average a piano attack.

void main(List<String> args) {
  final seconds = args.isEmpty ? 60 : int.parse(args[0]);
  if (seconds < 10) throw ArgumentError('Use at least ten seconds per preset');
  final dir = Directory(args.length > 1 ? args[1] : 'build/audio-balance')
    ..createSync(recursive: true);
  final report = <Map<String, dynamic>>[];
  for (final preset in SoundscapePreset.builtInPresets) {
    final config = preset.config;
    final renderer = SoundscapeRenderer(
      seed: 42,
      config: config,
      context: AudioSessionContext(
        presetId: preset.id,
        duration: Duration(seconds: seconds),
      ),
    );
    final length = seconds * 48000;
    final mix = Float32List(length * 2);
    final power = List<double>.filled(AudioStem.values.length, 0);
    final peak = List<double>.filled(AudioStem.values.length, 0);
    final onsetPower = List<double>.filled(AudioStem.values.length, 0);
    final onsetPeak = List<double>.filled(AudioStem.values.length, 0);
    final onsetCount = List<int>.filled(AudioStem.values.length, 0);
    final onsetFrames = List<int>.filled(AudioStem.values.length, 0);
    final onsetEnd = List<int>.filled(AudioStem.values.length, 0);
    final eventCounts = <String, int>{};
    var samplePeak = 0.0;
    var samplePower = 0.0;
    while (renderer.frame < length) {
      final block = renderer.render(min(4096, length - renderer.frame));
      final blockMix = OfflineRenderer.mixBlock(block, config);
      mix.setRange(
        block.startFrame * 2,
        (block.startFrame + block.frames) * 2,
        blockMix,
      );
      for (var s = 0; s < block.stems.length; s++) {
        final stem = block.stems[s];
        for (var i = 0; i < stem.length; i++) {
          final value = stem[i];
          power[s] += value * value;
          peak[s] = max(peak[s], value.abs());
        }
      }
      for (final event in block.events) {
        eventCounts.update(event.kind, (v) => v + 1, ifAbsent: () => 1);
        final stem = switch (event.kind) {
          'piano' => AudioStem.piano.index,
          'chime' => AudioStem.chimes.index,
          'pulse' || 'kick' || 'snare' || 'hat' => AudioStem.beats.index,
          'bass' => AudioStem.bass.index,
          _ => null,
        };
        if (stem == null) continue;
        onsetCount[stem]++;
        onsetEnd[stem] = max(onsetEnd[stem], event.frame + _onsetFrames);
      }
      for (var frame = block.startFrame; frame < renderer.frame; frame++) {
        final local = frame - block.startFrame;
        for (var s = 0; s < block.stems.length; s++) {
          if (frame >= onsetEnd[s]) continue;
          final l = block.stems[s][local * 2];
          final r = block.stems[s][local * 2 + 1];
          onsetPower[s] += l * l + r * r;
          onsetPeak[s] = max(onsetPeak[s], max(l.abs(), r.abs()));
          onsetFrames[s]++;
        }
      }
      for (var i = 0; i < blockMix.length; i++) {
        samplePeak = max(samplePeak, blockMix[i].abs());
        samplePower += blockMix[i] * blockMix[i];
      }
    }
    File('${dir.path}/${preset.id}.wav')
        .writeAsBytesSync(PcmWav.encode(mix), flush: true);
    double db(double value) => 20 * log(max(1e-12, value)) / ln10;
    final stemGains = [
      for (final stem in AudioStem.values) stem.gain(config) * .82 * .9,
    ];
    final stems = <String, Map<String, dynamic>>{};
    var bedPower = 0.0;
    var foregroundPower = 0.0;
    for (final stem in AudioStem.values) {
      final raw = sqrt(power[stem.index] / (length * 2));
      final mixed = raw * stemGains[stem.index];
      if (_bedStems.contains(stem)) bedPower += mixed * mixed;
      if (_foregroundStems.contains(stem)) foregroundPower += mixed * mixed;
      final onsetRms = onsetCount[stem.index] == 0
          ? null
          : sqrt(onsetPower[stem.index] / (onsetFrames[stem.index] * 2)) *
                stemGains[stem.index];
      stems[stem.name] = {
        'rawRmsDbfs': db(raw),
        'mixedRmsDbfs': db(mixed),
        'gainDbfs': db(stemGains[stem.index]),
        'onsetRmsDbfs': onsetRms == null
            ? null
            : db(onsetRms),
        'onsetPeakDbfs': onsetCount[stem.index] == 0
            ? null
            : db(onsetPeak[stem.index] * stemGains[stem.index]),
        'onsetCount': onsetCount[stem.index],
      };
    }
    final bed = sqrt(bedPower);
    final foreground = sqrt(foregroundPower);
    final pianoStem = stems['piano']!;
    final entry = <String, dynamic>{
      'preset': preset.id,
      'seconds': seconds,
      'peak': samplePeak,
      'peakDbfs': db(samplePeak),
      'rmsDbfs': 10 * log(samplePower / (length * 2)) / ln10,
      'bedRmsDbfs': db(bed),
      'foregroundRmsDbfs': db(foreground),
      'bedToForegroundDb': db(bed) - db(foreground),
      'bedToPianoOnsetDb': pianoStem['onsetRmsDbfs'] == null
          ? null
          : db(bed) - (pianoStem['onsetRmsDbfs'] as double),
      'eventCounts': eventCounts,
      'stems': stems,
    };
    report.add(entry);
    stdout.writeln(
      '${preset.id.padRight(14)} '
      'bed=${entry['bedRmsDbfs'].toStringAsFixed(1)} '
      'fg=${entry['foregroundRmsDbfs'].toStringAsFixed(1)} '
      'gap=${entry['bedToForegroundDb'].toStringAsFixed(1)} '
      'pianoOnset=${pianoStem['onsetRmsDbfs']} '
      'bed-piano=${entry['bedToPianoOnsetDb']?.toStringAsFixed(1)} '
      'peak=${entry['peak'].toStringAsFixed(3)}',
    );
  }
  File('${dir.path}/report.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
}
