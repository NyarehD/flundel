import 'package:flutter/material.dart';
import 'package:flundel/visualization/generative/engine/visual_engine.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/layers/visual_layer.dart';

/// Palette defining background, primary, secondary, highlight, and accent colors.
class ColorPalette {
  final Color background;
  final Color primary;
  final Color secondary;
  final Color highlight;
  final Color accent;

  const ColorPalette({
    required this.background,
    required this.primary,
    required this.secondary,
    required this.highlight,
    required this.accent,
  });

  static const focus = ColorPalette(
    background: Color(0xFF04060A),
    primary: Color(0xFF88AACC),
    secondary: Color(0xFF446688),
    highlight: Color(0xFFCCDDEE),
    accent: Color(0xFF5588BB),
  );

  static const deepFocus = ColorPalette(
    background: Color(0xFF020408),
    primary: Color(0xFF5577AA),
    secondary: Color(0xFF224466),
    highlight: Color(0xFFAABBCC),
    accent: Color(0xFF336699),
  );

  static const relax = ColorPalette(
    background: Color(0xFF080608),
    primary: Color(0xFFCC99AA),
    secondary: Color(0xFF774455),
    highlight: Color(0xFFEEDD88),
    accent: Color(0xFFAA6688),
  );

  static const sleep = ColorPalette(
    background: Color(0xFF030204),
    primary: Color(0xFF554466),
    secondary: Color(0xFF221133),
    highlight: Color(0xFF887799),
    accent: Color(0xFF443355),
  );

  ColorPalette lerp(ColorPalette target, double t) {
    final factor = t.clamp(0.0, 1.0);
    return ColorPalette(
      background: Color.lerp(background, target.background, factor)!,
      primary: Color.lerp(primary, target.primary, factor)!,
      secondary: Color.lerp(secondary, target.secondary, factor)!,
      highlight: Color.lerp(highlight, target.highlight, factor)!,
      accent: Color.lerp(accent, target.accent, factor)!,
    );
  }
}

/// Abstract profile defining specific layer stacks, palettes, and baseline parameters.
abstract class VisualProfile {
  const VisualProfile();

  String get id;
  String get name;
  VisualParameters get baseParameters;
  ColorPalette get palette;
  List<VisualLayer> getLayers(GenerativeVisualQuality quality);
}
