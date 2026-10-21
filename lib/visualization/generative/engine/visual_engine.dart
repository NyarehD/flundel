import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flundel/visualization/generative/engine/noise.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/engine/visual_seed.dart';
import 'package:flundel/visualization/generative/engine/visual_state.dart';

enum GenerativeVisualQuality {
  low,
  medium,
  high,
}

/// Core engine managing multi-timescale clocks, noise evaluation,
/// parameter smoothing, and quality options.
class VisualEngine extends ChangeNotifier {
  GenerativeVisualSeed _seed;
  late GenerativeNoise _noise;
  VisualParameters _currentParameters;
  VisualParameters _targetParameters;
  AudioVisualState _audioState;
  GenerativeVisualQuality _quality;

  // Clocks for different timescales
  double _elapsedTime = 0.0;
  double _flowTime = 0.0;
  double _particleTime = 0.0;
  double _pulseTime = 0.0;
  double _topologyTime = 0.0;
  double _compositionTime = 0.0;

  VisualEngine({
    GenerativeVisualSeed? seed,
    VisualParameters initialParameters = VisualParameters.focus,
    this._quality = GenerativeVisualQuality.medium,
  })  : _seed = seed ?? const GenerativeVisualSeed(sessionSeed: 42, patternSeed: 101),
        _currentParameters = initialParameters,
        _targetParameters = initialParameters,
        _audioState = const AudioVisualState() {
    _noise = _seed.createNoise();
  }

  GenerativeVisualSeed get seed => _seed;
  GenerativeNoise get noise => _noise;
  VisualParameters get parameters => _currentParameters;
  VisualParameters get targetParameters => _targetParameters;
  AudioVisualState get audioState => _audioState;
  GenerativeVisualQuality get quality => _quality;

  double get elapsedTime => _elapsedTime;
  double get flowTime => _flowTime;
  double get particleTime => _particleTime;
  double get pulseTime => _pulseTime;
  double get topologyTime => _topologyTime;
  double get compositionTime => _compositionTime;

  void setSeed(GenerativeVisualSeed newSeed) {
    if (_seed == newSeed) return;
    _seed = newSeed;
    _noise = _seed.createNoise();
    notifyListeners();
  }

  void setQuality(GenerativeVisualQuality newQuality) {
    if (_quality == newQuality) return;
    _quality = newQuality;
    notifyListeners();
  }

  void setTargetParameters(VisualParameters target) {
    _targetParameters = target;
  }

  void updateAudioState(AudioVisualState newState) {
    _audioState = newState;
    _targetParameters = _audioState.applyToParameters(_targetParameters);
  }

  /// Advances the engine clock and updates parameter interpolation.
  void advance(double deltaSeconds, {bool reducedMotion = false}) {
    if (!deltaSeconds.isFinite || deltaSeconds <= 0) return;
    final dt = deltaSeconds.clamp(0.0, 0.1);

    if (!reducedMotion) {
      final speedFactor = 0.2 + _currentParameters.speed * 1.2;
      _elapsedTime += dt * speedFactor;
      _flowTime += dt * 0.08 * speedFactor;
      _particleTime += dt * 0.05 * speedFactor;
      _pulseTime += dt * 0.15 * speedFactor;
      _topologyTime += dt * 0.02 * speedFactor;
      _compositionTime += dt * 0.005 * speedFactor;
    } else {
      // Very slow background evolution when reducedMotion is enabled
      _elapsedTime += dt * 0.02;
      _topologyTime += dt * 0.002;
    }

    // Exponential smoothing toward target parameters
    final smoothing = 1.0 - math.exp(-dt * 2.0);
    _currentParameters = _currentParameters.lerp(_targetParameters, smoothing);

    notifyListeners();
  }
}
