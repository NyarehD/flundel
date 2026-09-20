class AudioAnalysis {
  final double amplitude;
  final double lowEnergy;
  final double midEnergy;
  final double highEnergy;
  final double sessionIntensity;
  final bool hasPianoEvent;

  const AudioAnalysis({
    required this.amplitude,
    required this.lowEnergy,
    required this.midEnergy,
    required this.highEnergy,
    required this.sessionIntensity,
    this.hasPianoEvent = false,
  });
}

enum AudioEngineState { stopped, starting, playing, paused }
