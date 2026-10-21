import 'dart:async';

/// Schedules short phrase notes and cancels all outstanding notes together.
class PianoPhraseScheduler {
  final List<Timer> _timers = [];
  int _generation = 0;

  void schedule({
    required List<double> frequencies,
    required Duration spacing,
    required void Function(double frequency, int index) onNote,
  }) {
    cancel();
    final generation = ++_generation;
    for (var index = 0; index < frequencies.length; index++) {
      final frequency = frequencies[index];
      _timers.add(
        Timer(spacing * index, () {
          if (generation == _generation) onNote(frequency, index);
        }),
      );
    }
  }

  void cancel() {
    ++_generation;
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }
}
