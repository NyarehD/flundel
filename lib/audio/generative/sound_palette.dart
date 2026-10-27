import 'package:flundel/audio/procedural/harmony_controller.dart';

/// Physical destination for a synthesized event. These names stay identical to
/// the existing eleven native streams; no palette may introduce a new stream.
enum VoiceStem { piano, chimes, noise, beats, bass, nature, wind, water, birds }

/// Synthesis family. Recipes keep all timing and timbre values in one place so
/// the renderer does not need a large mode-specific switch.
enum VoiceSignal { tonal, bird, cricket, owl, frog, noise, kick, snare, hat }

/// Ambient bed character. A bed is continuous and lives on the existing
/// noise/nature/wind/water stems rather than creating new native sources.
enum AmbientBed { air, room, rain, ocean, stream, night, vinyl, forest }

class Partial {
  const Partial(this.ratio, this.amplitude, {this.decay = 0, this.phase = 0});

  /// Frequency multiplier relative to the event frequency.
  final double ratio;
  final double amplitude;

  /// Additional exponential decay in nepers per second.
  final double decay;

  /// Fixed phase offset in radians.
  final double phase;
}

class VoiceSpec {
  const VoiceSpec({
    required this.stem,
    required this.signal,
    required this.attack,
    required this.decay,
    required this.duration,
    this.partials = const [Partial(1, 1)],
    this.noiseMix = 0,
    this.noiseDecay = 0,
    this.noiseLowpass = 1,
    this.noiseHighpass = false,
    this.pitchGlideHz = 0,
    this.glideDecay = 20,
    this.chirpRate = 0,
    this.chirpDepthHz = 0,
    this.chirpRiseHz = 0,
    this.vibratoHz = 0,
    this.vibratoDepth = 0,
    this.tremoloHz = 0,
    this.tremoloDepth = 0,
    this.sourceGain = .2,
    this.voiceLimit = 2,
    this.melodic = false,
  });

  final VoiceStem stem;
  final VoiceSignal signal;
  final double attack;
  final double decay;
  final double duration;
  final List<Partial> partials;
  final double noiseMix;
  final double noiseDecay;

  /// One-pole filter coefficient. `1` bypasses filtering.
  final double noiseLowpass;
  final bool noiseHighpass;
  final double pitchGlideHz;
  final double glideDecay;
  final double chirpRate;
  final double chirpDepthHz;
  final double chirpRiseHz;
  final double vibratoHz;
  final double vibratoDepth;
  final double tremoloHz;
  final double tremoloDepth;
  final double sourceGain;
  final int voiceLimit;

  /// Melodic voices follow chord changes while unplayed notes are pending.
  final bool melodic;
}

