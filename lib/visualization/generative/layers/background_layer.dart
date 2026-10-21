import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flundel/visualization/generative/engine/visual_engine.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/layers/visual_layer.dart';
import 'package:flundel/visualization/generative/profiles/visual_profile.dart';

/// Low-contrast background color field with subtle animated radial depth glow.
class BackgroundLayer extends VisualLayer {
  const BackgroundLayer();

  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualEngine engine,
    VisualParameters params,
    ColorPalette palette,
  ) {
    // Fill base background
    canvas.drawColor(palette.background, BlendMode.src);
    if (size.isEmpty) return;

    final center = Offset(size.width / 2.0, size.height / 2.0);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) * 0.6;

    final pulseShift = math.sin(engine.pulseTime * 2.0) * 0.05 * params.pulse;
    final glowRadius = maxRadius * (0.8 + pulseShift);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.primary.withValues(alpha: 0.08 * params.brightness),
          palette.secondary.withValues(alpha: 0.03 * params.brightness),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));

    canvas.drawCircle(center, glowRadius, glowPaint);
  }
}
