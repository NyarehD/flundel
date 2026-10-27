import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract interface class VisualizationSignals {
  double get elapsedSeconds;
  double get motionSeconds;
  double get amplitude;
  double get tonal;
  double get texture;
  double get piano;
  double get pianoPulse;
  double get focus;
  double get detail;
}

/// Repeating monochrome fields with a distinct rhythm for each preset.
class SoundscapePainter extends CustomPainter {

  SoundscapePainter({
    required this.presetId,
    required this.signals,
    required Listenable repaint,
  }) : _geometry = _PatternGeometry.forPreset(presetId),
       super(repaint: repaint);
  final String presetId;
  final VisualizationSignals signals;
  final _PatternGeometry _geometry;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFF050505), BlendMode.src);
    if (size.isEmpty) return;

    final time = signals.elapsedSeconds;
    final ambientTime = signals.motionSeconds;
    final amplitude = signals.amplitude;
    final tonal = signals.tonal;
    final texture = signals.texture;
    final piano = signals.piano;
    final pulse = signals.pianoPulse;
    final strength = (0.78 + signals.focus * 0.16 + amplitude * 0.06).clamp(
      0.0,
      1.0,
    );

    switch (presetId) {
      case 'deep_work':
        _drawMoireLattice(
          canvas,
          size,
          time,
          amplitude,
          tonal,
          texture,
          pulse,
          strength,
        );
      case 'coding':
        _drawInterferenceStripes(
          canvas,
          size,
          time,
          amplitude,
          tonal,
          texture,
          pulse,
          strength,
        );
      case 'reading':
        _drawDiamondTiles(
          canvas,
          size,
          time,
          amplitude,
          tonal,
          texture,
          pulse,
          strength,
        );
      case 'quiet_focus':
        _drawTravelingBands(
          canvas,
          size,
          time,
          amplitude,
          tonal,
          texture,
          pulse,
          strength,
        );
      case 'piano_focus':
        _drawPianoRadial(
          canvas,
          size,
          time,
          amplitude,
          tonal,
          piano,
          pulse,
          strength,
        );
      case 'night_focus':
        _drawNightRadial(
          canvas,
          size,
          time,
          ambientTime,
          texture,
          pulse,
          signals.detail,
          strength,
        );
      case 'ocean_drift':
        _drawTravelingBands(
          canvas,
          size,
          time,
          amplitude,
          tonal,
          texture,
          pulse,
          strength,
        );
      case 'zen_meditation':
        _drawDiamondTiles(
          canvas,
          size,
          time,
          amplitude,
          tonal,
          texture,
          pulse,
          strength,
        );
      case 'lofi_study':
        _drawInterferenceStripes(
          canvas,
          size,
          time,
          amplitude,
          tonal,
          texture,
          pulse,
          strength,
        );
      case 'forest_stream':
        _drawMoireLattice(
          canvas,
          size,
          time,
          amplitude,
          tonal,
          texture,
          pulse,
          strength,
        );
      default:
        _drawMoireLattice(
          canvas,
          size,
          time,
          amplitude,
          tonal,
          texture,
          pulse,
          strength,
        );
    }
  }

  void _drawMoireLattice(
    Canvas canvas,
    Size size,
    double time,
    double amplitude,
    double tonal,
    double texture,
    double pulse,
    double strength,
  ) {
    final spacing = 25 + (1 - amplitude) * 8;
    final travel = time * 4.8;
    _drawGrid(
      canvas,
      size,
      spacing: spacing,
      angle: 0.035 + _geometry.phase * 0.05 + math.sin(time * 0.18) * 0.008,
      offset: travel + _geometry.phase * 2.0,
      alpha: 0.28 * strength,
      width: 0.75,
    );
    _drawGrid(
      canvas,
      size,
      spacing: spacing * (0.95 - texture * 0.045),
      angle: 0.075 + _geometry.phase * 0.05 + tonal * 0.045 + math.sin(time * 0.22 + 1) * 0.012,
      offset: -travel * 0.7 + pulse * spacing * 0.35,
      alpha: (0.19 + texture * 0.07) * strength,
      width: 0.65,
    );
  }

  void _drawInterferenceStripes(
    Canvas canvas,
    Size size,
    double time,
    double amplitude,
    double tonal,
    double texture,
    double pulse,
    double strength,
  ) {
    final spacing = 19 + (1 - texture) * 8 - amplitude * 3;
    final travel = time * 6;
    _drawStripes(
      canvas,
      size,
      spacing: spacing,
      angle: 0.68 + _geometry.phase * 0.05 + tonal * 0.08,
      offset: travel + _geometry.phase * 2.0,
      alpha: 0.3 * strength,
      width: 0.8,
    );
    _drawStripes(
      canvas,
      size,
      spacing: spacing * 1.04,
      angle: -0.68 + tonal * 0.08 + math.sin(time * 0.24) * 0.012,
      offset: -travel * 0.72 + pulse * spacing * 0.35,
      alpha: (0.21 + texture * 0.06) * strength,
      width: 0.7,
    );
  }

  void _drawDiamondTiles(
    Canvas canvas,
    Size size,
    double time,
    double amplitude,
    double tonal,
    double texture,
    double pulse,
    double strength,
  ) {
    final spacing = 37 + (1 - amplitude) * 8;
    final half = spacing * (0.42 + pulse * 0.025);
    final travel = time * 3.4;
    final phase = _geometry.phase + tonal * 0.12;
    // The field rotates around the viewport center. Cover its diagonal square
    // so the corners remain tiled at every phase and in either orientation.
    final diagonal = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final firstRow = ((size.height - diagonal) / (2 * spacing)).floor() - 1;
    final lastRow = ((size.height + diagonal) / (2 * spacing)).ceil() + 1;
    final firstColumn = ((size.width - diagonal) / (2 * spacing)).floor() - 1;
    final lastColumn = ((size.width + diagonal) / (2 * spacing)).ceil() + 1;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(math.pi / 4 + phase * 0.025);
    canvas.translate(-size.width / 2, -size.height / 2);
    for (var row = firstRow; row <= lastRow; row++) {
      final y = row * spacing + (travel % spacing);
      final rowOffset = row.isEven ? 0.0 : spacing * 0.5;
      for (var column = firstColumn; column <= lastColumn; column++) {
        final x = column * spacing + rowOffset - (travel * 0.62 % spacing);
        final tilePhase = (row + column) * 0.13 + time * 0.28;
        final tileHalf = half * (1 + math.sin(tilePhase) * 0.025);
        final path = Path()
          ..moveTo(x, y - tileHalf)
          ..lineTo(x + tileHalf, y)
          ..lineTo(x, y + tileHalf)
          ..lineTo(x - tileHalf, y)
          ..close();
        canvas.drawPath(
          path,
          _stroke((0.25 + texture * 0.035) * strength, 0.75),
        );
      }
    }
    canvas.restore();

    _drawStripes(
      canvas,
      size,
      spacing: spacing * 2,
      angle: -math.pi / 4,
      offset: travel * 0.45,
      alpha: (0.12 + texture * 0.06) * strength,
      width: 0.55,
    );
  }

  void _drawTravelingBands(
    Canvas canvas,
    Size size,
    double time,
    double amplitude,
    double tonal,
    double texture,
    double pulse,
    double strength,
  ) {
    final spacing = 34 + (1 - amplitude) * 7;
    final waveHeight =
        size.height * (0.009 + amplitude * 0.013 + pulse * 0.004);
    final lines = (size.height / spacing).ceil() + 2;
    final travel = time * 0.95 + texture * 0.28 + _geometry.phase * 0.15;
    for (var line = -1; line <= lines; line++) {
      final path = Path();
      final baseY =
          line * spacing + (travel * spacing / (math.pi * 2)) % spacing;
      for (var step = 0; step <= 64; step++) {
        final across = step / 64;
        final x = across * size.width;
        final phase = across * math.pi * 2.2 + travel + line * 0.22;
        final y =
            baseY +
            math.sin(phase) * waveHeight +
            math.sin(phase * 0.52 - time * 0.36 + tonal) * waveHeight * 0.24;
        if (step == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        _stroke((0.31 - (line % 3).abs() * 0.018) * strength, 0.9),
      );
    }
  }

  void _drawPianoRadial(
    Canvas canvas,
    Size size,
    double time,
    double amplitude,
    double tonal,
    double piano,
    double pulse,
    double strength,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) * 0.54;
    final spacing = 20 + (1 - amplitude) * 5 + piano * 2;
    final rings = (maxRadius / spacing).ceil();
    final phase = _geometry.phase + tonal * 0.18;
    final rippleTravel = pulse * spacing * 2.4;

    for (var ring = 1; ring <= rings; ring++) {
      final radius =
          ring * spacing +
          rippleTravel +
          math.sin(time * 0.62 - ring * 0.24) * 1.2;
      if (radius <= maxRadius) {
        canvas.drawCircle(
          center,
          radius,
          _stroke((0.29 - (ring % 4) * 0.018 + pulse * 0.025) * strength, 0.8),
        );
      }
    }

    const spokes = 20;
    final rotation = phase + time * 0.055;
    for (var spoke = 0; spoke < spokes; spoke++) {
      final angle = rotation + spoke * math.pi * 2 / spokes;
      final startRadius = maxRadius * (spoke.isEven ? 0.08 : 0.15);
      final endRadius =
          maxRadius * (0.82 + (spoke % 3) * 0.05) + rippleTravel * 0.2;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * startRadius,
        center + Offset(math.cos(angle), math.sin(angle)) * endRadius,
        _stroke(0.17 * strength, 0.65),
      );
    }
  }

  void _drawNightRadial(
    Canvas canvas,
    Size size,
    double time,
    double ambientTime,
    double texture,
    double pulse,
    double detail,
    double strength,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) * 0.5;
    final angleCount = 12 + (detail * 6).round();
    final rotation = time * 0.075 + ambientTime * 0.012 + _geometry.phase;
    for (var index = 0; index < angleCount; index++) {
      final angle = rotation + index * math.pi * 2 / angleCount;
      final rayEnd = maxRadius * (0.68 + (index % 3) * 0.08);
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * maxRadius * 0.14,
        center + Offset(math.cos(angle), math.sin(angle)) * rayEnd,
        _stroke((0.2 + texture * 0.035) * strength, 0.7),
      );
    }

    const orbitCount = 3;
    const pointsPerOrbit = 8;
    for (var orbit = 0; orbit < orbitCount; orbit++) {
      final radius = maxRadius * (0.28 + orbit * 0.17) + pulse * 9;
      final rotationOffset = orbit * 0.16;
      for (var point = 0; point < pointsPerOrbit; point++) {
        final angle =
            rotation + rotationOffset + point * math.pi * 2 / pointsPerOrbit;
        final position =
            center + Offset(math.cos(angle), math.sin(angle)) * radius;
        final markerSize = orbit == 1 ? 2.0 : 1.5;
        canvas.drawRect(
          Rect.fromCenter(
            center: position,
            width: markerSize,
            height: markerSize,
          ),
          _fill((0.3 + texture * 0.03) * strength),
        );
      }
    }

    final outerSpacing = 24 + (1 - detail) * 8;
    _drawStripes(
      canvas,
      size,
      spacing: outerSpacing,
      angle: math.pi / 2,
      offset: (time * 2) % outerSpacing,
      alpha: 0.1 * strength,
      width: 0.5,
    );
  }

  void _drawGrid(
    Canvas canvas,
    Size size, {
    required double spacing,
    required double angle,
    required double offset,
    required double alpha,
    required double width,
  }) {
    final extent = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final half = extent / 2;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);
    final shift = offset % spacing;
    for (var x = -half + shift; x <= half; x += spacing) {
      canvas.drawLine(Offset(x, -half), Offset(x, half), _stroke(alpha, width));
    }
    for (var y = -half + shift; y <= half; y += spacing) {
      canvas.drawLine(Offset(-half, y), Offset(half, y), _stroke(alpha, width));
    }
    canvas.restore();
  }

  void _drawStripes(
    Canvas canvas,
    Size size, {
    required double spacing,
    required double angle,
    required double offset,
    required double alpha,
    required double width,
  }) {
    final extent = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final half = extent / 2;
    final shift = offset % spacing;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);
    for (var y = -half + shift; y <= half; y += spacing) {
      canvas.drawLine(Offset(-half, y), Offset(half, y), _stroke(alpha, width));
    }
    canvas.restore();
  }

  Paint _stroke(double alpha, double width) => Paint()
    ..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 0.4))
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  Paint _fill(double alpha) => Paint()
    ..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 0.4))
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  @override
  bool shouldRepaint(covariant SoundscapePainter oldDelegate) =>
      oldDelegate.presetId != presetId || oldDelegate.signals != signals;
}

class _PatternGeometry {

  const _PatternGeometry._(this.phase);

  factory _PatternGeometry.forPreset(String presetId) => _cache.putIfAbsent(
    presetId,
    () => _PatternGeometry._(switch (presetId) {
      'deep_work' => 0.12,
      'coding' => 0.38,
      'reading' => 0.64,
      'quiet_focus' => 0.9,
      'piano_focus' => 1.16,
      'night_focus' => 1.42,
      'ocean_drift' => 1.68,
      'zen_meditation' => 1.94,
      'lofi_study' => 2.20,
      'forest_stream' => 2.46,
      _ => 0.12,
    }),
  );
  static final Map<String, _PatternGeometry> _cache = {};
  final double phase;
}
