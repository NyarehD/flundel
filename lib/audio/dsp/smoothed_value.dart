import 'dart:math';

/// A parameter smoother that interpolates values over time at control-rate.
///
/// Prevents audible clicks and pops caused by instant parameter jumps.
class SmoothedValue {
  double _current;
  double _target;
  double _smoothingDuration; // in seconds
  double _elapsed = 0.0;
  double _startValue;

  SmoothedValue(
    double initialValue, {
    double smoothingDurationSeconds = 0.15, // default 150ms
  })  : _current = initialValue,
        _target = initialValue,
        _startValue = initialValue,
        _smoothingDuration = max(0.001, smoothingDurationSeconds);

  double get value => _current;
  double get target => _target;
  bool get isComplete => _current == _target;

  /// Sets target value to smoothly interpolate towards.
  void setTarget(double newTarget, {double? durationSeconds}) {
    if (durationSeconds != null) {
      _smoothingDuration = max(0.001, durationSeconds);
    }
    if ((newTarget - _target).abs() < 1e-6) return;

    _startValue = _current;
    _target = newTarget;
    _elapsed = 0.0;
  }

  /// Instantly jump to a value (use only during initialization or silence).
  void setImmediate(double newValue) {
    _current = newValue;
    _target = newValue;
    _startValue = newValue;
    _elapsed = _smoothingDuration;
  }

  /// Advance time by [deltaTimeSeconds] and return updated smoothed value.
  double tick(double deltaTimeSeconds) {
    if (_current == _target) return _current;

    _elapsed += deltaTimeSeconds;
    final progress = (_elapsed / _smoothingDuration).clamp(0.0, 1.0);

    // Smoothstep interpolation (S-curve) for ultra-smooth parameter changes
    final smoothFactor = progress * progress * (3 - 2 * progress);
    _current = _startValue + (_target - _startValue) * smoothFactor;

    if (progress >= 1.0) {
      _current = _target;
    }

    return _current;
  }
}
