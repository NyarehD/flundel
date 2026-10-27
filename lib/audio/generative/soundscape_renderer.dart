import 'dart:math';
import 'dart:typed_data';

import 'package:flundel/audio/audio_mix_policy.dart';
import 'package:flundel/audio/audio_session_context.dart';
import 'package:flundel/audio/generative/arrangement_profile.dart';
import 'package:flundel/audio/generative/composition_planner.dart';
import 'package:flundel/audio/generative/sound_palette.dart';
import 'package:flundel/domain/models/soundscape_config.dart';

enum AudioStem {
  pad,
  piano,
  chimes,
  noise,
  nature,
  wind,
  water,
  birds,
  beats,
  bass,
  binaural,
}

extension AudioStemX on AudioStem {
  String get control => switch (this) {
    AudioStem.chimes => 'piano',
    AudioStem.wind || AudioStem.water || AudioStem.birds => 'nature',
    _ => name,
  };
  double gain(SoundscapeConfig c) {
    final level = switch (this) {
      AudioStem.pad => AudioMixPolicy.padLevel(c),
      AudioStem.piano => c.piano * AudioMixPolicy.pianoVoiceGain,
      AudioStem.chimes => c.chimes * AudioMixPolicy.chimeGain,
      AudioStem.noise => AudioMixPolicy.noiseLevel(c),
      AudioStem.nature => AudioMixPolicy.natureLevel(c),
      AudioStem.wind => AudioMixPolicy.windLevel(c),
      AudioStem.water => AudioMixPolicy.waterLevel(c),
      AudioStem.birds => AudioMixPolicy.birdsLevel(c),
      AudioStem.beats => c.beats * AudioMixPolicy.beatsGain,
      AudioStem.bass => c.bass * AudioMixPolicy.bassGain,
      AudioStem.binaural => c.binaural * .12,
    };
    return (level * c.intensity).clamp(0.0, .8);
  }
}

class RenderedAudioBlock {
  const RenderedAudioBlock(
    this.startFrame,
    this.frames,
    this.stems,
    this.events,
    this.renderMicros,
  );
  final int startFrame;
  final int frames;
  final List<Float32List> stems;
  final List<MusicalEvent> events;
  final int renderMicros;
}

class _PadVoice {
  _PadVoice(this.frequency, this.phase, this.left, this.right, this.foundation);
  factory _PadVoice.restore(List<dynamic> j) => _PadVoice(
    (j[0] as num).toDouble(),
    (j[1] as num).toDouble(),
    (j[2] as num).toDouble(),
    (j[3] as num).toDouble(),
    j.length > 4 ? (j[4] as num).toDouble() : (j[1] as num).toDouble() / 2,
  );
  double frequency;
  double phase;
  double left;
  double right;
  double foundation;
  List<double> snapshot() => [frequency, phase, left, right, foundation];
}

class _Voice {
  _Voice(this.event, {this.age = 0, this.phase = 0, this.smooth = 0})
    : left = sqrt((1 - event.pan) / 2),
      right = sqrt((1 + event.pan) / 2);
  factory _Voice.restore(Map<String, dynamic> j) => _Voice(
    MusicalEvent.fromJson(Map<String, dynamic>.from(j['event'] as Map)),
    age: j['age'] as int,
    phase: (j['phase'] as num).toDouble(),
    smooth: (j['smooth'] as num?)?.toDouble() ?? 0,
  );
  final MusicalEvent event;
  int age;
  double phase;
  final double left;
  final double right;
  double smooth;
  double get seconds => age / SoundscapeRenderer.rate;
  Map<String, dynamic> snapshot() => {
    'event': event.toJson(),
    'age': age,
    'phase': phase,
    'smooth': smooth,
  };
}

/// Small diffuse space, wholly inside the renderer so tail state is restorable.
/// Bass and binaural never pass through this effect.
class _Space {
  final List<Float64List> lines = [
    Float64List(1499),
    Float64List(2111),
    Float64List(2633),
  ];
  final List<int> cursor = [0, 0, 0];
  double left = 0;
  double right = 0;
  void tick(double input, double wet) {
    var a = 0.0;
    var b = 0.0;
    for (var i = 0; i < 3; i++) {
      final old = lines[i][cursor[i]];
      lines[i][cursor[i]] = input * .22 + old * .78;
      cursor[i] = (cursor[i] + 1) % lines[i].length;
      a += old * (i == 1 ? .7 : 1);
      b += old * (i == 0 ? .7 : 1);
    }
    left = a * wet * .5;
    right = b * wet * .5;
  }

