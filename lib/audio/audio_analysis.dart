class AudioAnalysis {

  const AudioAnalysis({
    required this.amplitude,
    required this.tonalEnergy,
    required this.textureEnergy,
    required this.pianoActivity,
    required this.focusDepth,
    this.hasPianoEvent = false,
  });
  final double amplitude;
  final double tonalEnergy;
  final double textureEnergy;
  final double pianoActivity;
  final double focusDepth;
  final bool hasPianoEvent;

  // Backwards compatibility helpers
  double get lowEnergy => tonalEnergy;
  double get midEnergy => (tonalEnergy + textureEnergy) / 2;
  double get highEnergy => textureEnergy;
  double get sessionIntensity => focusDepth;
}

enum AudioEngineState { stopped, starting, playing, paused }
