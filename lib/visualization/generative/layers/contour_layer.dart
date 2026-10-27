import 'dart:math' as math;

import 'package:flundel/visualization/generative/engine/visual_engine.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/layers/visual_layer.dart';
import 'package:flundel/visualization/generative/profiles/visual_profile.dart';
import 'package:flutter/material.dart';

/// Contour Field Layer rendering topographic / fluid-like boundary curves.
class ContourLayer extends VisualLayer {

  const ContourLayer({
    this.contourCount = 8,
  });
  final int contourCount;

  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualEngine engine,
    VisualParameters params,
    ColorPalette palette,
  ) {
    if (size.isEmpty) return;

    final count = (contourCount * (0.6 + params.density * 0.8)).round();
    final noise = engine.noise;
    final time = engine.topologyTime;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    final center = Offset(size.width / 2.0, size.height / 2.0);
    final maxRadius = math.min(size.width, size.height) * 0.45;

    for (var i = 0; i < count; i++) {
      final baseRadius = maxRadius * ((i + 1) / count);
      final path = Path();
      const points = 32;

      for (var p = 0; p <= points; p++) {
        final angle = (p / points) * math.pi * 2.0;
        final px = center.dx + math.cos(angle) * baseRadius;
        final py = center.dy + math.sin(angle) * baseRadius;

        final deform = noise.eval3D(
          px * 0.003,
          py * 0.003,
          time + i * 0.2,
        ) * 30.0 * params.turbulence;

        final radius = (baseRadius + deform).clamp(10.0, maxRadius * 1.5);
        final x = center.dx + math.cos(angle) * radius;
        final y = center.dy + math.sin(angle) * radius;

        if (p == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      final alpha = (0.15 * params.brightness * (1.0 - i / count)).clamp(0.0, 0.3);
      paint.color = palette.primary.withValues(alpha: alpha);
      canvas.drawPath(path, paint);
    }
  }
}