  Map<String, dynamic> snapshot() => {
    'cursor': List<int>.of(cursor),
    'lines': lines.map(Float64List.fromList).toList(),
  };
  void restore(Map<String, dynamic> j) {
    for (var i = 0; i < 3; i++) {
      cursor[i] = (j['cursor'] as List)[i] as int;
      lines[i].setAll(
        0,
        ((j['lines'] as List)[i] as List).map((v) => (v as num).toDouble()),
      );
    }
  }
}

/// Stateful production renderer shared by live streaming and offline tools.
/// No Flutter, native calls, wall-clock decisions, or externally loaded assets.
class SoundscapeRenderer {
  SoundscapeRenderer({
    required this.seed,
    required this.config,
    required this.context,
  }) {
    profile = ArrangementProfile.forId(context.presetId);
    palette = ModeSoundPalette.forId(context.presetId);
    variant = seed.abs() % palette.variants;
    planner = CompositionPlanner(seed, profile, palette: palette);
    noiseRandom = SeededSequence(seed ^ 0x4e4f49);
    _pad = _makePad(planner.chord.chordFrequencies, []);
    _warmth = config.warmth;
    _complexity = config.complexity;
  }
  factory SoundscapeRenderer.restore(Map<String, dynamic> j) {
    if (j['version'] != checkpointVersion) {
      throw const FormatException('Unsupported audio checkpoint');
    }
    final r = SoundscapeRenderer(
      seed: j['seed'] as int,
      config: SoundscapeConfig.fromJson(
        Map<String, dynamic>.from(j['config'] as Map),
      ),
      context: AudioSessionContext.fromJson(
        Map<String, dynamic>.from(j['context'] as Map),
      ),
    );
    r.frame = j['frame'] as int;
    r.revision = j['revision'] as int;
    r._chord = j['chord'] as int;
    r._blendStart = j['blend'] as int;
    r.planner.restore(Map<String, dynamic>.from(j['planner'] as Map));
    r.noiseRandom.state = j['noiseRng'] as int;
    r._pad = (j['pad'] as List)
        .map((v) => _PadVoice.restore(v as List))
        .toList();
    r._oldPad = (j['oldPad'] as List)
        .map((v) => _PadVoice.restore(v as List))
        .toList();
    r._voices.addAll(
      (j['voices'] as List).map(
        (v) => _Voice.restore(Map<String, dynamic>.from(v as Map)),
      ),
    );
    r._pending.addAll(
      (j['pending'] as List).map(
        (e) => MusicalEvent.fromJson(Map<String, dynamic>.from(e as Map)),
      ),
    );
    for (var i = 0; i < 3; i++) {
      r._spaces[i].restore(
        Map<String, dynamic>.from((j['spaces'] as List)[i] as Map),
      );
    }
    final d = (j['dsp'] as List).map((v) => (v as num).toDouble()).toList();
    r._brown = d[0];
    r._pink = d[1];
    r._water = d[2];
    r._wind = d[3];
    r._textureLeft = d[4];
    r._textureRight = d[5];
    r._carrierL = d[6];
    r._carrierR = d[7];
    r._warmth = d[8];
    r._complexity = d[9];
    r.reverb = d[10];
    r.cutoffOverride = d[11];
    r._rain = d.length > 12 ? d[12] : 0;
    r._crackle = d.length > 13 ? d[13] : 0;
    return r;
  }
  static const rate = 48000;
  static const blockFrames = 4096;
  static const checkpointVersion = 2;
  static const maxVoices = 24;
  final int seed;
  SoundscapeConfig config;
  AudioSessionContext context;
  late final ArrangementProfile profile;
  late final ModeSoundPalette palette;
  late final int variant;
  late final CompositionPlanner planner;
  late final SeededSequence noiseRandom;
  int frame = 0;
  int revision = 0;
  int _chord = 0;
  int _blendStart = -6 * rate;
  List<_PadVoice> _pad = [];
  List<_PadVoice> _oldPad = [];
  final List<_Voice> _voices = [];
  final List<MusicalEvent> _pending = [];
  final List<_Space> _spaces = List.generate(3, (_) => _Space());
  double _brown = 0;
  double _pink = 0;
  double _water = 0;
  double _wind = 0;
  double _textureLeft = 0;
  double _textureRight = 0;
  double _carrierL = 0;
  double _carrierR = 0;
  double _rain = 0;
  double _crackle = 0;
  double _warmth = .5;
  double _complexity = .5;
  double reverb = .16;
  double cutoffOverride = 0;
  List<_PadVoice> _makePad(List<double> frequencies, List<_PadVoice> previous) {
    final used = <double>{};
    return List.generate(5, (i) {
      final anchor = previous.isEmpty ? frequencies[i] : previous[i].frequency;
      final candidates = <double>[];
      for (final f in frequencies) {
        for (final octave in [.5, 1.0, 2.0]) {
          final v = f * octave;
          if (v >= 110 && v <= 784 && !used.contains(v)) candidates.add(v);
        }
      }
      candidates.sort(
        (a, b) => (a - anchor).abs().compareTo((b - anchor).abs()),
      );
      final f = candidates.isEmpty ? frequencies[i] : candidates.first;
      used.add(f);
      final phase = (i * 1.71) % (2 * pi);
      return _PadVoice(f, phase, phase, phase, phase / 2);
    });
  }

