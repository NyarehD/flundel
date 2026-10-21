import 'package:flundel/visualization/generative/engine/visual_engine.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/layers/background_layer.dart';
import 'package:flundel/visualization/generative/layers/blob_layer.dart';
import 'package:flundel/visualization/generative/layers/contour_layer.dart';
import 'package:flundel/visualization/generative/layers/particle_layer.dart';
import 'package:flundel/visualization/generative/layers/visual_layer.dart';
import 'package:flundel/visualization/generative/profiles/visual_profile.dart';

/// Relax Profile combining large soft breathing blobs, wide contours, and slow particles.
class RelaxVisualProfile extends VisualProfile {
  const RelaxVisualProfile();

  @override
  String get id => 'relax';

  @override
  String get name => 'Relax';

  @override
  VisualParameters get baseParameters => VisualParameters.relax;

  @override
  ColorPalette get palette => ColorPalette.relax;

  @override
  List<VisualLayer> getLayers(GenerativeVisualQuality quality) {
    return const [
      BackgroundLayer(),
      BlobLayer(),
      ContourLayer(),
      ParticleLayer(),
    ];
  }
}
