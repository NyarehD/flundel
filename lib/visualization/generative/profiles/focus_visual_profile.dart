import 'package:flundel/visualization/generative/engine/visual_engine.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/layers/background_layer.dart';
import 'package:flundel/visualization/generative/layers/flow_line_layer.dart';
import 'package:flundel/visualization/generative/layers/grid_layer.dart';
import 'package:flundel/visualization/generative/layers/particle_layer.dart';
import 'package:flundel/visualization/generative/layers/visual_layer.dart';
import 'package:flundel/visualization/generative/profiles/visual_profile.dart';

/// Focus Profile combining flowing curves, subtle deformed grid, and sparse particles.
class FocusVisualProfile extends VisualProfile {
  const FocusVisualProfile();

  @override
  String get id => 'focus';

  @override
  String get name => 'Focus';

  @override
  VisualParameters get baseParameters => VisualParameters.focus;

  @override
  ColorPalette get palette => ColorPalette.focus;

  @override
  List<VisualLayer> getLayers(GenerativeVisualQuality quality) {
    return const [
      BackgroundLayer(),
      GridLayer(),
      FlowLineLayer(),
      ParticleLayer(),
    ];
  }
}