  void update(
    SoundscapeConfig value,
    AudioSessionContext session,
    int newRevision,
  ) {
    if (newRevision < revision) return;
    config = value;
    context = session;
    revision = newRevision;
  }

  int _stemIndex(VoiceStem stem) => switch (stem) {
    VoiceStem.piano => AudioStem.piano.index,
    VoiceStem.chimes => AudioStem.chimes.index,
    VoiceStem.noise => AudioStem.noise.index,
    VoiceStem.beats => AudioStem.beats.index,
    VoiceStem.bass => AudioStem.bass.index,
    VoiceStem.nature => AudioStem.nature.index,
    VoiceStem.wind => AudioStem.wind.index,
    VoiceStem.water => AudioStem.water.index,
    VoiceStem.birds => AudioStem.birds.index,
  };

  double _voiceNoise(VoiceSpec spec, _Voice voice, double input) {
    if (spec.noiseLowpass >= 1) return input;
    voice.smooth += spec.noiseLowpass * (input - voice.smooth);
    return spec.noiseHighpass ? input - voice.smooth : voice.smooth;
  }

  double _voiceSignal(
    VoiceSpec spec,
    _Voice voice,
    double age,
    double white,
    double independent,
  ) {
    switch (spec.signal) {
      case VoiceSignal.tonal:
        var signal = 0.0;
        for (final partial in spec.partials) {
          signal +=
              partial.amplitude *
              sin(voice.phase * partial.ratio + partial.phase) *
              exp(-age * partial.decay);
        }
        if (spec.noiseMix > 0) {
          signal +=
              _voiceNoise(spec, voice, white) *
              spec.noiseMix *
              exp(-age * spec.noiseDecay);
        }
        return signal;
      case VoiceSignal.bird:
        return sin(voice.phase) + .08 * sin(2 * voice.phase);
      case VoiceSignal.cricket:
        return sin(voice.phase) *
            (.55 + .45 * sin(age * 2 * pi * spec.tremoloHz));
      case VoiceSignal.owl:
        return sin(voice.phase) *
            (.78 + .22 * sin(age * 2 * pi * spec.tremoloHz));
      case VoiceSignal.frog:
        final pulse = pow(
          max(0.0, sin(age * 2 * pi * spec.tremoloHz)),
          3,
        ).toDouble();
        return sin(voice.phase) * (.25 + .75 * pulse);
      case VoiceSignal.noise:
        return _voiceNoise(spec, voice, independent);
      case VoiceSignal.kick:
        return sin(voice.phase);
      case VoiceSignal.snare:
        return white * .35 + sin(voice.phase) * .30;
      case VoiceSignal.hat:
        return independent * .20;
    }
  }