/// Original procedural voice catalogue. All values are calibrated before user
/// gains, matching the renderer's fixed-source-gain policy.
class VoiceLibrary {
  static const Map<String, VoiceSpec> specs = {
    'piano': VoiceSpec(
      stem: VoiceStem.piano,
      signal: VoiceSignal.tonal,
      attack: .018,
      decay: 1.8,
      duration: 4,
      partials: [Partial(1, 1), Partial(2, .18, decay: 3), Partial(3, .025)],
      sourceGain: .30,
      voiceLimit: 8,
      melodic: true,
    ),
    'felt_piano': VoiceSpec(
      stem: VoiceStem.piano,
      signal: VoiceSignal.tonal,
      attack: .032,
      decay: 1.45,
      duration: 4.5,
      partials: [Partial(1, 1), Partial(2, .11, decay: 4), Partial(3, .014)],
      sourceGain: .30,
      voiceLimit: 8,
      melodic: true,
    ),
    'bright_piano': VoiceSpec(
      stem: VoiceStem.piano,
      signal: VoiceSignal.tonal,
      attack: .012,
      decay: 2.0,
      duration: 4,
      partials: [
        Partial(1, 1),
        Partial(2, .25, decay: 3),
        Partial(3, .06, decay: 4),
        Partial(4, .018),
      ],
      sourceGain: .30,
      voiceLimit: 8,
      melodic: true,
    ),
    'glass_piano': VoiceSpec(
      stem: VoiceStem.piano,
      signal: VoiceSignal.tonal,
      attack: .015,
      decay: 1.6,
      duration: 4.5,
      partials: [
        Partial(1, 1),
        Partial(2.01, .22, decay: 2),
        Partial(3.98, .06, decay: 4),
      ],
      sourceGain: .30,
      voiceLimit: 8,
      melodic: true,
    ),
    'music_box': VoiceSpec(
      stem: VoiceStem.chimes,
      signal: VoiceSignal.tonal,
      attack: .008,
      decay: 1.0,
      duration: 3,
      partials: [
        Partial(1, 1),
        Partial(2, .30, decay: 2),
        Partial(4, .08, decay: 3),
      ],
      sourceGain: .26,
      voiceLimit: 4,
      melodic: true,
    ),
    'kalimba': VoiceSpec(
      stem: VoiceStem.piano,
      signal: VoiceSignal.tonal,
      attack: .006,
      decay: 3.5,
      duration: 2.5,
      partials: [
        Partial(1, 1),
        Partial(2.5, .16, decay: 2),
        Partial(4.1, .04, decay: 3),
      ],
      sourceGain: .28,
      voiceLimit: 4,
      melodic: true,
    ),
    'pluck': VoiceSpec(
      stem: VoiceStem.piano,
      signal: VoiceSignal.tonal,
      attack: .004,
      decay: 5,
      duration: 1.6,
      partials: [
        Partial(1, 1),
        Partial(3, .18, decay: 2),
        Partial(5, .06, decay: 3),
      ],
      sourceGain: .27,
      voiceLimit: 4,
      melodic: true,
    ),
    'bell': VoiceSpec(
      stem: VoiceStem.chimes,
      signal: VoiceSignal.tonal,
      attack: .015,
      decay: 1.0,
      duration: 6,
      partials: [
        Partial(1, 1),
        Partial(2.4, .18, decay: 2),
        Partial(3.7, .08, decay: 3),
      ],
      sourceGain: .28,
      voiceLimit: 2,
      melodic: true,
    ),
    'bowl': VoiceSpec(
      stem: VoiceStem.chimes,
      signal: VoiceSignal.tonal,
      attack: .08,
      decay: .35,
      duration: 10,
      partials: [
        Partial(1, 1),
        Partial(2.7, .22, decay: 1),
        Partial(5.4, .08, decay: 2),
      ],
      sourceGain: .26,
      voiceLimit: 2,
      melodic: true,
    ),
    'gong': VoiceSpec(
      stem: VoiceStem.chimes,
      signal: VoiceSignal.tonal,
      attack: .2,
      decay: .25,
      duration: 12,
      partials: [
        Partial(1, 1),
        Partial(1.48, .30, decay: 1),
        Partial(2.2, .18, decay: 2),
        Partial(3.1, .08, decay: 3),
      ],
      sourceGain: .24,
      voiceLimit: 2,
      melodic: true,
    ),
    'chime': VoiceSpec(
      stem: VoiceStem.chimes,
      signal: VoiceSignal.tonal,
      attack: .025,
      decay: 1.2,
      duration: 5,
      partials: [Partial(1, 1), Partial(2.01, .13, decay: 3)],
      sourceGain: .30,
      voiceLimit: 2,
      melodic: true,
    ),
    'pulse': VoiceSpec(
      stem: VoiceStem.beats,
      signal: VoiceSignal.tonal,
      attack: .045,
      decay: 4.5,
      duration: 1.1,
      sourceGain: .22,
    ),
    'bass': VoiceSpec(
      stem: VoiceStem.bass,
      signal: VoiceSignal.tonal,
      attack: .02,
      decay: 4.5,
      duration: .8,
      sourceGain: .16,
    ),
    'kick': VoiceSpec(
      stem: VoiceStem.beats,
      signal: VoiceSignal.kick,
      attack: .006,
      decay: 15,
      duration: .45,
      pitchGlideHz: 60,
      glideDecay: 25,
      sourceGain: .22,
    ),
    'snare': VoiceSpec(
      stem: VoiceStem.beats,
      signal: VoiceSignal.snare,
      attack: .006,
      decay: 15,
      duration: .3,
      sourceGain: .22,
    ),
    'hat': VoiceSpec(
      stem: VoiceStem.beats,
      signal: VoiceSignal.hat,
      attack: .006,
      decay: 55,
      duration: .12,
      sourceGain: .22,
    ),
    'shaker': VoiceSpec(
      stem: VoiceStem.beats,
      signal: VoiceSignal.noise,
      attack: .004,
      decay: 35,
      duration: .14,
      noiseLowpass: .55,
      noiseHighpass: true,
      sourceGain: .18,
    ),
    'woodblock': VoiceSpec(
      stem: VoiceStem.beats,
      signal: VoiceSignal.tonal,
      attack: .002,
      decay: 80,
      duration: .08,
      partials: [Partial(1, 1), Partial(2.7, .20, decay: 2)],
      noiseMix: .15,
      noiseDecay: 60,
      noiseLowpass: .8,
      noiseHighpass: true,
      sourceGain: .18,
    ),
    'rim': VoiceSpec(
      stem: VoiceStem.beats,
      signal: VoiceSignal.tonal,
      attack: .002,
      decay: 90,
      duration: .06,
      noiseMix: .2,
      noiseDecay: 70,
      noiseLowpass: .75,
      noiseHighpass: true,
      sourceGain: .16,
    ),
    'bird': VoiceSpec(
      stem: VoiceStem.birds,
      signal: VoiceSignal.bird,
      attack: .05,
      decay: 4.0,
      duration: 1.2,
      chirpRate: 18,
      chirpDepthHz: 380,
      chirpRiseHz: 180,
      sourceGain: .16,
    ),
    'cricket': VoiceSpec(
      stem: VoiceStem.birds,
      signal: VoiceSignal.cricket,
      attack: .08,
      decay: 1.4,
      duration: .9,
      tremoloHz: 45,
      tremoloDepth: .45,
      sourceGain: .10,
    ),
    'owl': VoiceSpec(
      stem: VoiceStem.birds,
      signal: VoiceSignal.owl,
      attack: .18,
      decay: 1.1,
      duration: 2.4,
      vibratoHz: .8,
      vibratoDepth: .08,
      tremoloHz: 2.1,
      tremoloDepth: .22,
      sourceGain: .12,
    ),
    'frog': VoiceSpec(
      stem: VoiceStem.birds,
      signal: VoiceSignal.frog,
      attack: .03,
      decay: 4.5,
      duration: .5,
      tremoloHz: 18,
      tremoloDepth: .8,
      sourceGain: .12,
    ),
    'gull': VoiceSpec(
      stem: VoiceStem.birds,
      signal: VoiceSignal.bird,
      attack: .04,
      decay: 2.4,
      duration: 1.4,
      chirpRate: 3,
      chirpDepthHz: 120,
      chirpRiseHz: -70,
      sourceGain: .10,
    ),
    'droplet': VoiceSpec(
      stem: VoiceStem.water,
      signal: VoiceSignal.tonal,
      attack: .004,
      decay: 12,
      duration: .35,
      pitchGlideHz: -500,
      glideDecay: 30,
      sourceGain: .10,
    ),
    'rustle': VoiceSpec(
      stem: VoiceStem.wind,
      signal: VoiceSignal.noise,
      attack: .05,
      decay: 4,
      duration: .9,
      noiseLowpass: .5,
      noiseHighpass: true,
      sourceGain: .10,
    ),
    'wave': VoiceSpec(
      stem: VoiceStem.water,
      signal: VoiceSignal.noise,
      attack: .8,
      decay: .7,
      duration: 5,
      noiseLowpass: .04,
      sourceGain: .16,
    ),
    'thunder': VoiceSpec(
      stem: VoiceStem.nature,
      signal: VoiceSignal.noise,
      attack: .2,
      decay: .5,
      duration: 6,
      noiseLowpass: .008,
      sourceGain: .20,
    ),
    'vinyl': VoiceSpec(
      stem: VoiceStem.noise,
      signal: VoiceSignal.noise,
      attack: .001,
      decay: 90,
      duration: .05,
      noiseLowpass: .7,
      noiseHighpass: true,
      sourceGain: .08,
    ),
    'tape': VoiceSpec(
      stem: VoiceStem.noise,
      signal: VoiceSignal.noise,
      attack: .5,
      decay: .6,
      duration: 5,
      noiseLowpass: .1,
      sourceGain: .05,
    ),
    'breath': VoiceSpec(
      stem: VoiceStem.wind,
      signal: VoiceSignal.noise,
      attack: 1.4,
      decay: .4,
      duration: 7,
      noiseLowpass: .02,
      sourceGain: .08,
    ),
    'sub_swell': VoiceSpec(
      stem: VoiceStem.bass,
      signal: VoiceSignal.tonal,
      attack: .8,
      decay: .4,
      duration: 8,
      partials: [Partial(1, 1), Partial(2, .10)],
      sourceGain: .14,
    ),
  };

