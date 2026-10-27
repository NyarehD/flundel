import 'dart:math' as math;

import 'package:flundel/visualization/generative/engine/visual_engine.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/layers/visual_layer.dart';
import 'package:flundel/visualization/generative/profiles/visual_profile.dart';
import 'package:flutter/material.dart';

/// Sparse particle layer with noise-driven slow drift and rare distance connections.
class ParticleLayer extends VisualLayer {

  const ParticleLayer({
    this.maxParticles = 60,
  });
  final int maxParticles;

  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualEngine engine,
    VisualParameters params,
    ColorPalette palette,
  ) {
    if (size.isEmpty) return;

    final particleCount = switch (engine.quality) {
      GenerativeVisualQuality.low => (15 * params.density).round().clamp(8, 25),
      GenerativeVisualQuality.medium => (30 * params.density).round().clamp(15, 45),
      GenerativeVisualQuality.high => (50 * params.density).round().clamp(25, maxParticles),
    };

    final noise = engine.noise;
    final time = engine.particleTime;

    final positions = <Offset>[];
    final fillPaint = Paint()..style = PaintingStyle.fill..isAntiAlias = true;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..isAntiAlias = true;

    for (var i = 0; i < particleCount; i++) {
      final pSeed = i * 29 + engine.seed.sessionSeed;
      final baseX = ((pSeed * 13) % 1000) / 1000.0 * size.width;
      final baseY = ((pSeed * 47) % 1000) / 1000.0 * size.height;

      final driftX = noise.eval3D(baseX * 0.002, baseY * 0.002, time) * 60.0;
      final driftY = noise.eval3D(baseX * 0.002 + 50.0, baseY * 0.002 + 50.0, time) * 60.0;

      final px = (baseX + driftX) % size.width;
      final py = (baseY + driftY) % size.height;
      final pos = Offset(px, py);
      positions.add(pos);

      final radius = 1.0 + (i % 3) * 0.5 + params.complexity * 0.5;
      final pAlpha = (0.2 + (i % 4) * 0.05) * params.brightness;

      fillPaint.color = palette.highlight.withValues(alpha: pAlpha.clamp(0.0, 0.4));
      canvas.drawCircle(pos, radius, fillPaint);
    }

    // Rare implied connections between nearby particles
    const connectionDistSq = 65.0 * 65.0;
    for (var i = 0; i < positions.length; i++) {
      for (var j = i + 1; j < positions.length; j++) {
        final dx = positions[i].dx - positions[j].dx;
        final dy = positions[i].dy - positions[j].dy;
        final distSq = dx * dx + dy * dy;

        if (distSq < connectionDistSq) {
          final dist = math.sqrt(distSq);
          final connAlpha = ((1.0 - dist / 65.0) * 0.12 * params.brightness).clamp(0.0, 0.2);
          linePaint.color = palette.accent.withValues(alpha: connAlpha);
          canvas.drawLine(positions[i], positions[j], linePaint);
        }
      }
    }
  }
}
