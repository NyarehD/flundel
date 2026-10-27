import 'dart:math';

import 'package:flundel/audio/dsp/smoothed_value.dart';

class AudioBus {
  final SmoothedValue masterVolume = SmoothedValue(
    0.9,
    smoothingDurationSeconds: 0.1,
  );
  final SmoothedValue tonalBusGain = SmoothedValue(
    0.8,
  );
  final SmoothedValue textureBusGain = SmoothedValue(
    0.7,
  );
  final SmoothedValue reverbBusSend = SmoothedValue(
    0.3,
    smoothingDurationSeconds: 0.2,
  );

  static const double masterLimiterCeiling = 0.89; // -1 dBFS
  static const double preMasterPeakTarget = 0.50; // -6 dBFS

  /// Process gain staging & soft master limiter on input signal amplitude.
  double applyMasterLimiter(double rawPeakAmplitude) {
    // Apply master volume
    final scaled = rawPeakAmplitude * masterVolume.value;

    // Soft knee limiter
    if (scaled <= preMasterPeakTarget) {
      return scaled;
    }

    // Compress values above -6 dBFS smoothly towards ceiling
    final over = scaled - preMasterPeakTarget;
    final compressed = preMasterPeakTarget + (over / (1.0 + over * 2.0));
    return min(masterLimiterCeiling, compressed);
  }

  /// Calculates effective gain for a layer given solo / mute states.
  double calculateEffectiveGain({
    required double baseLevel,
    required bool isMuted,
    required bool isSolo,
    required bool anyLayerSolo,
    required double busGain,
  }) {
    if (isMuted) return 0.0;
    if (anyLayerSolo && !isSolo) return 0.0;

    return (baseLevel * busGain * masterVolume.value).clamp(0.0, 1.0);
  }
}