  static VoiceSpec of(String kind) => specs[kind] ?? specs['piano']!;

  static bool contains(String kind) => specs.containsKey(kind);
}

class AmbientEventSpec {
  const AmbientEventSpec(
    this.kind, {
    required this.minSeconds,
    required this.maxSeconds,
    this.weight = 1,
    this.minFrequency = 400,
    this.maxFrequency = 1200,
    this.velocity = .5,
    this.followChord = false,
    this.panWidth = 1,
  });

  final String kind;
  final double minSeconds;
  final double maxSeconds;

  /// Higher values make the event more frequent.
  final double weight;
  final double minFrequency;
  final double maxFrequency;
  final double velocity;
  final bool followChord;
  final double panWidth;
}

class PercussionKit {
  const PercussionKit({
    this.kick = 'kick',
    this.snare = 'snare',
    this.hat = 'hat',
    this.pulse = 'pulse',
    this.bass = 'bass',
    this.ghost,
    this.ghostChance = 0,
  });

  final String kick;
  final String snare;
  final String hat;
  final String pulse;
  final String bass;
  final String? ghost;
  final double ghostChance;
}

class BedRecipe {
  const BedRecipe({
    required this.kind,
    this.noiseGain = 1,
    this.natureGain = 1,
    this.windGain = 1,
    this.waterGain = 1,
    this.cutoffBase = 180,
    this.cutoffWarmth = 1200,
    this.cutoffMotion = 300,
    this.swellRateHz = .02,
    this.swellDepth = .25,
    this.flowRateHz = .05,
    this.crackleRate = 0,
  });

