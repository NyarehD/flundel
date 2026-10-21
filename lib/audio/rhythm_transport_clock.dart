/// Phase-preserving transport anchor for native scheduled rhythm loops.
///
/// Audio playback is scheduled by SoLoud; this clock only maps the native
/// engine timestamp to a loop phase for seek-aligned bass chord changes and
/// pause/resume. It never schedules individual hits.
class RhythmTransportClock {
  Duration _loopDuration = Duration.zero;
  Duration _origin = Duration.zero;
  Duration _originPhase = Duration.zero;

  Duration get loopDuration => _loopDuration;

  void reset(Duration loopDuration) {
    _loopDuration = loopDuration;
    _origin = Duration.zero;
    _originPhase = Duration.zero;
  }

  void anchor(Duration engineTime, {Duration phase = Duration.zero}) {
    if (_loopDuration == Duration.zero) {
      _origin = engineTime;
      _originPhase = Duration.zero;
      return;
    }
    _origin = engineTime;
    _originPhase = _wrap(phase);
  }

  Duration phaseAt(Duration engineTime) {
    if (_loopDuration == Duration.zero || engineTime < _origin) {
      return _originPhase;
    }
    return _wrap(
      Duration(
        microseconds:
            _originPhase.inMicroseconds + (engineTime - _origin).inMicroseconds,
      ),
    );
  }

  Duration _wrap(Duration phase) => Duration(
    microseconds: phase.inMicroseconds % _loopDuration.inMicroseconds,
  );
}
