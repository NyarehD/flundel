import 'package:flutter/material.dart';
import 'package:flundel/visualization/generative/engine/visual_engine.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/layers/visual_layer.dart';
import 'package:flundel/visualization/generative/profiles/visual_profile.dart';

/// Deformed Grid Layer combining structured geometry with spatial field displacement.
class GridLayer extends VisualLayer {
  final double baseSpacing;

  const GridLayer({
    this.baseSpacing = 40.0,
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

    final spacing = baseSpacing * (1.2 - params.density * 0.4);
    final columns = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;

    final noise = engine.noise;
    final time = engine.topologyTime;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = palette.secondary.withValues(
        alpha: (0.15 * params.brightness).clamp(0.0, 0.3),
      )
      ..isAntiAlias = true;

    final pointGrid = List.generate(
      rows + 1,
      (r) => List<Offset>.generate(columns + 1, (c) => Offset.zero),
    );

    final maxDisplacement = spacing * 0.35 * params.turbulence;

    for (var r = 0; r <= rows; r++) {
      for (var c = 0; c <= columns; c++) {
        final gx = c * spacing;
        final gy = r * spacing;

        final dx = noise.eval3D(gx * 0.005, gy * 0.005, time) * maxDisplacement;
        final dy = noise.eval3D(gx * 0.005 + 100.0, gy * 0.005, time) * maxDisplacement;

        pointGrid[r][c] = Offset(gx + dx, gy + dy);
      }
    }

    // Draw horizontal grid lines
    for (var r = 0; r <= rows; r++) {
      final path = Path()..moveTo(pointGrid[r][0].dx, pointGrid[r][0].dy);
      for (var c = 1; c <= columns; c++) {
        path.lineTo(pointGrid[r][c].dx, pointGrid[r][c].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw vertical grid lines
    for (var c = 0; c <= columns; c++) {
      final path = Path()..moveTo(pointGrid[0][c].dx, pointGrid[0][c].dy);
      for (var r = 1; r <= rows; r++) {
        path.lineTo(pointGrid[r][c].dx, pointGrid[r][c].dy);
      }
      canvas.drawPath(path, paint);
    }
  }
}
