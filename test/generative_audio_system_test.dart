import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flundel/audio/audio_session_context.dart';
import 'package:flundel/audio/generative/arrangement_profile.dart';
import 'package:flundel/audio/generative/composition_planner.dart';
import 'package:flundel/audio/generative/render_worker.dart';
import 'package:flundel/audio/generative/soundscape_renderer.dart';
import 'package:flundel/audio/playback/playback_lifecycle.dart';
import 'package:flundel/audio/tools/offline_renderer.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';
import 'package:flundel/session/session_phase.dart';
import 'package:flutter_test/flutter_test.dart';

SoundscapeRenderer renderer() => SoundscapeRenderer(
  seed: 42,
  config: SoundscapePreset.builtInPresets.first.config,
  context: const AudioSessionContext(),
);

void main() {
  test('rendering is identical across arbitrary block boundaries', () {
    final a = renderer();
    final b = renderer();
    final expected = a.render(12000);
    final parts = [b.render(19), b.render(4081), b.render(7900)];
    for (final stem in AudioStem.values) {
      expect(
        parts.expand((p) => p.stems[stem.index]),
        orderedEquals(expected.stems[stem.index]),
        reason: stem.name,
      );
    }
    expect(jsonEncode(a.snapshot()), jsonEncode(b.snapshot()));
  });
  test('JSON checkpoints restore oscillator, random, envelope and tail state exactly', () {
    final original = renderer();
    for (var i = 0; i < 48; i++) {
      original.render();
    }
    final restored = SoundscapeRenderer.restore(
      Map<String, dynamic>.from(
        jsonDecode(jsonEncode(original.snapshot())) as Map,
      ),
    );
    final a = original.render();
    final b = restored.render();
    for (var i = 0; i < a.stems.length; i++) {
      expect(a.stems[i], orderedEquals(b.stems[i]));
    }
    expect(jsonEncode(original.snapshot()), jsonEncode(restored.snapshot()));
  });
  test('muting layers does not change composition or phase', () {
    final a = renderer();
    final b = renderer();
    for (var i = 0; i < 40; i++) {
      final dry = a.render();
      final muted = b.render();
      final output = OfflineRenderer.mixBlock(
        muted,
        b.config,
        muted: {'piano', 'nature', 'beats'},
      );
      expect(output.every((v) => v.isFinite), isTrue);
      expect(dry.stems[0], orderedEquals(muted.stems[0]));
    }
    expect(jsonEncode(a.snapshot()), jsonEncode(b.snapshot()));
  });
  test('older pad snapshots restore without losing the consumed position', () {
    final original = renderer();
    original.render(8192);
    final legacy = original.snapshot();
    for (final key in ['pad', 'oldPad']) {
      legacy[key] = (legacy[key]! as List)
          .map((voice) => (voice as List).take(4).toList())
          .toList();
    }
    final restored = SoundscapeRenderer.restore(legacy);
    expect(restored.frame, 8192);
    final block = restored.render();
    expect(block.startFrame, 8192);
    expect(block.stems.expand((stem) => stem).every((v) => v.isFinite), isTrue);
    final resumed = SoundscapeRenderer.restore(restored.snapshot());
    expect(
      resumed.render().stems[0],
      orderedEquals(restored.render().stems[0]),
    );
  });
  test('all profiles render finite, unclipped stereo with bounded voices', () {
    expect(
      ArrangementProfile.profiles.keys,
      unorderedEquals(SoundscapePreset.builtInPresets.map((p) => p.id)),
    );
    for (final preset in SoundscapePreset.builtInPresets) {
      final r = SoundscapeRenderer(
        seed: 91,
        config: preset.config,
        context: AudioSessionContext(presetId: preset.id),
      );
      var peak = 0.0;
      var power = 0.0;
      for (var b = 0; b < 50; b++) {
        final block = r.render();
        final mix = OfflineRenderer.mixBlock(block, preset.config);
        for (final v in mix) {
          expect(v.isFinite, isTrue);
          peak = max(peak, v.abs());
          power += v * v;
        }
      }
      expect(peak, lessThan(.89), reason: preset.id);
      expect(power, greaterThan(0), reason: preset.id);
      expect((r.snapshot()['voices'] as List).length, lessThanOrEqualTo(24));
    }
  });
  test('binaural channels are isolated sine carriers with no wet tails', () {
    final r = renderer();
    final block = r.render(10000);
    final samples = block.stems[AudioStem.binaural.index];
    final beat = r.config.warmth >= .75 ? 6 : 10;
    for (final frame in [0, 199, 2048, 9999]) {
      expect(
        samples[frame * 2],
        closeTo(sin(2 * pi * 180 * (frame + 1) / 48000) * .32, 1e-6),
      );
      expect(
        samples[frame * 2 + 1],
        closeTo(sin(2 * pi * (180 + beat) * (frame + 1) / 48000) * .32, 1e-6),
      );
    }
  });
  test('zero intensity, mute and solo are deterministic mixer controls', () {
    final r = renderer();
    final block = r.render();
    expect(
      OfflineRenderer.mixBlock(block, r.config.copyWith(intensity: 0)),
      everyElement(0),
    );
    final solo = OfflineRenderer.mixBlock(block, r.config, solo: {'pad'});
    final gain = AudioStem.pad.gain(r.config) * .9 * .82;
    for (var i = 0; i < solo.length; i++) {
      expect(solo[i], closeTo(block.stems[0][i] * gain, 1e-7));
    }
  });
  test(
    'native worker checkpoint uses consumed rather than render-ahead position',
    () async {
      final worker = RenderWorker();
      await worker.open();
      addTearDown(worker.dispose);
      final config = SoundscapePreset.builtInPresets.first.config;
      await worker.reset(
        config: config,
        context: const AudioSessionContext(),
        seed: 42,
      );
      final blocks = <RenderedAudioBlock>[];
      for (var i = 0; i < 12; i++) {
        blocks.add(await worker.render());
      }
      final snap = await worker.checkpoint(8001);
      expect(snap['frame'], 8001);
      final exact = renderer()..render(8001);
      expect(jsonEncode(snap), jsonEncode(exact.snapshot()));
      final restored = SoundscapeRenderer.restore(snap);
      final expected = exact.render();
      final actual = restored.render();
      expect(actual.stems[0], orderedEquals(expected.stems[0]));
    },
  );
  test(
    'old checkpoint schemas preserve position with reconstructed DSP',
    () async {
      final worker = RenderWorker();
      await worker.open();
      addTearDown(worker.dispose);
      await worker.reset(
        config: renderer().config,
        context: const AudioSessionContext(),
        seed: 19,
        checkpoint: {'version': 0, 'frame': 1234567},
      );
      final block = await worker.render();
      expect(block.startFrame, 1234567);
      expect(block.stems.expand((s) => s).every((v) => v.isFinite), isTrue);
    },
  );
  test(
    'stale configuration revisions cannot replace newer synthesis settings',
    () {
      final r = renderer();
      r.update(r.config.copyWith(warmth: .9), r.context, 7);
      r.update(r.config.copyWith(warmth: .1), r.context, 6);
      expect(r.config.warmth, .9);
      expect(r.revision, 7);
    },
  );
  test('unplayed melodic events move with the shared chord transition', () {
    final r = renderer();
    final p = r.planner;
    p.pending.add(const MusicalEvent(48001, 'piano', 440, .8, 0));
    p.nextChord = 48000;
    final events = p.tick(48000, r.config, r.context);
    final note = events.singleWhere(
      (e) => e.kind == 'piano' && e.frame == 48001,
    );
    expect(
      p.chord.chordFrequencies.any(
        (f) => [
          .5,
          1.0,
          2.0,
          4.0,
        ].any((o) => (f * o - note.frequency).abs() < .001),
      ),
      isTrue,
    );
  });
  test(
    'debug phase override survives timeline updates and checkpoint JSON',
    () {
      final c = AudioSessionContext.fromJson(
        const AudioSessionContext(
          phase: SessionPhase.windDown,
          followTimeline: false,
        ).toJson(),
      );
      expect(c.atFrame(0).phase, SessionPhase.windDown);
    },
  );
  test('worker ignores stale config and effect commands together', () async {
    final worker = RenderWorker();
    await worker.open();
    addTearDown(worker.dispose);
    final r = renderer();
    await worker.reset(config: r.config, context: r.context, seed: 42);
    await worker.update(
      r.config.copyWith(warmth: .8),
      r.context,
      9,
      reverb: .2,
    );
    await worker.update(
      r.config.copyWith(warmth: .1),
      r.context,
      8,
      reverb: .9,
    );
    final checkpoint = await worker.checkpoint(0);
    expect((checkpoint['config'] as Map)['warmth'], .8);
    expect((checkpoint['dsp'] as List)[10], .2);
  });
  test('concurrent disposals share the actual cleanup completion', () async {
    final lifecycle = PlaybackLifecycle();
    final gate = Completer<void>();
    var count = 0;
    final a = lifecycle.close(() async {
      count++;
      await gate.future;
    });
    final b = lifecycle.close(() async {
      count++;
    });
    expect(identical(a, b), isTrue);
    gate.complete();
    await Future.wait([a, b]);
    expect(count, 1);
  });
  test('lifecycle continues after errors and invalidates stale work', () async {
    final lifecycle = PlaybackLifecycle();
    final epoch = lifecycle.epoch;
    await expectLater(
      lifecycle.run<void>(() async {
        throw StateError('probe');
      }),
      throwsStateError,
    );
    expect(await lifecycle.run(() => Future.value(7)), 7);
    lifecycle.invalidate();
    expect(lifecycle.epoch, isNot(epoch));
    await lifecycle.close(() async {});
    await expectLater(lifecycle.run(() => Future.value(1)), throwsStateError);
  });
  test(
    'wind-down lasts to the true end and endless sessions never complete',
    () {
      expect(
        SessionPhaseX.calculatePhase(
          elapsedSeconds: 99,
          totalDurationSeconds: 100,
        ),
        SessionPhase.windDown,
      );
      expect(
        SessionPhaseX.calculatePhase(
          elapsedSeconds: 100,
          totalDurationSeconds: 100,
        ),
        SessionPhase.completion,
      );
      expect(
        SessionPhaseX.calculatePhase(
          elapsedSeconds: 99999,
          totalDurationSeconds: null,
        ),
        SessionPhase.deepFocus,
      );
    },
  );
}
