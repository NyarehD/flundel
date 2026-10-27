import 'dart:math';

/// Equal-power weights for overlapping decorrelated pads. Source gain staging
/// leaves headroom for shared chord tones, which can still sum coherently.
class PadBlend {
  static ({double outgoing, double incoming}) weights(double progress) {
    final angle = progress.clamp(0.0, 1.0) * pi / 2;
    return (outgoing: cos(angle), incoming: sin(angle));
  }
}
