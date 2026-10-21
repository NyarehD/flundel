import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flundel/visualization/generative/engine/visual_engine.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/layers/visual_layer.dart';
import 'package:flundel/visualization/generative/profiles/visual_profile.dart';

/// Orbital Layer rendering partial arcs, concentric rings, and eccentric circles.
class OrbitalLayer extends VisualLayer {
  final int ringCount;

  const OrbitalLayer({
    this.ringCount = 5,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualEngine engine,
    VisualParameters params,
    ColorPalette palette,
  ) {
    if (size.isEmpty) return;

    final center = Offset(size.width / 2.0, size.height / 2.0);
    final maxRadius = math.min(size.width, size.height) * 0.4;
    final time = engine.topologyTime;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 + params.complexity * 0.5
      ..isAntiAlias = true;

    for (var i = 1; i <= ringCount; i++) {
      final ringSeed = i * 37 + engine.seed.patternSeed;
      final radius = maxRadius * (i / ringCount) + math.sin(time * 0.5 + i) * 6.0 * params.pulse;

      final startAngle = (time * (0.2 + (i % 3) * 0.1) + ringSeed) % (math.pi * 2.0);
      final sweepAngle = math.pi * (0.4 + ((i * 19) % 10) / 20.0);

      final alpha = (0.18 + (i % 3) * 0.04) * params.brightness;
      paint.color = palette.accent.withValues(alpha: alpha.clamp(0.0, 0.35));

      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
  }
}
