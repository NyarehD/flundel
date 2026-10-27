import 'package:audio_service/audio_service.dart';

/// Media-session bridge for Android notification and iOS lock-screen controls.
class FlundelAudioHandler extends BaseAudioHandler {
  Future<void> Function()? onPlay;
  Future<void> Function()? onPause;
  Future<void> Function()? onStop;

  void publish({required bool playing}) {
    mediaItem.add(
      const MediaItem(
        id: 'focus-session',
        title: 'Flundel Focus',
        artist: 'Soundscape',
      ),
    );
    playbackState.add(
      PlaybackState(
        controls: playing
            ? const [MediaControl.pause, MediaControl.stop]
            : const [MediaControl.play, MediaControl.stop],
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
        },
        playing: playing,
        processingState: AudioProcessingState.ready,
      ),
    );
  }

  void publishIdle() {
    playbackState.add(
      PlaybackState(
        controls: [],
        systemActions: {},
      ),
    );
  }

  @override
  Future<void> play() async {
    await onPlay?.call();
  }

  @override
  Future<void> pause() async {
    await onPause?.call();
  }

  @override
  Future<void> stop() async {
    await onStop?.call();
    await super.stop();
    publishIdle();
  }
}

FlundelAudioHandler? flundelAudioHandler;
