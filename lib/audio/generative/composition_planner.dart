import 'dart:math';

import 'package:flundel/audio/audio_session_context.dart';
import 'package:flundel/audio/generative/arrangement_profile.dart';
import 'package:flundel/audio/generative/sound_palette.dart';
import 'package:flundel/audio/procedural/harmony_controller.dart';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flundel/session/session_phase.dart';

/// Serializable independent PRNG; never depends on Dart Random internals.
class SeededSequence {
  SeededSequence(int seed) : state = seed & 0xffffffff;
  int state;
  double next() {
    state = (1664525 * state + 1013904223) & 0xffffffff;
    return state / 4294967296;
  }
}

class MusicalEvent {
  const MusicalEvent(
    this.frame,
    this.kind,
    this.frequency,
    this.velocity,
    this.pan,
  );
  factory MusicalEvent.fromJson(Map<String, dynamic> j) => MusicalEvent(
    j['frame'] as int,
    j['kind'] as String,
    (j['frequency'] as num).toDouble(),
    (j['velocity'] as num).toDouble(),
    (j['pan'] as num).toDouble(),
  );
  final int frame;
  final String kind;
  final double frequency;
  final double velocity;
  final double pan;
  Map<String, dynamic> toJson() => {
    'frame': frame,
    'kind': kind,
    'frequency': frequency,
    'velocity': velocity,
    'pan': pan,
  };
}

/// All decisions are made at absolute sample positions. UI timer cadence and
/// render block size cannot change the composition or consume random choices.
class CompositionPlanner {
  CompositionPlanner(int seed, this.profile, {ModeSoundPalette? palette})
    : palette = palette ?? ModeSoundPalette.forId(profile.id),
      harmony = SeededSequence(seed ^ 0x484152),
      rhythm = SeededSequence(seed ^ 0x524859),
      melody = SeededSequence(seed ^ 0x4d454c),
      ambience = SeededSequence(seed ^ 0x414d42) {
    final harmonies = this.palette.harmonies;
    variant = seed.abs() % this.palette.variants;
    harmonyPalette = harmonies[variant % harmonies.length];
    chordIndex = harmonyPalette.start.index;
    nextChord = (profile.chordSeconds * rate).round();
    _seedAmbientSchedule(0);
  }
  static const rate = 48000;
  final ArrangementProfile profile;
  final ModeSoundPalette palette;
  final SeededSequence harmony;
  final SeededSequence rhythm;
  final SeededSequence melody;
  final SeededSequence ambience;
  late final int variant;
  late final HarmonyPalette harmonyPalette;
  int nextChord = 0;
  int nextMelody = 3 * rate;
  int nextBeat = 0;
  int beatIndex = 0;
  int chordIndex = 0;
  int changes = 0;
  int lastMacro = -10 * rate;
  double depth = .3;
  double activity = .65;
  double complexity = .5;
  double lastNote = 440;
  final Map<String, int> nextAmbient = {};
  final List<MusicalEvent> pending = [];
  ChordInfo get chord =>
      HarmonyController.chords[ChordType.values[chordIndex]]!;
  double get root {
    final value = chord.chordFrequencies.first;
    var f = value;
    while (f > 82.5) {
      f /= 2;
    }
    return f;
  }

  double targetDepth(SessionPhase phase) => switch (phase) {
    SessionPhase.settling => .3,
    SessionPhase.enteringFocus => .65,
    SessionPhase.deepFocus => .85,
    SessionPhase.windDown => .5,
    SessionPhase.completion => 0,
  };

  /// Called when a session starts at a non-zero saved frame.
  void resetSchedule(int frame, int beatsBpm) {
    nextChord = frame + 40 * rate;
    nextMelody = frame + 3 * rate;
    beatIndex = (frame * beatsBpm * 2 / (60 * rate)).ceil();
    nextBeat = (beatIndex * 60 * rate / (beatsBpm * 2)).round();
    _seedAmbientSchedule(frame);
  }

  void _seedAmbientSchedule(int frame) {
    nextAmbient.clear();
    var index = 0;
    for (final spec in palette.ambientEvents) {
      final firstSeconds = max(6.0, spec.minSeconds * .6) + index * 1.5;
      nextAmbient[spec.kind] = frame + (firstSeconds * rate).round();
      index++;
    }
  }