  final AmbientBed kind;
  final double noiseGain;
  final double natureGain;
  final double windGain;
  final double waterGain;
  final double cutoffBase;
  final double cutoffWarmth;
  final double cutoffMotion;
  final double swellRateHz;
  final double swellDepth;
  final double flowRateHz;

  /// Per-sample probability of a vinyl crackle impulse.
  final double crackleRate;
}

class HarmonyPalette {
  const HarmonyPalette({
    required this.id,
    required this.start,
    required this.transitions,
  });

  final String id;
  final ChordType start;
  final Map<ChordType, List<ChordType>> transitions;
}

/// Authored identity for one built-in mode. ArrangementProfile still controls
/// musical limits; this palette controls which sounds express those limits.
class ModeSoundPalette {
  const ModeSoundPalette({
    required this.id,
    required this.melodicVoices,
    required this.ambientEvents,
    required this.percussion,
    required this.bed,
    required this.harmonies,
    this.melodyNoteCount = 2,
    this.variants = 2,
  });

  final String id;
  final List<String> melodicVoices;
  final List<AmbientEventSpec> ambientEvents;
  final PercussionKit percussion;
  final BedRecipe bed;
  final List<HarmonyPalette> harmonies;
  final int melodyNoteCount;
  final int variants;

  static const _chime = AmbientEventSpec(
    'chime',
    minSeconds: 30,
    maxSeconds: 55,
    minFrequency: 500,
    maxFrequency: 2200,
    velocity: .55,
    followChord: true,
  );
  static const _bell = AmbientEventSpec(
    'bell',
    minSeconds: 42,
    maxSeconds: 72,
    minFrequency: 300,
    maxFrequency: 1600,
    velocity: .45,
    followChord: true,
  );
  static const _bowl = AmbientEventSpec(
    'bowl',
    minSeconds: 24,
    maxSeconds: 45,
    minFrequency: 220,
    maxFrequency: 700,
    velocity: .50,
    followChord: true,
  );
  static const _gong = AmbientEventSpec(
    'gong',
    minSeconds: 45,
    maxSeconds: 80,
    minFrequency: 90,
    maxFrequency: 330,
    velocity: .45,
    followChord: true,
  );
  static const _bird = AmbientEventSpec(
    'bird',
    minSeconds: 5,
    maxSeconds: 14,
    minFrequency: 1700,
    maxFrequency: 3400,
    velocity: .55,
  );
  static const _cricket = AmbientEventSpec(
    'cricket',
    minSeconds: 6,
    maxSeconds: 14,
    minFrequency: 3500,
    maxFrequency: 5000,
    velocity: .25,
  );
  static const _owl = AmbientEventSpec(
    'owl',
    minSeconds: 25,
    maxSeconds: 50,
    minFrequency: 300,
    maxFrequency: 500,
    velocity: .35,
  );
  static const _frog = AmbientEventSpec(
    'frog',
    minSeconds: 20,
    maxSeconds: 45,
    minFrequency: 160,
    maxFrequency: 300,
    velocity: .30,
  );
  static const _gull = AmbientEventSpec(
    'gull',
    minSeconds: 20,
    maxSeconds: 45,
    minFrequency: 900,
    maxFrequency: 1500,
    velocity: .35,
  );
  static const _droplet = AmbientEventSpec(
    'droplet',
    minSeconds: 15,
    maxSeconds: 30,
    minFrequency: 700,
    maxFrequency: 1400,
    velocity: .35,
  );
  static const _rustle = AmbientEventSpec(
    'rustle',
    minSeconds: 12,
    maxSeconds: 28,
    minFrequency: 500,
    maxFrequency: 1500,
    velocity: .25,
  );
  static const _wave = AmbientEventSpec(
    'wave',
    minSeconds: 8,
    maxSeconds: 18,
    minFrequency: 400,
    maxFrequency: 900,
    velocity: .45,
  );
  static const _thunder = AmbientEventSpec(
    'thunder',
    minSeconds: 60,
    maxSeconds: 110,
    minFrequency: 60,
    maxFrequency: 120,
    velocity: .50,
  );
  static const _vinyl = AmbientEventSpec(
    'vinyl',
    minSeconds: 4,
    maxSeconds: 9,
    minFrequency: 1000,
    maxFrequency: 2000,
    velocity: .20,
  );
  static const _breath = AmbientEventSpec(
    'breath',
    minSeconds: 35,
    maxSeconds: 60,
    minFrequency: 300,
    maxFrequency: 800,
    velocity: .25,
  );

