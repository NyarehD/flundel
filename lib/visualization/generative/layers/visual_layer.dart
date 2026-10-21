import 'package:flutter/material.dart';
import 'package:flundel/visualization/generative/engine/visual_engine.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/profiles/visual_profile.dart';

/// Abstract base interface for all generative visual rendering layers.
abstract class VisualLayer {
  const VisualLayer();

  void paint(
    Canvas canvas,
    Size size,
    VisualEngine engine,
    VisualParameters params,
    ColorPalette palette,
  );
}
