import 'package:flundel/session/session_phase.dart';

/// Session intent. The consumed audio frame, not a wall clock, owns elapsed time.
class AudioSessionContext {
  const AudioSessionContext({
    this.presetId = 'deep_work',
    this.elapsed = Duration.zero,
    this.duration,
    this.phase = SessionPhase.settling,
    this.followTimeline = true,
  });
  factory AudioSessionContext.fromJson(Map<String, dynamic> json) =>
      AudioSessionContext(
        followTimeline: json['followTimeline'] as bool? ?? true,
        presetId: json['presetId'] as String? ?? 'deep_work',
        elapsed: Duration(
          microseconds: (json['elapsedUs'] as num?)?.toInt() ?? 0,
        ),
        duration: json['durationUs'] == null
            ? null
            : Duration(microseconds: (json['durationUs'] as num).toInt()),
        phase: SessionPhase.values.firstWhere(
          (p) => p.name == json['phase'],
          orElse: () => SessionPhase.settling,
        ),
      );
  final String presetId;
  final Duration elapsed;
  final Duration? duration;
  final SessionPhase phase;
  final bool followTimeline;
  AudioSessionContext atFrame(int frame) {
    final elapsed = Duration(microseconds: frame * 1000000 ~/ 48000);
    return AudioSessionContext(
      presetId: presetId,
      elapsed: elapsed,
      duration: duration,
      followTimeline: followTimeline,
      phase: !followTimeline
          ? phase
          : SessionPhaseX.calculatePhase(
              elapsedSeconds: elapsed.inSeconds,
              totalDurationSeconds: duration?.inSeconds,
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    'presetId': presetId,
    'elapsedUs': elapsed.inMicroseconds,
    'durationUs': duration?.inMicroseconds,
    'phase': phase.name,
    'followTimeline': followTimeline,
  };
}

class AudioPlaybackSnapshot {
  const AudioPlaybackSnapshot({
    this.consumedFrames = 0,
    this.buffering = false,
    this.queuedFrames = 0,
  });
  final int consumedFrames;
  final bool buffering;
  final int queuedFrames;
  Duration get position =>
      Duration(microseconds: consumedFrames * 1000000 ~/ 48000);
}

class AudioDiagnostics {
  const AudioDiagnostics({
    required this.playback,
    required this.underruns,
    required this.activeVoices,
    required this.bufferBytes,
    required this.renderLoad,
    this.renderedBlocks = 0,
    this.worstRenderMs = 0,
    this.overBudgetBlocks = 0,
    this.error,
  });
  final AudioPlaybackSnapshot playback;
  final int underruns;
  final int activeVoices;
  final int bufferBytes;
  final double renderLoad;
  final int renderedBlocks;
  final double worstRenderMs;
  final int overBudgetBlocks;
  final String? error;
}
