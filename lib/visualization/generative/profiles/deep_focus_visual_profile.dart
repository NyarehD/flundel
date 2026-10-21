import 'package:flundel/visualization/generative/engine/visual_engine.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/layers/background_layer.dart';
import 'package:flundel/visualization/generative/layers/flow_line_layer.dart';
import 'package:flundel/visualization/generative/layers/orbital_layer.dart';
import 'package:flundel/visualization/generative/layers/particle_layer.dart';
import 'package:flundel/visualization/generative/layers/visual_layer.dart';
import 'package:flundel/visualization/generative/profiles/visual_profile.dart';

/// Deep Focus Profile featuring long curved paths, arcs, and subtle central orientation.
class DeepFocusVisualProfile extends VisualProfile {
  const DeepFocusVisualProfile();

  @override
  String get id => 'deep_focus';

  @override
  String get name => 'Deep Focus';

  @override
  VisualParameters get baseParameters => VisualParameters.deepFocus;

  @override
  ColorPalette get palette => ColorPalette.deepFocus;

  @override
  List<VisualLayer> getLayers(GenerativeVisualQuality quality) {
    return const [
      BackgroundLayer(),
      OrbitalLayer(),
      FlowLineLayer(),
      ParticleLayer(),
    ];
  }
}