  /// Called on a fixed 100 Hz composition grid, independent of render blocks.
  List<MusicalEvent> tick(
    int frame,
    SoundscapeConfig config,
    AudioSessionContext context,
  ) {
    final phase = context.atFrame(frame).phase;
    complexity += (config.complexity - complexity) * (1 - exp(-.01 / 2));
    depth += (targetDepth(phase) - depth) * (1 - exp(-.01 / 15));
    final targetActivity = switch (phase) {
      SessionPhase.settling => .55,
      SessionPhase.enteringFocus => .85,
      SessionPhase.deepFocus => .7,
      SessionPhase.windDown => .3,
      SessionPhase.completion => 0.0,
    };
    activity += (targetActivity - activity) * (1 - exp(-.01 / 20));
    if (frame >= nextChord && frame - lastMacro >= 8 * rate) {
      final previous = ChordType.values[chordIndex];
      final choices = harmonyPalette.transitions[previous] ?? const [];
      if (choices.isNotEmpty) {
        chordIndex = choices[(harmony.next() * choices.length).floor()].index;
      }
      nextChord =
          frame +
          (profile.chordSeconds *
                  (0.85 + depth * .5 + harmony.next() * .25) *
                  rate)
              .round();
      // Unplayed phrase notes follow the new harmony; sounding notes keep
      // their release tails while the pad crossfades.
      for (var i = 0; i < pending.length; i++) {
        final e = pending[i];
        if (VoiceLibrary.specs[e.kind]?.melodic != true) continue;
        final candidates =
            <double>[
              for (final f in chord.chordFrequencies)
                for (final octave in [.5, 1.0, 2.0, 4.0]) f * octave,
            ]..sort(
              (a, b) =>
                  (a - e.frequency).abs().compareTo((b - e.frequency).abs()),
            );
        pending[i] = MusicalEvent(
          e.frame,
          e.kind,
          candidates.first,
          e.velocity,
          e.pan,
        );
      }
      lastMacro = frame;
      changes++;
    }
    if (frame >= nextMelody) {
      final notes =
          chord.chordFrequencies.map((frequency) {
            var f = frequency;
            while (f < profile.lowNote) {
              f *= 2;
            }
            while (f > profile.highNote) {
              f /= 2;
            }
            return f;
          }).toList()..sort(
            (a, b) => (a - lastNote).abs().compareTo((b - lastNote).abs()),
          );
      final voices = palette.melodicVoices;
      final kind = voices[(melody.next() * voices.length).floor()];
      final count = palette.melodyNoteCount;
      for (var i = 0; i < count; i++) {
        final frequency = notes[(melody.next() * min(3, notes.length)).floor()];
        pending.add(
          MusicalEvent(
            frame + (i * (0.8 + melody.next() * .5) * rate).round(),
            kind,
            frequency,
            .6 + melody.next() * .25,
            (melody.next() - .5) * profile.width,
          ),
        );
        lastNote = frequency;
      }
      nextMelody =
          frame +
          (profile.phraseSeconds *
                  (1.35 -
                      activity * .35 -
                      complexity * .2 +
                      melody.next() * .3) *
                  rate)
              .round();
    }
    for (final spec in palette.ambientEvents) {
      final due = nextAmbient[spec.kind];
      if (due == null || frame < due) continue;
      pending.add(_ambientEvent(spec, frame));
      nextAmbient[spec.kind] = frame + _ambientInterval(spec, phase);
    }
    // Beat grid uses rational absolute positions, never rounded accumulations.
    final kit = palette.percussion;
    while (frame + 480 > nextBeat) {
      final position = beatIndex % 8;
      final density =
          profile.pulseDensity * (.55 + activity * .25 + complexity * .2);
      final roll = rhythm.next();
      final velocity = .65 + rhythm.next() * .25;
      if (profile.drums && !config.gentlePulses) {
        if (position == 0 ||
            (position == 4 && roll < .9) ||
            (position == 7 && roll < complexity * .35)) {
          pending.add(MusicalEvent(nextBeat, kit.kick, 55, velocity, 0));
          pending.add(
            MusicalEvent(
              nextBeat,
              kit.bass,
              root * (position == 7 ? 1.5 : 1),
              velocity,
              0,
            ),
          );
        }
        if (position == 2 || position == 6) {
          pending.add(MusicalEvent(nextBeat, kit.snare, 180, velocity * .6, 0));
        }
        if (roll < .45 + complexity * .4) {
          pending.add(
            MusicalEvent(nextBeat, kit.hat, 4000, velocity * .4, .12),
          );
        }
        final ghost = kit.ghost;
        if (ghost != null &&
            (position == 3 || position == 5) &&
            roll > 1 - kit.ghostChance) {
          pending.add(MusicalEvent(nextBeat, ghost, 900, velocity * .25, -.12));
        }
      } else if (position.isEven && roll < density) {
        pending.add(MusicalEvent(nextBeat, kit.pulse, root * 2, velocity, 0));
        if (position == 0 || position == 4) {
          pending.add(MusicalEvent(nextBeat, kit.bass, root, velocity * .8, 0));
        }
      }
      beatIndex++;
      nextBeat =
          (beatIndex * 60 * rate / (config.beatsBpm * 2) +
                  (profile.drums && beatIndex.isOdd
                      ? .08 * 60 * rate / config.beatsBpm
                      : 0))
              .round();
    }
    final events = pending.where((e) => e.frame < frame + 480).toList();
    pending.removeWhere((e) => e.frame < frame + 480);
    return events;
  }

