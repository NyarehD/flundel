import 'dart:math' as math;
import 'dart:ui';

import 'package:flundel/visualization/generative/engine/noise.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';

/// 2D Flow Field generating vector directions θ = f(x, y, time, seed).
///
/// Nearby spatial positions produce related directions for coherent flow.
class FlowField {

  const FlowField({
    this.baseAngle = 0.0,
    this.angleRange = math.pi * 2.0,
  });
  final double baseAngle;
  final double angleRange;

  /// Evaluates angle in radians at (x, y) given current time and parameters.
  double getAngle(
    double x,
    double y,
    double time,
    GenerativeNoise noise,
    VisualParameters params,
  ) {
    final spatialScale = 0.0015 + params.spatialScale * 0.003;
    final temporalScale = 0.1 + params.speed * 0.4;

    final n1 = noise.eval3D(
      x * spatialScale,
      y * spatialScale,
      time * temporalScale,
    );

    var angle = baseAngle + n1 * angleRange;

    if (params.turbulence > 0.05) {
      final n2 = noise.eval3D(
        x * spatialScale * 2.5,
        y * spatialScale * 2.5,
        time * temporalScale * 1.8,
      );
      angle += n2 * params.turbulence * math.pi;
    }

    return angle;
  }

  /// Evaluates unit direction vector Offset(cos(angle), sin(angle)).
  Offset getVector(
    double x,
    double y,
    double time,
    GenerativeNoise noise,
    VisualParameters params,
  ) {
    final angle = getAngle(x, y, time, noise, params);
    return Offset(math.cos(angle), math.sin(angle));
  }
}
