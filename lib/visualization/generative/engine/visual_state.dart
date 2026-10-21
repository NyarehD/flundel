import 'dart:ui';

import 'package:flundel/audio/audio_analysis.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';

/// Intermediate visual state computed from audio state analysis.
///
/// Decouples visual rendering from raw PCM audio samples and provides
/// high-level soundscape attributes.
class AudioVisualState {
  final double intensity;
  final double rhythm;
  final double density;
  final double brightness;
  final double movement;
  final double complexity;

  const AudioVisualState({
    this.intensity = 0.5,
    this.rhythm = 0.2,
    this.density = 0.5,
    this.brightness = 0.7,
    this.movement = 0.4,
    this.complexity = 0.5,
  });

  factory AudioVisualState.fromAudioAnalysis(AudioAnalysis analysis) {
    return AudioVisualState(
      intensity: _unit(analysis.amplitude),
      rhythm: _unit(analysis.pianoActivity),
      density: _unit(analysis.textureEnergy),
      brightness: _unit(analysis.tonalEnergy),
      movement: _unit(1.0 - analysis.focusDepth * 0.5),
      complexity: _unit(1.0 - analysis.focusDepth * 0.4),
    );
  }

  static double _unit(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0) : 0.0;

  AudioVisualState lerp(AudioVisualState target, double t) {
    final factor = t.clamp(0.0, 1.0);
    return AudioVisualState(
      intensity: lerpDouble(intensity, target.intensity, factor)!,
      rhythm: lerpDouble(rhythm, target.rhythm, factor)!,
      density: lerpDouble(density, target.density, factor)!,
      brightness: lerpDouble(brightness, target.brightness, factor)!,
      movement: lerpDouble(movement, target.movement, factor)!,
      complexity: lerpDouble(complexity, target.complexity, factor)!,
    );
  }

  /// Converts high-level audio metrics to adjusted [VisualParameters].
  VisualParameters applyToParameters(VisualParameters base) {
    return base.copyWith(
      energy: (base.energy * 0.6 + intensity * 0.4).clamp(0.0, 1.0),
      density: (base.density * 0.6 + density * 0.4).clamp(0.0, 1.0),
      complexity: (base.complexity * 0.7 + complexity * 0.3).clamp(0.0, 1.0),
      flow: (base.flow * 0.6 + movement * 0.4).clamp(0.0, 1.0),
      pulse: (base.pulse * 0.5 + rhythm * 0.5).clamp(0.0, 1.0),
      brightness: (base.brightness * 0.6 + brightness * 0.4).clamp(0.0, 1.0),
      speed: (base.speed * 0.7 + movement * 0.3).clamp(0.0, 1.0),
    );
  }
}
