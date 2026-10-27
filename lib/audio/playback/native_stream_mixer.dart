import 'dart:math';

import 'package:flundel/audio/generative/soundscape_renderer.dart';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// One native parent bus pauses all child stems atomically. Each child keeps
/// its own gain and routing; reverberation is already rendered per tonal stem.
class NativeStreamMixer {
  NativeStreamMixer(this.soloud);
  final SoLoud soloud;
  Bus? _transport;
  final List<AudioSource> _sources = [];
  final List<SoundHandle> _handles = [];
  int baseFrame = 0;
  int suppliedFrames = 0;
  bool paused = true;
  bool _closing = false;
  bool hadUnderrun = false;
  static const int maxFrames = 3 * 48000;
  int get activeVoices => _handles.length + (_transport == null ? 0 : 1);
  int get bufferBytes =>
      _sources.fold(0, (sum, s) => sum + soloud.getBufferSize(s));
  int get consumedFrames {
    if (_sources.isEmpty) return baseFrame;
    final positions = _sources.map(
      (s) => soloud.getStreamTimeConsumed(s).inMicroseconds * 48000 ~/ 1000000,
    );
    return baseFrame + positions.reduce(min).clamp(0, suppliedFrames);
  }

  int get queuedFrames =>
      (suppliedFrames - (consumedFrames - baseFrame)).clamp(0, maxFrames);
  int get skewFrames {
    if (_sources.isEmpty) return 0;
    final positions = _sources
        .map(
          (s) =>
              soloud.getStreamTimeConsumed(s).inMicroseconds * 48000 ~/ 1000000,
        )
        .toList();
    return positions.reduce(max) - positions.reduce(min);
  }

  Future<void> open(int frame) async {
    await close();
    _closing = false;
    baseFrame = frame;
    suppliedFrames = 0;
    hadUnderrun = false;
    paused = true;
    _transport = soloud.createMixingBus(name: 'flundel-stream-transport');
    _transport!.playOnEngine(volume: .82);
    final parent = _transport!.soundHandle!;
    soloud.setRelativePlaySpeed(parent, 48000 / 44100);
    soloud.setInaudibleBehavior(parent, true, false);
    soloud.setPause(parent, true);
    for (final _ in AudioStem.values) {
      _sources.add(
        soloud.setBufferStream(
          maxBufferSizeDuration: const Duration(seconds: 3),
          bufferingType: BufferingType.released,
          bufferingTimeNeeds: .12,
          sampleRate: 48000,
          channels: Channels.stereo,
          format: BufferType.f32le,
          onBuffering: (buffering, handle, time) {
            if (buffering && !paused) hadUnderrun = true;
          },
        ),
      );
    }
  }

  void append(RenderedAudioBlock block) {
    if (block.startFrame != baseFrame + suppliedFrames) {
      throw StateError('Noncontiguous PCM block');
    }
    if (queuedFrames + block.frames > maxFrames) {
      throw StateError('PCM queue capacity exceeded');
    }
    for (var i = 0; i < _sources.length; i++) {
      soloud.addAudioDataStream(
        _sources[i],
        block.stems[i].buffer.asUint8List(),
      );
    }
    suppliedFrames += block.frames;
  }

  void start(
    SoundscapeConfig config,
    Map<String, bool> muted,
    Map<String, bool> solo,
  ) {
    // Parent stays paused while all voices are created: a single unpause starts
    // them on exactly the same native sample, without per-voice clock races.
    if (_handles.isEmpty) {
      for (final source in _sources) {
        final handle = _transport!.play(source, volume: 0);
        soloud.setInaudibleBehavior(handle, true, false);
        _handles.add(handle);
      }
    }
    applyGains(config, muted, solo);
    setPaused(false);
  }

  void setPaused(bool value) {
    paused = value;
    if (_transport != null) soloud.setPause(_transport!.soundHandle!, value);
  }

  void applyGains(
    SoundscapeConfig config,
    Map<String, bool> muted,
    Map<String, bool> solo,
  ) {
    if (_closing) return;
    final anySolo = solo.values.any((v) => v);
    for (var i = 0; i < _handles.length; i++) {
      final stem = AudioStem.values[i];
      final allowed =
          muted[stem.control] != true &&
          (!anySolo || solo[stem.control] == true);
      soloud.fadeVolume(
        _handles[i],
        allowed ? stem.gain(config) : 0,
        const Duration(milliseconds: 180),
      );
    }
  }

  void fadeOut(Duration duration) {
    for (final h in _handles) {
      soloud.fadeVolume(h, 0, duration);
    }
  }

  Future<void> close() async {
    _closing = true;
    if (_transport != null) soloud.setPause(_transport!.soundHandle!, true);
    for (final h in _handles) {
      await soloud.stop(h);
    }
    _handles.clear();
    for (final s in _sources) {
      await soloud.disposeSource(s);
    }
    _sources.clear();
    _transport?.dispose();
    _transport = null;
    paused = true;
  }
}