  static const _warmMinor = HarmonyPalette(
    id: 'warm_minor',
    start: ChordType.am7,
    transitions: {
      ChordType.am7: [ChordType.fMaj7, ChordType.cMaj7, ChordType.em7],
      ChordType.fMaj7: [ChordType.cMaj7, ChordType.am9, ChordType.dMaj7],
      ChordType.cMaj7: [ChordType.am7, ChordType.fMaj7, ChordType.em7],
      ChordType.em7: [ChordType.am7, ChordType.fMaj7],
      ChordType.dMaj7: [ChordType.fMaj7, ChordType.am7],
      ChordType.am9: [ChordType.fMaj7, ChordType.cMaj9, ChordType.em7],
      ChordType.cMaj9: [ChordType.am9, ChordType.fMaj7],
      ChordType.fMaj7Sharp11: [ChordType.cMaj9, ChordType.am9],
    },
  );
  static const _brightMajor = HarmonyPalette(
    id: 'bright_major',
    start: ChordType.cMaj7,
    transitions: {
      ChordType.cMaj7: [ChordType.am7, ChordType.fMaj7, ChordType.dMaj7],
      ChordType.am7: [ChordType.fMaj7, ChordType.cMaj7, ChordType.em7],
      ChordType.fMaj7: [ChordType.cMaj7, ChordType.dMaj7, ChordType.am9],
      ChordType.dMaj7: [ChordType.fMaj7, ChordType.cMaj7, ChordType.am7],
      ChordType.em7: [ChordType.am7, ChordType.cMaj7],
      ChordType.am9: [ChordType.cMaj9, ChordType.fMaj7],
      ChordType.cMaj9: [ChordType.am9, ChordType.fMaj7],
      ChordType.fMaj7Sharp11: [ChordType.cMaj9, ChordType.dMaj7],
    },
  );
  static const _suspended = HarmonyPalette(
    id: 'suspended',
    start: ChordType.am9,
    transitions: {
      ChordType.am9: [ChordType.fMaj7Sharp11, ChordType.cMaj9, ChordType.fMaj7],
      ChordType.fMaj7Sharp11: [ChordType.cMaj9, ChordType.am9, ChordType.dMaj7],
      ChordType.cMaj9: [ChordType.am9, ChordType.fMaj7Sharp11, ChordType.em7],
      ChordType.fMaj7: [ChordType.cMaj7, ChordType.am9],
      ChordType.cMaj7: [ChordType.fMaj7, ChordType.am9],
      ChordType.em7: [ChordType.am9, ChordType.fMaj7],
      ChordType.dMaj7: [ChordType.fMaj7Sharp11, ChordType.am9],
    },
  );
  static const _jazzy = HarmonyPalette(
    id: 'jazzy',
    start: ChordType.dMaj7,
    transitions: {
      ChordType.dMaj7: [ChordType.fMaj7, ChordType.am9, ChordType.cMaj9],
      ChordType.fMaj7: [ChordType.cMaj9, ChordType.am9, ChordType.dMaj7],
      ChordType.am9: [ChordType.cMaj9, ChordType.fMaj7Sharp11, ChordType.dMaj7],
      ChordType.cMaj9: [ChordType.am9, ChordType.fMaj7, ChordType.em7],
      ChordType.fMaj7Sharp11: [ChordType.cMaj9, ChordType.am9],
      ChordType.em7: [ChordType.am9, ChordType.cMaj9],
      ChordType.am7: [ChordType.dMaj7, ChordType.fMaj7],
      ChordType.cMaj7: [ChordType.am7, ChordType.fMaj7],
    },
  );
  static const _nightMinor = HarmonyPalette(
    id: 'night_minor',
    start: ChordType.em7,
    transitions: {
      ChordType.em7: [ChordType.am9, ChordType.dMaj7, ChordType.fMaj7],
      ChordType.am9: [ChordType.em7, ChordType.fMaj7, ChordType.dMaj7],
      ChordType.dMaj7: [ChordType.am9, ChordType.em7],
      ChordType.fMaj7: [ChordType.em7, ChordType.am9],
      ChordType.am7: [ChordType.em7, ChordType.fMaj7],
      ChordType.cMaj7: [ChordType.am9, ChordType.fMaj7],
      ChordType.cMaj9: [ChordType.am9, ChordType.em7],
      ChordType.fMaj7Sharp11: [ChordType.dMaj7, ChordType.am9],
    },
  );
  static const _forestMajor = HarmonyPalette(
    id: 'forest_major',
    start: ChordType.fMaj7,
    transitions: {
      ChordType.fMaj7: [ChordType.cMaj7, ChordType.am7, ChordType.dMaj7],
      ChordType.cMaj7: [ChordType.am7, ChordType.fMaj7, ChordType.em7],
      ChordType.am7: [ChordType.cMaj7, ChordType.fMaj7, ChordType.em7],
      ChordType.dMaj7: [ChordType.fMaj7, ChordType.cMaj7],
      ChordType.em7: [ChordType.am7, ChordType.fMaj7],
      ChordType.am9: [ChordType.fMaj7, ChordType.cMaj9],
      ChordType.cMaj9: [ChordType.am9, ChordType.fMaj7],
      ChordType.fMaj7Sharp11: [ChordType.cMaj9, ChordType.dMaj7],
    },
  );

