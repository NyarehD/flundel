import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flundel/audio/audio_analysis.dart';

class SoundscapePainter extends CustomPainter {
  final double animationValue;
  final AudioAnalysis? analysis;
  final String visualPreset;

  SoundscapePainter({
    required this.animationValue,
    required this.analysis,
    required this.visualPreset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final amp = analysis?.amplitude ?? 0.3;
    final low = analysis?.lowEnergy ?? 0.3;
    final high = analysis?.highEnergy ?? 0.3;
    final center = Offset(size.width / 2, size.height / 2);

    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(const Color(0xFF1E2638), const Color(0xFF2A1F3D), low)!,
          const Color(0xFF0D0F12),
        ],
        radius: 0.8 + (amp * 0.3),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (visualPreset == 'waves_particles' || visualPreset == 'waves') {
      _drawWaves(canvas, size, amp, low);
    }

    if (visualPreset == 'blobs' || visualPreset == 'waves_particles') {
      _drawBlobs(canvas, center, amp, low);
    }

    if (visualPreset == 'geometric_particles' || visualPreset == 'waves_particles') {
      _drawParticles(canvas, size, amp, high);
    }

    if (visualPreset == 'starfield') {
      _drawStarfield(canvas, size, amp, high);
    }

    if (analysis?.hasPianoEvent == true) {
      _drawPianoPulse(canvas, center, size);
    }
  }

  void _drawWaves(Canvas canvas, Size size, double amp, double low) {
    final path = Path();
    final waveHeight = 20.0 + (amp * 40.0);
    path.moveTo(0, size.height * 0.6);

    for (double x = 0; x <= size.width; x += 10) {
      final y = size.height * 0.6 +
          sin((x / size.width * 2 * pi) + (animationValue * 2 * pi)) * waveHeight +
          cos((x / size.width * 4 * pi) + (animationValue * 3 * pi)) * (low * 15);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final wavePaint = Paint()
      ..color = const Color(0xFF7C8BA1).withValues(alpha: 0.15 + (amp * 0.1))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, wavePaint);
  }

  void _drawBlobs(Canvas canvas, Offset center, double amp, double low) {
    final blobRadius = 80.0 + (low * 60.0) + (amp * 30.0);
    final blobPaint = Paint()
      ..color = const Color(0xFF8892B0).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    canvas.drawCircle(
      Offset(
        center.dx + sin(animationValue * 2 * pi) * 30,
        center.dy + cos(animationValue * 2 * pi) * 20,
      ),
      blobRadius,
      blobPaint,
    );
  }

  void _drawParticles(Canvas canvas, Size size, double amp, double high) {
    final particlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2 + (high * 0.3))
      ..style = PaintingStyle.fill;

    final random = Random(42);
    for (int i = 0; i < 25; i++) {
      final x = (random.nextDouble() * size.width +
              sin((animationValue + i) * 2 * pi) * 20) %
          size.width;
      final y = (random.nextDouble() * size.height +
              cos((animationValue + i) * 2 * pi) * 20) %
          size.height;
      final radius = 1.5 + (random.nextDouble() * 2.0) + (amp * 1.5);

      canvas.drawCircle(Offset(x, y), radius, particlePaint);
    }
  }

  void _drawStarfield(Canvas canvas, Size size, double amp, double high) {
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.3 + (high * 0.4));
    final random = Random(101);
    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = (random.nextDouble() * 1.5) + (amp * 1.0);
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  void _drawPianoPulse(Canvas canvas, Offset center, Size size) {
    final pulsePaint = Paint()
      ..color = const Color(0xFFD8DEE9).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, size.width * 0.35, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant SoundscapePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.analysis != analysis;
  }
}
