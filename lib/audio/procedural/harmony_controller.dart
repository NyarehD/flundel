import 'dart:math';

enum ChordType { am7, cMaj7, fMaj7, em7, dMaj7, am9, cMaj9, fMaj7Sharp11 }

class ChordInfo {

  const ChordInfo({
    required this.type,
    required this.name,
    required this.chordFrequencies,
    required this.passingFrequencies,
  });
  final ChordType type;
  final String name;
  final List<double> chordFrequencies;
  final List<double> passingFrequencies;
}

class HarmonyController {
  static const Map<ChordType, ChordInfo> chords = {
    ChordType.am7: ChordInfo(
      type: ChordType.am7,
      name: 'Am7',
      chordFrequencies: [
        220.0,
        261.63,
        329.63,
        392.00,
        440.0,
      ], // A3, C4, E4, G4, A4
      passingFrequencies: [246.94, 293.66, 349.23, 493.88], // B3, D4, F4, B4
    ),
    ChordType.cMaj7: ChordInfo(
      type: ChordType.cMaj7,
      name: 'Cmaj7',
      chordFrequencies: [
        261.63,
        329.63,
        392.00,
        493.88,
        523.25,
      ], // C4, E4, G4, B4, C5
      passingFrequencies: [293.66, 349.23, 440.00, 587.33], // D4, F4, A4, D5
    ),
    ChordType.fMaj7: ChordInfo(
      type: ChordType.fMaj7,
      name: 'Fmaj7',
      chordFrequencies: [
        174.61,
        220.00,
        261.63,
        329.63,
        349.23,
      ], // F3, A3, C4, E4, F4
      passingFrequencies: [196.00, 246.94, 293.66, 392.00], // G3, B3, D4, G4
    ),
    ChordType.em7: ChordInfo(
      type: ChordType.em7,
      name: 'Em7',
      chordFrequencies: [
        164.81,
        196.00,
        246.94,
        293.66,
        329.63,
      ], // E3, G3, B3, D4, E4
      passingFrequencies: [174.61, 220.00, 261.63, 392.00], // F3, A3, C4, G4
    ),
    ChordType.dMaj7: ChordInfo(
      type: ChordType.dMaj7,
      name: 'Dm7',
      chordFrequencies: [
        146.83,
        174.61,
        220.00,
        261.63,
        293.66,
      ], // D3, F3, A3, C4, D4
      passingFrequencies: [164.81, 196.00, 246.94, 329.63], // E3, G3, B3, E4
    ),
    ChordType.am9: ChordInfo(
      type: ChordType.am9,
      name: 'Am9',
      chordFrequencies: [
        220.0,
        261.63,
        329.63,
        392.00,
        493.88,
      ], // A3, C4, E4, G4, B4 (9th)
      passingFrequencies: [246.94, 293.66, 349.23, 440.00], // B3, D4, F4, A4
    ),
    ChordType.cMaj9: ChordInfo(
      type: ChordType.cMaj9,
      name: 'Cmaj9',
      chordFrequencies: [
        261.63,
        329.63,
        392.00,
        493.88,
        587.33,
      ], // C4, E4, G4, B4, D5 (9th)
      passingFrequencies: [293.66, 349.23, 440.00, 523.25], // D4, F4, A4, C5
    ),
    ChordType.fMaj7Sharp11: ChordInfo(
      type: ChordType.fMaj7Sharp11,
      name: 'Fmaj7#11',
      chordFrequencies: [
        174.61,
        220.00,
        261.63,
        329.63,
        493.88,
      ], // F3, A3, C4, E4, B4 (#11)
      passingFrequencies: [196.00, 246.94, 293.66, 349.23], // G3, B3, D4, F4
    ),
  };

  ChordInfo _currentChord = chords[ChordType.am7]!;

  ChordInfo get currentChord => _currentChord;

  void reset() => _currentChord = chords[ChordType.am7]!;

  /// Transition to next chord based on weighted Markov probabilities
  ChordInfo transitionNextChord(Random random) {
    final Map<ChordType, double> transitions;

    switch (_currentChord.type) {
      case ChordType.am7:
      case ChordType.am9:
        transitions = {
          ChordType.fMaj7: 0.30,
          ChordType.cMaj7: 0.25,
          ChordType.cMaj9: 0.20,
          ChordType.em7: 0.15,
          ChordType.fMaj7Sharp11: 0.10,
        };
      case ChordType.cMaj7:
      case ChordType.cMaj9:
        transitions = {
          ChordType.am7: 0.30,
          ChordType.am9: 0.25,
          ChordType.fMaj7: 0.25,
          ChordType.dMaj7: 0.20,
        };
      case ChordType.fMaj7:
      case ChordType.fMaj7Sharp11:
        transitions = {
          ChordType.cMaj7: 0.35,
          ChordType.cMaj9: 0.25,
          ChordType.am7: 0.20,
          ChordType.dMaj7: 0.20,
        };
      case ChordType.em7:
        transitions = {
          ChordType.am7: 0.40,
          ChordType.am9: 0.30,
          ChordType.cMaj7: 0.30,
        };
      case ChordType.dMaj7:
        transitions = {
          ChordType.fMaj7: 0.35,
          ChordType.am7: 0.35,
          ChordType.cMaj9: 0.20,
          ChordType.em7: 0.10,
        };
    }

    final roll = random.nextDouble();
    double cumulative = 0.0;

    for (final entry in transitions.entries) {
      cumulative += entry.value;
      if (roll <= cumulative) {
        _currentChord = chords[entry.key]!;
        return _currentChord;
      }
    }

    _currentChord = chords[ChordType.cMaj7]!;
    return _currentChord;
  }
}
