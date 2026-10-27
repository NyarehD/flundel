// flutter run -d <native-device> -t tool/focus_audio_probe.dart
// Add --dart-define=AUDIO_SOAK_SECONDS=1800 for a 30-minute native soak.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flundel/audio/audio_engine_impl.dart';
import 'package:flundel/audio/audio_session_context.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SizedBox.shrink());
  var stallNextRender = false;
  final engine = AudioEngineImpl(
    beforeRender: () async {
      if (stallNextRender) {
        stallNextRender = false;
        await Future<void>.delayed(const Duration(seconds: 3));
      }
    },
  );
  final directory = await Directory.systemTemp.createTemp(
    'flundel-stream-probe-',
  );
  final report = <String, dynamic>{
    'platform': Platform.operatingSystem,
    'presets': <Map<String, dynamic>>[],
  };
  void check(bool condition, String message) {
    if (!condition) throw StateError(message);
  }

  Future<Map<String, dynamic>> capture(String name, int seconds) async {
    final bytes = await engine.captureOutputPreview(Duration(seconds: seconds));
    await File('${directory.path}/$name.wav').writeAsBytes(bytes);
    final d = ByteData.sublistView(bytes);
    var peak = 0.0;
    var power = 0.0;
    for (var i = 44; i < bytes.length; i += 2) {
      final v = d.getInt16(i, Endian.little) / 32768;
      peak = max(peak, v.abs());
      power += v * v;
    }
    final rms = sqrt(power / ((bytes.length - 44) / 2));
    check(peak < .999, 'Clipped mixer output: $name');
    return {'peak': peak, 'rms': rms};
  }

  try {
    await engine.initialize();
    final deep = SoundscapePreset.builtInPresets.first;
    await engine.start(
      deep.config,
      context: AudioSessionContext(presetId: deep.id),
    );
    await Future<void>.delayed(const Duration(seconds: 4));
    debugPrint('STREAM_DIAGNOSTICS: ${jsonEncode(engine.getDiagnostics())}');
    // Long enough to audition phrase spacing and the first chord crossfade.
    report['deepWork'] = await capture('deep-work', 45);
    check(
      ((report['deepWork'] as Map<String, dynamic>)['rms'] as num).toDouble() >
          0.001,
      'Silent stream',
    );
    stallNextRender = true;
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    check(
      engine.playbackSnapshot.buffering,
      'Slow producer did not pause transport',
    );
    final stalledPosition = engine.playbackSnapshot.consumedFrames;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    check(
      engine.playbackSnapshot.consumedFrames == stalledPosition,
      'Buffering advanced session time',
    );
    await Future<void>.delayed(const Duration(seconds: 3));
    check(!engine.playbackSnapshot.buffering, 'Transport failed to recover');
    check(
      engine.playbackSnapshot.consumedFrames > stalledPosition,
      'Recovered transport did not advance',
    );
    check(
      engine.getDiagnostics()['stemSkewFrames'] == 0,
      'Stems lost synchronization',
    );
    report['forcedStall'] = engine.getDiagnostics();
    // Deliberately block the Dart consumer so native PCM genuinely runs out.
    final beforeGap = engine.playbackSnapshot;
    final recoveries = engine.diagnostics.underruns;
    sleep(const Duration(seconds: 2));
    final afterGap = engine.playbackSnapshot;
    check(
      afterGap.consumedFrames - beforeGap.consumedFrames <=
          beforeGap.queuedFrames + 2048,
      'Underrun counted silent time as musical progress',
    );
    await Future<void>.delayed(const Duration(seconds: 3));
    check(engine.diagnostics.error == null, 'Native underrun recovery failed');
    check(
      engine.diagnostics.underruns > recoveries,
      'Native underrun was not detected',
    );
    check(
      engine.getDiagnostics()['stemSkewFrames'] == 0,
      'Underrun left stem skew',
    );
    report['actualUnderrun'] = engine.getDiagnostics();
    await engine.updateConfig(deep.config.copyWith(pad: .5, warmth: .8));
    await engine.pause();
    final position = engine.playbackSnapshot.consumedFrames;
    final checkpoint = await engine.captureCheckpoint();
    check(
      checkpoint['frame'] == position,
      'Checkpoint is not at consumed position',
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    check(
      engine.playbackSnapshot.consumedFrames == position,
      'Paused timeline advanced',
    );
    await engine.resume();
    await Future<void>.delayed(const Duration(seconds: 2));
    check(
      engine.playbackSnapshot.consumedFrames > position,
      'Resume did not advance',
    );
    await engine.stop();
    await engine.start(
      deep.config,
      context: AudioSessionContext(presetId: deep.id),
      checkpoint: checkpoint,
      startPaused: true,
    );
    check(
      engine.getDiagnostics()['state'] == 'paused',
      'Restore was not paused',
    );
    check(
      engine.playbackSnapshot.consumedFrames == position,
      'Restore position changed',
    );
    await Future<void>.delayed(const Duration(seconds: 1));
    check(
      engine.playbackSnapshot.consumedFrames == position,
      'Restored session advanced before Play',
    );
    await engine.resume();
    await engine.updateConfig(deep.config.copyWith(intensity: 0));
    await Future<void>.delayed(const Duration(seconds: 1));
    final silence = await capture('muted', 1);
    check((silence['peak'] as double) == 0, 'Zero intensity not silent');
    await engine.updateConfig(deep.config);
    engine.setLayerSolo('pad', true);
    engine.setLayerMuted('pad', true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final soloMuted = await capture('solo-muted', 1);
    check((soloMuted['peak'] as double) == 0, 'Mute did not override solo');
    engine.setLayerMuted('pad', false);
    engine.setMasterVolume(0);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    check(
      (await capture('master-zero', 1))['peak'] == 0,
      'Master zero not silent',
    );
    engine.setMasterVolume(.9);
    engine.setLayerSolo('pad', false);
    for (var i = 0; i < 12; i++) {
      await engine.updateConfig(
        deep.config.copyWith(warmth: i.isEven ? .2 : .8),
      );
    }
    check(engine.diagnostics.error == null, 'Rapid controls failed');
    await engine.stop();
    for (final preset in SoundscapePreset.builtInPresets) {
      await engine.start(
        preset.config,
        context: AudioSessionContext(presetId: preset.id),
      );
      await Future<void>.delayed(const Duration(seconds: 3));
      final measurement = await capture(preset.id, 2);
      check((measurement['rms'] as double) > 0, 'Silent ${preset.id}');
      (report['presets'] as List).add({
        'id': preset.id,
        ...measurement,
        ...engine.getDiagnostics(),
      });
      await engine.stop();
      check(engine.diagnostics.activeVoices == 0, 'Leaked native voices');
    }
    stallNextRender = true;
    final staleStart = engine.start(
      deep.config,
      context: AudioSessionContext(presetId: deep.id),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final stopDuringRender = engine.stop();
    await Future.wait([staleStart, stopDuringRender]);
    check(
      engine.diagnostics.activeVoices == 0,
      'Stale worker result restarted audio',
    );
    await engine.start(
      deep.config,
      context: AudioSessionContext(presetId: deep.id),
    );
    const soakSeconds = int.fromEnvironment('AUDIO_SOAK_SECONDS');
    final watch = Stopwatch()..start();
    var maxRss = ProcessInfo.currentRss;
    var maxBuffer = 0;
    while (watch.elapsed.inSeconds < soakSeconds) {
      await Future<void>.delayed(const Duration(seconds: 10));
      final d = engine.diagnostics;
      maxRss = max(maxRss, ProcessInfo.currentRss);
      maxBuffer = max(maxBuffer, d.bufferBytes);
      check(d.error == null, 'Runtime error: ${d.error}');
      check(d.activeVoices <= 12, 'Voice accumulation');
      check(d.bufferBytes <= 11 * 3 * 48000 * 8, 'Native buffer overflow');
      await engine.captureCheckpoint();
      await File('${directory.path}/progress.json').writeAsString(
        jsonEncode({
          'seconds': watch.elapsed.inSeconds,
          ...engine.getDiagnostics(),
        }),
      );
      if (watch.elapsed.inSeconds % 60 < 10) {
        debugPrint(
          'STREAM_SOAK: ${watch.elapsed.inSeconds}s ${jsonEncode(engine.getDiagnostics())}',
        );
      }
    }
    report['soak'] = {
      'seconds': watch.elapsed.inSeconds,
      'maxProcessRss': maxRss,
      'maxBufferBytes': maxBuffer,
      ...engine.getDiagnostics(),
    };
    await engine.playCompletionCue();
    await engine.stop();
    await File('${directory.path}/report.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
    debugPrint('STREAM_PROBE_PASS: ${directory.path}');
  } on Object catch (error, stack) {
    debugPrint('STREAM_PROBE_FAIL: $error\n$stack\n${engine.getDiagnostics()}');
    await File('${directory.path}/failure.json').writeAsString(
      jsonEncode({'error': '$error', ...engine.getDiagnostics()}),
    );
  } finally {
    await engine.dispose();
    final disposed = engine.getDiagnostics();
    await File('${directory.path}/disposal.json')
        .writeAsString(jsonEncode(disposed));
    check(
      disposed['nativeVoiceCount'] == 0 &&
          disposed['workerRunning'] == false &&
          disposed['nativeInitialized'] == false,
      'Audio resources survived disposal',
    );
  }
}
