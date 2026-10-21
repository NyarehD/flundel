import 'dart:math' as math;

import 'package:flundel/visualization/generative/engine/noise.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';

/// Wave Interference Field combining multiple low-frequency wave functions.
///
/// Used to influence line displacement, particle location, brightness,
/// and contour deformation.
class WaveField {
  const WaveField();

  /// Evaluates wave interference scalar field value at (x, y) at time t.
  double evaluate(
    double x,
    double y,
    double time,
    GenerativeNoise noise,
    VisualParameters params,
  ) {
    final spatialScale = 0.002 + params.spatialScale * 0.004;
    final waveA = math.sin(x * spatialScale + time * 0.4);
    final waveB = math.cos(y * spatialScale * 1.3 - time * 0.3);
    final waveC = math.sin((x + y) * spatialScale * 0.7 + time * 0.5);

    final interference = (waveA + waveB + waveC) / 3.0;

    final n = noise.eval3D(
      x * spatialScale * 0.5,
      y * spatialScale * 0.5,
      time * 0.1,
    );

    return (interference * 0.7 + n * 0.3 * params.complexity).clamp(-1.0, 1.0);
  }
}
