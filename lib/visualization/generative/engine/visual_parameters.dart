import 'dart:ui';

/// Common parameter model driving generative visual rendering.
///
/// All values are normalized between 0.0 and 1.0 where applicable.
class VisualParameters {

  const VisualParameters({
    this.energy = 0.5,
    this.density = 0.5,
    this.complexity = 0.5,
    this.flow = 0.5,
    this.pulse = 0.2,
    this.turbulence = 0.2,
    this.brightness = 0.7,
    this.spatialScale = 0.5,
    this.speed = 0.5,
  });
  final double energy;
  final double density;
  final double complexity;
  final double flow;
  final double pulse;
  final double turbulence;
  final double brightness;
  final double spatialScale;
  final double speed;

  static const VisualParameters focus = VisualParameters(
    energy: 0.45,
    density: 0.55,
    complexity: 0.4,
    flow: 0.6,
    turbulence: 0.15,
    brightness: 0.75,
    speed: 0.45,
  );

  static const VisualParameters deepFocus = VisualParameters(
    energy: 0.35,
    density: 0.65,
    flow: 0.4,
    pulse: 0.15,
    turbulence: 0.08,
    brightness: 0.65,
    spatialScale: 0.4,
    speed: 0.3,
  );

  static const VisualParameters relax = VisualParameters(
    energy: 0.25,
    density: 0.35,
    complexity: 0.3,
    flow: 0.8,
    pulse: 0.3,
    brightness: 0.6,
    spatialScale: 0.7,
    speed: 0.25,
  );

  static const VisualParameters sleep = VisualParameters(
    energy: 0.1,
    density: 0.2,
    complexity: 0.15,
    flow: 0.3,
    pulse: 0.1,
    turbulence: 0.05,
    brightness: 0.25,
    spatialScale: 0.8,
    speed: 0.1,
  );

  VisualParameters copyWith({
    double? energy,
    double? density,
    double? complexity,
    double? flow,
    double? pulse,
    double? turbulence,
    double? brightness,
    double? spatialScale,
    double? speed,
  }) {
    return VisualParameters(
      energy: energy ?? this.energy,
      density: density ?? this.density,
      complexity: complexity ?? this.complexity,
      flow: flow ?? this.flow,
      pulse: pulse ?? this.pulse,
      turbulence: turbulence ?? this.turbulence,
      brightness: brightness ?? this.brightness,
      spatialScale: spatialScale ?? this.spatialScale,
      speed: speed ?? this.speed,
    );
  }

  /// Linearly interpolates smoothly toward target parameters.
  VisualParameters lerp(VisualParameters target, double t) {
    final factor = t.clamp(0.0, 1.0);
    return VisualParameters(
      energy: lerpDouble(energy, target.energy, factor)!,
      density: lerpDouble(density, target.density, factor)!,
      complexity: lerpDouble(complexity, target.complexity, factor)!,
      flow: lerpDouble(flow, target.flow, factor)!,
      pulse: lerpDouble(pulse, target.pulse, factor)!,
      turbulence: lerpDouble(turbulence, target.turbulence, factor)!,
      brightness: lerpDouble(brightness, target.brightness, factor)!,
      spatialScale: lerpDouble(spatialScale, target.spatialScale, factor)!,
      speed: lerpDouble(speed, target.speed, factor)!,
    );
  }
}
