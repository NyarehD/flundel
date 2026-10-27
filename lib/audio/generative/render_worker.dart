import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:flundel/audio/audio_session_context.dart';
import 'package:flundel/audio/generative/soundscape_renderer.dart';
import 'package:flundel/domain/models/soundscape_config.dart';

/// One persistent isolate per engine. History is bounded to 2.73 seconds and
/// snapshots are reconstructed at CONSUMED frames, never the render frontier.
class RenderWorker {
  Isolate? _isolate;
  SendPort? _port;
  ReceivePort? _exit;
  StreamSubscription<dynamic>? _exitSubscription;
  bool _closed = false;
  bool get isOpen => !_closed && _port != null;
  final Set<ReceivePort> _requests = {};
  Future<void> open() async {
    if (_port != null) return;
    _closed = false;
    final ready = ReceivePort();
    _exit = ReceivePort();
    _exitSubscription = _exit!.listen((_) {
      _port = null;
      for (final request in _requests.toList()) {
        request.sendPort.send(['Render worker exited', null]);
      }
    });
    try {
      _isolate = await Isolate.spawn(
        _run,
        ready.sendPort,
        onExit: _exit!.sendPort,
      );
      _port = await ready.first.timeout(const Duration(seconds: 5)) as SendPort;
    } finally {
      ready.close();
    }
  }

  Future<T> _request<T>(String command, [Object? payload]) async {
    if (_closed || _port == null) throw StateError('Render worker closed');
    final reply = ReceivePort();
    _requests.add(reply);
    _port!.send([command, payload, reply.sendPort]);
    try {
      final result =
          await reply.first.timeout(const Duration(seconds: 30)) as List;
      if (result[0] != null) throw StateError(result[0] as String);
      return result[1] as T;
    } finally {
      _requests.remove(reply);
      reply.close();
    }
  }

  Future<void> reset({
    required SoundscapeConfig config,
    required AudioSessionContext context,
    required int seed,
    Map<String, dynamic>? checkpoint,
  }) => _request<void>('reset', [
    config.toJson(),
    context.toJson(),
    seed,
    checkpoint,
  ]);
  Future<void> update(
    SoundscapeConfig config,
    AudioSessionContext context,
    int revision, {
    double? reverb,
    double? cutoff,
  }) => _request<void>('update', [
    config.toJson(),
    context.toJson(),
    revision,
    reverb,
    cutoff,
  ]);
  Future<RenderedAudioBlock> render() => _request<RenderedAudioBlock>('render');
  Future<Map<String, dynamic>> checkpoint(int consumedFrame) =>
      _request<Map<String, dynamic>>('checkpoint', consumedFrame);
  Future<void> dispose() async {
    if (_closed) return;
    _closed = true;
    await _exitSubscription?.cancel();
    _exit?.close();
    _exitSubscription = null;
    _exit = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _port = null;
    // Port close completes first with an error instead of leaving callers hung.
    for (final p in _requests.toList()) {
      p.close();
    }
    _requests.clear();
  }

  static void _run(SendPort ready) {
    final incoming = ReceivePort();
    ready.send(incoming.sendPort);
    SoundscapeRenderer? renderer;
    final history = ListQueue<Map<String, dynamic>>();
    incoming.listen((dynamic raw) {
      final message = raw as List;
      final reply = message[2] as SendPort;
      try {
        Object? result;
        switch (message[0]) {
          case 'reset':
            final p = message[1] as List;
            final config = SoundscapeConfig.fromJson(
              Map<String, dynamic>.from(p[0] as Map),
            );
            final context = AudioSessionContext.fromJson(
              Map<String, dynamic>.from(p[1] as Map),
            );
            var restored = false;
            if (p[3] != null) {
              try {
                renderer = SoundscapeRenderer.restore(
                  Map<String, dynamic>.from(p[3] as Map),
                );
                restored = true;
              } on FormatException {
                // A previous schema retains the user's settings and position.
                // Persisted dynamic JSON is a trust boundary, not a coding error.
                // ignore: avoid_catching_errors
              } on TypeError {
                // Incomplete legacy snapshots also receive coherent new DSP.
                // ignore: avoid_catching_errors
              } on RangeError {
                // A truncated delay line must never prevent session recovery.
              }
            }
            if (!restored) {
              renderer = SoundscapeRenderer(
                seed: p[2] as int,
                config: config,
                context: context,
              );
            }
            renderer!.revision = 0;
            renderer!.update(config, context, 0);
            // Old sessions have no synthesis state. Start a coherent composition
            // at their saved elapsed frame; do not simulate hours on the UI thread.
            final savedFrame = p[3] is Map ? (p[3] as Map)['frame'] : null;
            final startFrame = savedFrame is int && savedFrame >= 0
                ? savedFrame
                : context.elapsed.inMicroseconds * 48000 ~/ 1000000;
            if (!restored && startFrame > 0) {
              renderer!.frame = startFrame;
              renderer!.planner.resetSchedule(renderer!.frame, config.beatsBpm);
            }
            history.clear();
          case 'update':
            final p = message[1] as List;
            if ((p[2] as int) < renderer!.revision) break;
            renderer!.update(
              SoundscapeConfig.fromJson(Map<String, dynamic>.from(p[0] as Map)),
              AudioSessionContext.fromJson(
                Map<String, dynamic>.from(p[1] as Map),
              ),
              p[2] as int,
            );
            if (p[3] != null) renderer!.reverb = p[3] as double;
            if (p[4] != null) renderer!.cutoffOverride = p[4] as double;
          case 'render':
            history.add(renderer!.snapshot());
            while (history.length > 32) {
              history.removeFirst();
            }
            result = renderer!.render();
          case 'checkpoint':
            final frame = message[1] as int;
            final prior = history
                .where((s) => (s['frame'] as int) <= frame)
                .lastOrNull;
            if (prior == null) {
              if (renderer!.frame != frame) {
                throw StateError('Consumed frame outside checkpoint history');
              }
              result = renderer!.snapshot();
            } else {
              final clone = SoundscapeRenderer.restore(prior);
              clone.render(frame - clone.frame);
              result = clone.snapshot();
            }
          default:
            throw ArgumentError('Unknown render request');
        }
        reply.send([null, result]);
      } on Object catch (error, stack) {
        reply.send(['$error\n$stack', null]);
      }
    });
  }
}
