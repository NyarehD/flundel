import 'package:flutter/material.dart';
import 'package:flundel/visualization/generative/engine/visual_engine.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/profiles/visual_profile.dart';

/// Multi-layer composite painter executing visual layers in depth order.
class GenerativeVisualPainter extends CustomPainter {
  final VisualProfile profile;
  final VisualEngine engine;
  final VisualParameters params;
  final ColorPalette palette;

  GenerativeVisualPainter({
    required this.profile,
    required this.engine,
    required this.params,
    required this.palette,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final layers = profile.getLayers(engine.quality);
    for (final layer in layers) {
      layer.paint(canvas, size, engine, params, palette);
    }
  }

  @override
  bool shouldRepaint(covariant GenerativeVisualPainter oldDelegate) {
    return oldDelegate.profile != profile ||
        oldDelegate.engine != engine ||
        oldDelegate.params != params ||
        oldDelegate.palette != palette;
  }
}
