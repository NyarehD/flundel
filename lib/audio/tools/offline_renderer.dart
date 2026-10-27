import 'dart:math';
import 'dart:typed_data';

import 'package:flundel/audio/audio_session_context.dart';
import 'package:flundel/audio/generative/soundscape_renderer.dart';
import 'package:flundel/audio/tools/pcm_wav.dart';
import 'package:flundel/domain/models/soundscape_config.dart';

class OfflineRenderResult {
  const OfflineRenderResult({
    required this.wavBytes,
    required this.totalSamples,
    required this.durationSeconds,
    required this.pianoEventsTriggered,
  });
  final Uint8List wavBytes;
  final int totalSamples;
  final double durationSeconds;
  final int pianoEventsTriggered;
}

/// Uses the production planner and stateful DSP. Native final limiter and audio
/// device behavior still require a real mixer capture.
class OfflineRenderer {
  static OfflineRenderResult renderAudio({
    required SoundscapeConfig config,
    required int sessionSeed,
    double durationSeconds = 30,
    int sampleRate = 44100,
    String presetId = 'custom',
    Duration? sessionDuration,
  }) {
    if (!durationSeconds.isFinite ||
        durationSeconds <= 0 ||
        sampleRate < 8000) {
      throw ArgumentError('Invalid render duration/rate');
    }
    final renderer = SoundscapeRenderer(
      seed: sessionSeed,
      config: config,
      context: AudioSessionContext(
        presetId: presetId,
        duration: sessionDuration,
      ),
    );
    final frames = (durationSeconds * 48000).round();
    final pcm = Float32List(frames * 2);
    var events = 0;
    while (renderer.frame < frames) {
      final block = renderer.render(min(4096, frames - renderer.frame));
      events += block.events.where((e) => e.kind == 'piano').length;
      final mix = mixBlock(block, config);
      pcm.setRange(
        block.startFrame * 2,
        (block.startFrame + block.frames) * 2,
        mix,
      );
    }
    final outputFrames = (durationSeconds * sampleRate).round();
    final output = Float32List(outputFrames * 2);
    for (var frame = 0; frame < outputFrames; frame++) {
      final position = frame * 48000 / sampleRate;
      final first = position.floor().clamp(0, frames - 1);
      final last = min(frames - 1, first + 1);
      final fraction = position - first;
      for (var c = 0; c < 2; c++) {
        output[frame * 2 + c] =
            pcm[first * 2 + c] * (1 - fraction) + pcm[last * 2 + c] * fraction;
      }
    }
    return OfflineRenderResult(
      wavBytes: PcmWav.encode(output, sampleRate: sampleRate),
      totalSamples: outputFrames,
      durationSeconds: durationSeconds,
      pianoEventsTriggered: events,
    );
  }

  static Float32List mixBlock(
    RenderedAudioBlock block,
    SoundscapeConfig config, {
    double master = .9,
    Set<String> muted = const {},
    Set<String> solo = const {},
  }) {
    final output = Float32List(block.frames * 2);
    for (final stem in AudioStem.values) {
      if (muted.contains(stem.control) ||
          (solo.isNotEmpty && !solo.contains(stem.control))) {
        continue;
      }
      final gain = stem.gain(config) * master * .82;
      for (var i = 0; i < output.length; i++) {
        output[i] += block.stems[stem.index][i] * gain;
      }
    }
    return output;
  }
}
