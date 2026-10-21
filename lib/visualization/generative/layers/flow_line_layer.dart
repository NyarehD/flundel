import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flundel/visualization/generative/engine/visual_engine.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/fields/flow_field.dart';
import 'package:flundel/visualization/generative/fields/wave_field.dart';
import 'package:flundel/visualization/generative/layers/visual_layer.dart';
import 'package:flundel/visualization/generative/profiles/visual_profile.dart';

/// Flowing Lines Layer generating smooth procedural Bézier curves moving
/// through a 2D vector field with smooth birth/death lifecycles.
class FlowLineLayer extends VisualLayer {
  final FlowField flowField;
  final WaveField waveField;

  const FlowLineLayer({
    this.flowField = const FlowField(),
    this.waveField = const WaveField(),
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

    final lineCount = switch (engine.quality) {
      GenerativeVisualQuality.low => (20 * params.density).round().clamp(10, 30),
      GenerativeVisualQuality.medium => (40 * params.density).round().clamp(20, 50),
      GenerativeVisualQuality.high => (60 * params.density).round().clamp(30, 70),
    };

    final noise = engine.noise;
    final time = engine.flowTime;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 + params.complexity * 0.4
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (var i = 0; i < lineCount; i++) {
      // Deterministic line seed
      final lineSeed = i * 13 + engine.seed.patternSeed;
      final seedX = ((lineSeed * 17) % 1000) / 1000.0;
      final seedY = ((lineSeed * 31) % 1000) / 1000.0;

      // Lifespan calculation (20-60s)
      final cycleDuration = 25.0 + (i % 5) * 7.0;
      final cycleTime = (engine.elapsedTime + i * 3.7) % cycleDuration;
      final cycleProgress = cycleTime / cycleDuration; // 0.0 -> 1.0

      // Smooth opacity envelope (sine curve fade in / fade out)
      final opacityEnvelope = math.sin(cycleProgress * math.pi);
      final alpha = (opacityEnvelope * 0.35 * params.brightness).clamp(0.0, 0.4);

      if (alpha <= 0.01) continue;

      // Starting point on canvas
      final startX = seedX * size.width;
      final startY = seedY * size.height;

      final path = Path();
      path.moveTo(startX, startY);

      var currX = startX;
      var currY = startY;

      const steps = 12;
      final stepLength = 15.0 + params.flow * 25.0;

      for (var step = 0; step < steps; step++) {
        final vec = flowField.getVector(currX, currY, time, noise, params);
        final waveDisp = waveField.evaluate(currX, currY, time, noise, params) * 12.0;

        final nextX = currX + vec.dx * stepLength;
        final nextY = currY + vec.dy * stepLength + waveDisp;

        // Draw smooth quadratic curve segment
        final controlX = (currX + nextX) / 2.0 + vec.dy * waveDisp * 0.5;
        final controlY = (currY + nextY) / 2.0 - vec.dx * waveDisp * 0.5;

        path.quadraticBezierTo(controlX, controlY, nextX, nextY);

        currX = nextX;
        currY = nextY;
      }

      final lineColor = Color.lerp(
        palette.primary,
        palette.secondary,
        (i % 3) / 2.0,
      )!;

      paint.color = lineColor.withValues(alpha: alpha);
      canvas.drawPath(path, paint);
    }
  }
}
