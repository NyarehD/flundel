import 'package:flundel/visualization/generative/engine/visual_engine.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/layers/background_layer.dart';
import 'package:flundel/visualization/generative/layers/contour_layer.dart';
import 'package:flundel/visualization/generative/layers/particle_layer.dart';
import 'package:flundel/visualization/generative/layers/visual_layer.dart';
import 'package:flundel/visualization/generative/profiles/visual_profile.dart';

/// Sleep Profile featuring restrained low-contrast slow fields and minimal particles.
class SleepVisualProfile extends VisualProfile {
  const SleepVisualProfile();

  @override
  String get id => 'sleep';

  @override
  String get name => 'Sleep';

  @override
  VisualParameters get baseParameters => VisualParameters.sleep;

  @override
  ColorPalette get palette => ColorPalette.sleep;

  @override
  List<VisualLayer> getLayers(GenerativeVisualQuality quality) {
    return const [
      BackgroundLayer(),
      ContourLayer(contourCount: 4),
      ParticleLayer(maxParticles: 15),
    ];
  }
}
