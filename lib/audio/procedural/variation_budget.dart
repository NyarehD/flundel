/// Controls simultaneous macro variation transitions to prevent audio distraction.
class VariationBudget {

  VariationBudget({this.maxSimultaneousTransitions = 2});
  final int maxSimultaneousTransitions;
  final Set<String> _activeTransitions = {};

  int get activeCount => _activeTransitions.length;

  /// Attempts to acquire budget for a major procedural transition.
  bool requestTransition(String transitionId) {
    if (_activeTransitions.contains(transitionId)) return true;
    if (_activeTransitions.length < maxSimultaneousTransitions) {
      _activeTransitions.add(transitionId);
      return true;
    }
    return false;
  }

  /// Releases budget after transition stabilizes.
  void releaseTransition(String transitionId) {
    _activeTransitions.remove(transitionId);
  }

  void reset() {
    _activeTransitions.clear();
  }
}