  RenderedAudioBlock render([int count = blockFrames]) {
    if (count < 0 || count > rate * 3) {
      throw ArgumentError('Render 0..3 seconds per block');
    }
    final watch = Stopwatch()..start();
    final start = frame;
    final stems = List.generate(
      AudioStem.values.length,
      (_) => Float32List(count * 2),
    );
    final events = <MusicalEvent>[];
    final detune = pow(2, 2.2 / 1200).toDouble();
    final bed = palette.bed;
    for (var i = 0; i < count; i++, frame++) {
      if (frame % 480 == 0) {
        _pending.addAll(planner.tick(frame, config, context));
        _pending.sort((a, b) => a.frame.compareTo(b.frame));
        if (_chord != planner.chordIndex) {
          _chord = planner.chordIndex;
          _oldPad = _pad;
          _pad = _makePad(planner.chord.chordFrequencies, _oldPad);
          _blendStart = frame;
        }
      }
      while (_pending.isNotEmpty && _pending.first.frame <= frame) {
        final event = _pending.removeAt(0);
        // Strictly bounded polyphony independent of gain/mute state.
        final spec = VoiceLibrary.of(event.kind);
        final same = _voices.where((v) => v.event.kind == event.kind).toList();
        if (same.length >= spec.voiceLimit) _voices.remove(same.first);
        while (_voices.length >= maxVoices) {
          _voices.removeAt(0);
        }
        _voices.add(_Voice(event));
        events.add(event);
      }
      _warmth += (config.warmth - _warmth) / 24000;
      _complexity += (config.complexity - _complexity) / 24000;
      final t = frame / rate;
      final entrance = min(1.0, frame / (3 * rate));
      final phaseGain = .65 + planner.activity * .35;
      final lfo = sin(t * .087 + seed % 13) * profile.modulation;
      final blend = ((frame - _blendStart) / (6 * rate)).clamp(0.0, 1.0);
      var padL = 0.0;
      var padR = 0.0;
      for (var group = 0; group < 2; group++) {
        final voices = group == 0 ? _pad : _oldPad;
        final weight = group == 0 ? sin(blend * pi / 2) : cos(blend * pi / 2);
        if (weight < .00001) continue;
        for (final v in voices) {
          final increment = 2 * pi * v.frequency / rate;
          v.phase = (v.phase + increment) % (2 * pi);
          v.left = (v.left + increment / detune) % (2 * pi);
          v.right = (v.right + increment * detune) % (2 * pi);
          v.foundation = (v.foundation + increment * .5) % (2 * pi);
          final harmonic = .14 + (1 - _warmth) * .18 * profile.brightness;
          final center =
              sin(v.phase) +
              harmonic * sin(2 * v.phase) +
              .065 * sin(3 * v.phase) +
              (v.frequency <= 330 ? .28 : .12) * sin(v.foundation);
          final side = profile.width * .35;
          padL += ((1 - side) * center + side * sin(v.left)) * weight;
          padR += ((1 - side) * center + side * sin(v.right)) * weight;
        }
      }
      if (blend >= 1) _oldPad = [];
      final padGain =
          .16 * profile.padPresence * (1 + lfo) * phaseGain * entrance;
      padL *= padGain;
      padR *= padGain;
      _spaces[0].tick((padL + padR) * .5, reverb);
      // Fixed, memoryless soft saturation contains coincident chord peaks;
      // it does not raise quiet passages or compensate for user attenuation.
      double padShape(double value) => value / sqrt(1 + pow(value / .9, 2));
      stems[0][i * 2] = padShape(padL + _spaces[0].left);
      stems[0][i * 2 + 1] = padShape(padR + _spaces[0].right);
      final white = noiseRandom.next() * 2 - 1;
      final independent = noiseRandom.next() * 2 - 1;
      _brown = (_brown + white * .018) * .997;
      _pink += .025 * (white - _pink);
      _wind += .006 * (independent - _wind);
      _water += .18 * (white - _water);
      if (bed.kind == AmbientBed.rain) {
        _rain += .06 * (white - _rain);
      }
      if (bed.crackleRate > 0) {
        if (noiseRandom.next() < bed.crackleRate) {
          _crackle = 1;
        } else {
          _crackle *= .993;
        }
      }
      final cutoff = cutoffOverride > 0
          ? cutoffOverride
          : bed.cutoffBase +
                (1 - _warmth) * bed.cutoffWarmth +
                profile.natureMotion * bed.cutoffMotion;
      final alpha = 1 - exp(-2 * pi * cutoff / rate);
      _textureLeft += alpha * ((_brown * .45 + _pink * .8) - _textureLeft);
      _textureRight +=
          alpha * ((_brown * .45 + _pink * .65 + _wind * .15) - _textureRight);
      final air = profile.texturePresence;
      final swell =
          .75 + bed.swellDepth * sin(t * 2 * pi * bed.swellRateHz + .7);
      final flow = .7 + .3 * sin(t * 2 * pi * bed.flowRateHz + sin(t * .07));
      final baseNoiseL = _textureLeft * .7;
      final baseNoiseR = _textureRight * .7;
      final baseNatureL = _water * .16 + _wind * .08;
      final baseNatureR = _water * .12 + _wind * .15;
      final baseWindL = _wind * .9;
      final baseWindR = _wind * .7 + _brown * .08;
      final baseWaterL = _water * .22;
      final baseWaterR = _water * .16 + independent * .018;
      double noiseL;
      double noiseR;
      double natureL;
      double natureR;
      double windL;
      double windR;
      double waterL;
      double waterR;
      switch (bed.kind) {
        case AmbientBed.air:
          noiseL = baseNoiseL;
          noiseR = baseNoiseR;
          natureL = baseNatureL;
          natureR = baseNatureR;
          windL = baseWindL;
          windR = baseWindR;
          waterL = baseWaterL;
          waterR = baseWaterR;
        case AmbientBed.room:
          noiseL = _textureLeft * .45;
          noiseR = _textureRight * .42;
          natureL = _wind * .04;
          natureR = _wind * .05;
          windL = _wind * .12;
          windR = _wind * .10;
          waterL = _water * .03;
          waterR = _water * .02;
        case AmbientBed.rain:
          noiseL = _textureLeft * .9 + _rain * .25;
          noiseR = _textureRight * .85 + _rain * .23;
          natureL = _rain * .14 + _water * .08;
          natureR = _rain * .13 + _water * .07;
          windL = _wind * .12;
          windR = _wind * .10;
          waterL = _rain * .28 + _water * .12;
          waterR = _rain * .26 + _water * .10;
        case AmbientBed.ocean:
          noiseL = _brown * .35 + _textureLeft * .25;
          noiseR = _brown * .33 + _textureRight * .22;
          natureL = _brown * .30 + _water * .18;
          natureR = _brown * .28 + _water * .16;
          windL = _wind * .30;
          windR = _wind * .26;
          waterL = _water * .42 + _brown * .12;
          waterR = _water * .36 + _brown * .10;
        case AmbientBed.stream:
          noiseL = _pink * .30 + _textureLeft * .30;
          noiseR = _pink * .28 + _textureRight * .26;
          natureL = _water * .25 + _wind * .06;
          natureR = _water * .22 + _wind * .05;
          windL = _wind * .16;
          windR = _wind * .14;
          waterL = _water * .48 + _pink * .06;
          waterR = _water * .42 + _pink * .05;
        case AmbientBed.night:
          noiseL = _brown * .30 + _textureLeft * .18;
          noiseR = _brown * .28 + _textureRight * .16;
          natureL = _wind * .08 + _water * .04;
          natureR = _wind * .07 + _water * .03;
          windL = _wind * .46;
          windR = _wind * .40;
          waterL = _water * .12;
          waterR = _water * .10;
        case AmbientBed.vinyl:
          noiseL = _pink * .95 + _crackle * .18;
          noiseR = _pink * .88 + _crackle * .16;
          natureL = 0;
          natureR = 0;
          windL = 0;
          windR = 0;
          waterL = 0;
          waterR = 0;
        case AmbientBed.forest:
          noiseL = _textureLeft * .55 + _pink * .12;
          noiseR = _textureRight * .52 + _pink * .10;
          natureL = _water * .22 + _wind * .12;
          natureR = _water * .20 + _wind * .10;
          windL = _wind * .42;
          windR = _wind * .36;
          waterL = _water * .40;
          waterR = _water * .34;
      }
      stems[3][i * 2] = noiseL * air * bed.noiseGain;
      stems[3][i * 2 + 1] = noiseR * air * bed.noiseGain;
      stems[4][i * 2] = natureL * air * bed.natureGain;
      stems[4][i * 2 + 1] = natureR * air * bed.natureGain;
      stems[5][i * 2] = windL * swell * air * bed.windGain;
      stems[5][i * 2 + 1] = windR * swell * air * bed.windGain;
      stems[6][i * 2] = waterL * flow * air * bed.waterGain;
      stems[6][i * 2 + 1] = waterR * flow * air * bed.waterGain;
      for (final voice in _voices) {
        final e = voice.event;
        final spec = VoiceLibrary.of(e.kind);
        final age = voice.seconds;
        var frequency = e.frequency;
        if (spec.pitchGlideHz != 0) {
          frequency += spec.pitchGlideHz * exp(-age * spec.glideDecay);
        }
        if (spec.chirpDepthHz != 0) {
          frequency +=
              sin(age * spec.chirpRate) * spec.chirpDepthHz +
              age * spec.chirpRiseHz;
        }
        if (spec.vibratoHz > 0) {
          frequency *=
              1 + sin(age * 2 * pi * spec.vibratoHz) * spec.vibratoDepth;
        }
        voice.phase = (voice.phase + 2 * pi * frequency / rate) % (2 * pi);
        final attack = max(.001, spec.attack);
        final env =
            (.5 - .5 * cos(pi * min(1.0, age / attack))) *
            exp(-age * spec.decay) *
            min(1.0, max(0.0, (spec.duration - age) / .06));
        final signal = _voiceSignal(spec, voice, age, white, independent);
        final value = signal * env * e.velocity * spec.sourceGain * phaseGain;
        final index = _stemIndex(spec.stem);
        stems[index][i * 2] += value * voice.left;
        stems[index][i * 2 + 1] += value * voice.right;
        voice.age++;
      }
      _voices.removeWhere(
        (v) => v.seconds > VoiceLibrary.of(v.event.kind).duration,
      );
      for (var s = 1; s <= 2; s++) {
        _spaces[s].tick((stems[s][i * 2] + stems[s][i * 2 + 1]) * .5, reverb);
        stems[s][i * 2] += _spaces[s].left;
        stems[s][i * 2 + 1] += _spaces[s].right;
      }
      _carrierL = (_carrierL + 2 * pi * 180 / rate) % (2 * pi);
      _carrierR =
          (_carrierR +
              2 * pi * (180 + AudioMixPolicy.binauralBeatHz(config)) / rate) %
          (2 * pi);
      stems[10][i * 2] = sin(_carrierL) * .32;
      stems[10][i * 2 + 1] = sin(_carrierR) * .32;
    }
    return RenderedAudioBlock(
      start,
      count,
      stems,
      events,
      watch.elapsedMicroseconds,
    );
  }

  Map<String, dynamic> snapshot() => {
    'version': checkpointVersion,
    'seed': seed,
    'frame': frame,
    'revision': revision,
    'palette': palette.id,
    'variant': variant,
    'config': config.toJson(),
    'context': context.toJson(),
    'planner': planner.snapshot(),
    'noiseRng': noiseRandom.state,
    'pad': _pad.map((v) => v.snapshot()).toList(),
    'oldPad': _oldPad.map((v) => v.snapshot()).toList(),
    'chord': _chord,
    'blend': _blendStart,
    'voices': _voices.map((v) => v.snapshot()).toList(),
    'pending': _pending.map((e) => e.toJson()).toList(),
    'spaces': _spaces.map((s) => s.snapshot()).toList(),
    'dsp': [
      _brown,
      _pink,
      _water,
      _wind,
      _textureLeft,
      _textureRight,
      _carrierL,
      _carrierR,
      _warmth,
      _complexity,
      reverb,
      cutoffOverride,
      _rain,
      _crackle,
    ],
  };
}
