/// Authored limits; user levels remain independent of composition density.
class ArrangementProfile {
  const ArrangementProfile(
    this.id, {
    this.chordSeconds = 36,
    this.phraseSeconds = 18,
    this.modulation = .08,
    this.width = .45,
    this.lowNote = 220,
    this.highNote = 784,
    this.pulseDensity = .7,
    this.natureMotion = .35,
    this.brightness = .5,
    this.padPresence = 1,
    this.texturePresence = .3,
    this.drums = false,
  });
  final String id;
  final double chordSeconds;
  final double phraseSeconds;
  final double modulation;
  final double width;
  final double lowNote;
  final double highNote;
  final double pulseDensity;
  final double natureMotion;
  final double brightness;

  /// Fixed source balance, independent of saved layer and master controls.
  final double padPresence;

  /// Environmental profiles retain their texture; focus beds keep air subdued.
  final double texturePresence;
  final bool drums;

  static const profiles = <String, ArrangementProfile>{
    'deep_work': ArrangementProfile(
      'deep_work',
      chordSeconds: 42,
      phraseSeconds: 16,
      brightness: .38,
      padPresence: 1.15,
      texturePresence: .15,
    ),
    'coding': ArrangementProfile(
      'coding',
      chordSeconds: 32,
      phraseSeconds: 12,
      pulseDensity: .9,
      modulation: .11,
      brightness: .55,
      padPresence: 1.15,
      texturePresence: .2,
    ),
    'reading': ArrangementProfile(
      'reading',
      phraseSeconds: 15,
      pulseDensity: .35,
      natureMotion: .5,
      brightness: .42,
    ),
    'quiet_focus': ArrangementProfile(
      'quiet_focus',
      chordSeconds: 58,
      phraseSeconds: 38,
      modulation: .025,
      width: .2,
      pulseDensity: 0,
      brightness: .25,
      texturePresence: .12,
    ),
    'piano_focus': ArrangementProfile(
      'piano_focus',
      chordSeconds: 34,
      phraseSeconds: 7,
      lowNote: 261.63,
      highNote: 1046.5,
      width: .55,
      pulseDensity: .3,
      brightness: .6,
    ),
    'night_focus': ArrangementProfile(
      'night_focus',
      chordSeconds: 60,
      phraseSeconds: 32,
      lowNote: 164.81,
      highNote: 523.25,
      modulation: .035,
      width: .25,
      pulseDensity: 0,
      brightness: .18,
      texturePresence: .12,
    ),
    'ocean_drift': ArrangementProfile(
      'ocean_drift',
      chordSeconds: 52,
      phraseSeconds: 34,
      modulation: .13,
      width: .65,
      pulseDensity: 0,
      natureMotion: .9,
      brightness: .3,
      texturePresence: 1,
    ),
    'zen_meditation': ArrangementProfile(
      'zen_meditation',
      chordSeconds: 56,
      phraseSeconds: 26,
      modulation: .045,
      width: .55,
      pulseDensity: .2,
      natureMotion: .45,
      brightness: .32,
      texturePresence: .55,
    ),
    'lofi_study': ArrangementProfile(
      'lofi_study',
      chordSeconds: 30,
      phraseSeconds: 13,
      modulation: .06,
      width: .4,
      pulseDensity: .85,
      brightness: .48,
      drums: true,
      texturePresence: .45,
    ),
    'forest_stream': ArrangementProfile(
      'forest_stream',
      chordSeconds: 48,
      phraseSeconds: 25,
      modulation: .075,
      width: .7,
      pulseDensity: .15,
      natureMotion: .8,
      brightness: .55,
      texturePresence: 1,
    ),
  };
  static ArrangementProfile forId(String id) =>
      profiles[id] ?? const ArrangementProfile('custom', drums: true);
}
