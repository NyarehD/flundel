import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flundel/visualization/generative/engine/visual_engine.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/layers/visual_layer.dart';
import 'package:flundel/visualization/generative/profiles/visual_profile.dart';

/// Soft Blobs Layer generating breathing organic shapes deforming with smooth noise.
class BlobLayer extends VisualLayer {
  final int controlPointCount;

  const BlobLayer({
    this.controlPointCount = 12,
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
    final baseRadius = math.min(size.width, size.height) * 0.28 * (0.8 + params.spatialScale * 0.4);

    final noise = engine.noise;
    final time = engine.topologyTime;

    final points = <Offset>[];
    for (var i = 0; i < controlPointCount; i++) {
      final angle = (i / controlPointCount) * math.pi * 2.0;

      final deform = noise.eval3D(
        math.cos(angle) * 1.5 + engine.seed.sessionSeed,
        math.sin(angle) * 1.5,
        time * 0.8,
      ) * baseRadius * 0.35 * params.flow;

      final radius = baseRadius + deform;
      points.add(Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      ));
    }

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(
        (points.last.dx + points.first.dx) / 2.0,
        (points.last.dy + points.first.dy) / 2.0,
      );

      for (var i = 0; i < points.length; i++) {
        final current = points[i];
        final next = points[(i + 1) % points.length];
        final midX = (current.dx + next.dx) / 2.0;
        final midY = (current.dy + next.dy) / 2.0;

        path.quadraticBezierTo(current.dx, current.dy, midX, midY);
      }
      path.close();
    }

    // Soft fill and subtle outline
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = palette.secondary.withValues(alpha: 0.08 * params.brightness)
      ..isAntiAlias = true;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = palette.primary.withValues(alpha: 0.2 * params.brightness)
      ..isAntiAlias = true;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }
}