  static const Map<String, ModeSoundPalette> byId = {
    'deep_work': ModeSoundPalette(
      id: 'deep_work',
      melodicVoices: ['felt_piano', 'piano'],
      ambientEvents: [_bell, _breath, _rustle],
      percussion: PercussionKit(),
      bed: BedRecipe(
        kind: AmbientBed.room,
        noiseGain: .45,
        natureGain: .30,
        windGain: .35,
        waterGain: .10,
        cutoffBase: 90,
        cutoffWarmth: 400,
        cutoffMotion: 120,
        swellRateHz: .012,
        swellDepth: .18,
        flowRateHz: .02,
      ),
      harmonies: [_warmMinor, _brightMajor],
      melodyNoteCount: 2,
    ),
    'coding': ModeSoundPalette(
      id: 'coding',
      melodicVoices: ['pluck', 'glass_piano'],
      ambientEvents: [_chime, _rustle],
      percussion: PercussionKit(),
      bed: BedRecipe(
        kind: AmbientBed.air,
        noiseGain: .85,
        natureGain: .25,
        windGain: .30,
        waterGain: .20,
        cutoffBase: 220,
        cutoffWarmth: 950,
        cutoffMotion: 250,
        swellRateHz: .03,
        swellDepth: .22,
        flowRateHz: .08,
      ),
      harmonies: [_brightMajor, _warmMinor],
      melodyNoteCount: 2,
    ),
    'reading': ModeSoundPalette(
      id: 'reading',
      melodicVoices: ['kalimba', 'felt_piano'],
      ambientEvents: [_chime, _bird, _droplet, _rustle],
      percussion: PercussionKit(ghost: 'rim', ghostChance: .06),
      bed: BedRecipe(
        kind: AmbientBed.rain,
        noiseGain: 1.05,
        natureGain: .45,
        windGain: .20,
        waterGain: .40,
        cutoffBase: 700,
        cutoffWarmth: 500,
        cutoffMotion: 160,
        swellRateHz: .10,
        swellDepth: .18,
        flowRateHz: .14,
      ),
      harmonies: [_brightMajor, _suspended],
      melodyNoteCount: 2,
    ),
    'quiet_focus': ModeSoundPalette(
      id: 'quiet_focus',
      melodicVoices: ['felt_piano'],
      ambientEvents: [_chime, _breath],
      percussion: PercussionKit(),
      bed: BedRecipe(
        kind: AmbientBed.room,
        noiseGain: .40,
        natureGain: .20,
        windGain: .25,
        waterGain: .05,
        cutoffBase: 70,
        cutoffWarmth: 260,
        cutoffMotion: 80,
        swellRateHz: .008,
        swellDepth: .12,
        flowRateHz: .015,
      ),
      harmonies: [_suspended, _warmMinor],
      melodyNoteCount: 1,
    ),
    'piano_focus': ModeSoundPalette(
      id: 'piano_focus',
      melodicVoices: ['felt_piano', 'bright_piano', 'glass_piano'],
      ambientEvents: [_chime, _rustle],
      percussion: PercussionKit(),
      bed: BedRecipe(
        kind: AmbientBed.room,
        noiseGain: .30,
        natureGain: .20,
        windGain: .18,
        waterGain: .05,
        cutoffBase: 110,
        cutoffWarmth: 380,
        cutoffMotion: 120,
        swellRateHz: .015,
        swellDepth: .16,
        flowRateHz: .03,
      ),
      harmonies: [_brightMajor, _warmMinor],
      melodyNoteCount: 3,
    ),
    'night_focus': ModeSoundPalette(
      id: 'night_focus',
      melodicVoices: ['music_box', 'felt_piano'],
      ambientEvents: [_cricket, _owl, _droplet, _chime],
      percussion: PercussionKit(),
      bed: BedRecipe(
        kind: AmbientBed.night,
        noiseGain: .50,
        natureGain: .30,
        windGain: .40,
        waterGain: .15,
        cutoffBase: 80,
        cutoffWarmth: 360,
        cutoffMotion: 120,
        swellRateHz: .008,
        swellDepth: .12,
        flowRateHz: .012,
      ),
      harmonies: [_nightMinor, _suspended],
      melodyNoteCount: 2,
    ),
    'ocean_drift': ModeSoundPalette(
      id: 'ocean_drift',
      melodicVoices: ['bell', 'pluck'],
      ambientEvents: [_wave, _gull, _chime, _droplet, _thunder],
      percussion: PercussionKit(),
      bed: BedRecipe(
        kind: AmbientBed.ocean,
        noiseGain: .70,
        natureGain: 1.10,
        windGain: .50,
        waterGain: 1.30,
        cutoffBase: 120,
        cutoffWarmth: 800,
        cutoffMotion: 250,
        swellRateHz: .07,
        swellDepth: .45,
        flowRateHz: .03,
      ),
      harmonies: [_suspended, _forestMajor],
      melodyNoteCount: 2,
    ),
    'zen_meditation': ModeSoundPalette(
      id: 'zen_meditation',
      melodicVoices: ['bowl', 'gong', 'bell'],
      ambientEvents: [_bowl, _gong, _droplet, _breath],
      percussion: PercussionKit(),
      bed: BedRecipe(
        kind: AmbientBed.air,
        noiseGain: .45,
        natureGain: .35,
        windGain: .35,
        waterGain: .20,
        cutoffBase: 110,
        cutoffWarmth: 650,
        cutoffMotion: 180,
        swellRateHz: .015,
        swellDepth: .20,
        flowRateHz: .025,
      ),
      harmonies: [_suspended, _warmMinor],
      melodyNoteCount: 1,
    ),
    'lofi_study': ModeSoundPalette(
      id: 'lofi_study',
      melodicVoices: ['felt_piano', 'kalimba'],
      ambientEvents: [_vinyl, _chime, _rustle],
      percussion: PercussionKit(ghost: 'woodblock', ghostChance: .18),
      bed: BedRecipe(
        kind: AmbientBed.vinyl,
        noiseGain: 1.15,
        natureGain: .05,
        windGain: .05,
        waterGain: .05,
        cutoffBase: 160,
        cutoffWarmth: 700,
        cutoffMotion: 80,
        swellRateHz: .02,
        swellDepth: .10,
        flowRateHz: .04,
        crackleRate: .00045,
      ),
      harmonies: [_jazzy, _warmMinor, _brightMajor],
      melodyNoteCount: 2,
      variants: 3,
    ),
    'forest_stream': ModeSoundPalette(
      id: 'forest_stream',
      melodicVoices: ['pluck', 'kalimba', 'bell'],
      ambientEvents: [_bird, _rustle, _droplet, _frog, _chime],
      percussion: PercussionKit(ghost: 'rim', ghostChance: .04),
      bed: BedRecipe(
        kind: AmbientBed.forest,
        noiseGain: .75,
        natureGain: 1.05,
        windGain: .70,
        waterGain: 1.10,
        cutoffBase: 260,
        cutoffWarmth: 900,
        cutoffMotion: 420,
        swellRateHz: .04,
        swellDepth: .28,
        flowRateHz: .22,
      ),
      harmonies: [_forestMajor, _brightMajor],
      melodyNoteCount: 2,
    ),
  };

  static ModeSoundPalette forId(String id) => byId[id] ?? byId['deep_work']!;

  /// Ambient event kinds must be unique because their next-fire times are
  /// checkpointed in a map keyed by kind.
  bool get hasUniqueAmbientKinds =>
      ambientEvents.map((e) => e.kind).toSet().length == ambientEvents.length;
}
