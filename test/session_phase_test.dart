import 'package:flundel/session/session_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionPhase Calculations', () {
    test('Calculates timed session phases correctly', () {
      const totalSeconds = 1000;

      expect(
        SessionPhaseX.calculatePhase(
          elapsedSeconds: 50,
          totalDurationSeconds: totalSeconds,
        ),
        SessionPhase.settling,
      );

      expect(
        SessionPhaseX.calculatePhase(
          elapsedSeconds: 150,
          totalDurationSeconds: totalSeconds,
        ),
        SessionPhase.enteringFocus,
      );

      expect(
        SessionPhaseX.calculatePhase(
          elapsedSeconds: 500,
          totalDurationSeconds: totalSeconds,
        ),
        SessionPhase.deepFocus,
      );

      expect(
        SessionPhaseX.calculatePhase(
          elapsedSeconds: 850,
          totalDurationSeconds: totalSeconds,
        ),
        SessionPhase.windDown,
      );

      expect(
        SessionPhaseX.calculatePhase(
          elapsedSeconds: 1000,
          totalDurationSeconds: totalSeconds,
        ),
        SessionPhase.completion,
      );
    });

    test('Calculates endless session phases correctly', () {
      expect(
        SessionPhaseX.calculatePhase(
          elapsedSeconds: 30,
          totalDurationSeconds: null,
        ),
        SessionPhase.settling,
      );

      expect(
        SessionPhaseX.calculatePhase(
          elapsedSeconds: 120,
          totalDurationSeconds: null,
        ),
        SessionPhase.enteringFocus,
      );

      expect(
        SessionPhaseX.calculatePhase(
          elapsedSeconds: 600,
          totalDurationSeconds: null,
        ),
        SessionPhase.deepFocus,
      );
    });
  });
}
