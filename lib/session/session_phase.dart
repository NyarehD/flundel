enum SessionPhase { settling, enteringFocus, deepFocus, windDown, completion }

extension SessionPhaseX on SessionPhase {
  String get labelKey {
    switch (this) {
      case SessionPhase.settling:
        return 'session.phase_settling';
      case SessionPhase.enteringFocus:
        return 'session.phase_entering';
      case SessionPhase.deepFocus:
        return 'session.phase_deep';
      case SessionPhase.windDown:
        return 'session.phase_wind_down';
      case SessionPhase.completion:
        return 'session.phase_completion';
    }
  }

  static SessionPhase calculatePhase({
    required int elapsedSeconds,
    required int? totalDurationSeconds,
  }) {
    if (totalDurationSeconds == null || totalDurationSeconds <= 0) {
      // Endless session logic
      if (elapsedSeconds < 60) return SessionPhase.settling;
      if (elapsedSeconds < 300) return SessionPhase.enteringFocus;
      return SessionPhase.deepFocus;
    }

    final progress = (elapsedSeconds / totalDurationSeconds).clamp(0.0, 1.0);
    if (progress >= 1.0) return SessionPhase.completion;
    if (progress >= 0.80) return SessionPhase.windDown;
    if (progress >= 0.30) return SessionPhase.deepFocus;
    if (progress >= 0.10) return SessionPhase.enteringFocus;
    return SessionPhase.settling;
  }
}