  MusicalEvent _ambientEvent(AmbientEventSpec spec, int frame) {
    double frequency;
    if (spec.followChord) {
      final tones = chord.chordFrequencies;
      frequency = tones[(ambience.next() * tones.length).floor()];
      while (frequency < spec.minFrequency) {
        frequency *= 2;
      }
      while (frequency > spec.maxFrequency) {
        frequency /= 2;
      }
    } else {
      frequency =
          spec.minFrequency +
          ambience.next() * (spec.maxFrequency - spec.minFrequency);
    }
    final velocity = (spec.velocity * (.85 + ambience.next() * .30)).clamp(
      0.0,
      1.0,
    );
    final pan = (ambience.next() - .5) * profile.width * spec.panWidth;
    return MusicalEvent(frame, spec.kind, frequency, velocity, pan);
  }

  int _ambientInterval(AmbientEventSpec spec, SessionPhase phase) {
    final base =
        spec.minSeconds + ambience.next() * (spec.maxSeconds - spec.minSeconds);
    final phaseScale = switch (phase) {
      SessionPhase.settling => 1.15,
      SessionPhase.enteringFocus => 1.0,
      SessionPhase.deepFocus => 1.10,
      SessionPhase.windDown => .85,
      SessionPhase.completion => 1.40,
    };
    final seconds = (base * phaseScale / spec.weight).clamp(2.0, 240.0);
    return (seconds * rate).round();
  }

  Map<String, dynamic> snapshot() => {
    'rng': [harmony.state, rhythm.state, melody.state, ambience.state],
    'next': [nextChord, nextMelody, nextBeat],
    'ambient': Map<String, int>.of(nextAmbient),
    'beat': beatIndex,
    'chord': chordIndex,
    'changes': changes,
    'macro': lastMacro,
    'depth': depth,
    'activity': activity,
    'complexity': complexity,
    'note': lastNote,
    'variant': variant,
    'harmony': harmonyPalette.id,
    'pending': pending.map((e) => e.toJson()).toList(),
  };
  void restore(Map<String, dynamic> j) {
    final rng = (j['rng'] as List).cast<int>();
    harmony.state = rng[0];
    rhythm.state = rng[1];
    melody.state = rng[2];
    ambience.state = rng[3];
    final n = (j['next'] as List).cast<int>();
    nextChord = n[0];
    nextMelody = n[1];
    nextBeat = n[2];
    final ambient = j['ambient'];
    if (ambient is Map) {
      nextAmbient
        ..clear()
        ..addAll(
          ambient.map(
            (key, value) => MapEntry(key as String, (value as num).toInt()),
          ),
        );
    }
    beatIndex = j['beat'] as int;
    chordIndex = j['chord'] as int;
    changes = j['changes'] as int;
    lastMacro = j['macro'] as int;
    depth = (j['depth'] as num).toDouble();
    activity = (j['activity'] as num).toDouble();
    complexity = (j['complexity'] as num?)?.toDouble() ?? .5;
    lastNote = (j['note'] as num).toDouble();
    pending
      ..clear()
      ..addAll(
        (j['pending'] as List).map(
          (e) => MusicalEvent.fromJson(Map<String, dynamic>.from(e as Map)),
        ),
      );
  }
}
