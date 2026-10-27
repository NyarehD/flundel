import 'dart:async';

/// Orders transport and configuration operations without poisoning later work
/// after one operation fails. Epochs invalidate outstanding render responses.
class PlaybackLifecycle {
  Future<void> _tail = Future.value();
  int epoch = 0;
  bool closed = false;
  Future<void>? _closing;
  int invalidate() => ++epoch;
  Future<T> run<T>(Future<T> Function() operation) {
    if (closed) return Future.error(StateError('Audio engine disposed'));
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> close(Future<void> Function() cleanup) {
    if (_closing != null) return _closing!;
    closed = true;
    invalidate();
    return _closing = _tail.then((_) => cleanup());
  }
}
