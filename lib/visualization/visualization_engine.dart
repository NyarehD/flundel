import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flundel/audio/audio_analysis.dart';
import 'package:flundel/audio/audio_engine.dart';
import 'package:flundel/visualization/painters/soundscape_painter.dart';

/// A low-contrast, audio-reactive pattern. Preview instances never subscribe to
/// the audio engine; they show only the selected preset's ambient motion.
class VisualizationWidget extends ConsumerStatefulWidget {
  final String presetId;
  final bool preview;
  final bool isActive;
  final bool animatePreview;

  const VisualizationWidget({
    super.key,
    required this.presetId,
    this.preview = false,
    this.isActive = true,
    this.animatePreview = false,
  });

  @override
  ConsumerState<VisualizationWidget> createState() =>
      _VisualizationWidgetState();
}

class _VisualizationWidgetState extends ConsumerState<VisualizationWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  late final VisualizationModel _signals;
  StreamSubscription<AudioAnalysis>? _analysisSubscription;
  StreamSubscription<AudioEngineState>? _engineStateSubscription;
  AudioEngine? _audioEngine;
  Duration _elapsedOffset = Duration.zero;
  Duration _currentElapsed = Duration.zero;
  bool _enginePlaying;
  bool _lifecycleResumed = true;
  bool _tickerModeEnabled = true;
  bool _reducedMotion = false;

  _VisualizationWidgetState() : _enginePlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enginePlaying = widget.isActive;
    _signals = VisualizationModel();
    _ticker = createTicker(_onTick);
    if (!widget.preview) _connectToAudio();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _tickerModeEnabled = TickerMode.valuesOf(context).enabled;
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant VisualizationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preview != widget.preview) {
      if (widget.preview) {
        _disconnectFromAudio();
        _signals.clear();
      } else {
        _connectToAudio();
      }
    }
    if (oldWidget.isActive != widget.isActive) {
      _enginePlaying = widget.isActive;
      _syncTicker();
      if (!_enginePlaying) _signals.clearPulse();
    }
  }

  void _connectToAudio() {
    _audioEngine = ref.read(audioEngineProvider);
    final audioEngine = _audioEngine!;
    _analysisSubscription = audioEngine.analysisStream.listen((analysis) {
      if (!_lifecycleResumed || !_tickerModeEnabled) return;
      _signals.accept(analysis, motionEnabled: _ticker.isActive);
    });
    _engineStateSubscription = audioEngine.stateStream.listen((state) {
      _enginePlaying = state == AudioEngineState.playing;
      _syncTicker();
      if (state == AudioEngineState.stopped) {
        _signals.clear();
      } else if (!_enginePlaying) {
        _signals.clearPulse();
      }
    });
  }

  void _disconnectFromAudio() {
    _analysisSubscription?.cancel();
    _analysisSubscription = null;
    _engineStateSubscription?.cancel();
    _engineStateSubscription = null;
    _audioEngine = null;
  }

  void _onTick(Duration elapsed) {
    final total = _elapsedOffset + elapsed;
    final delta = total - _currentElapsed;
    _currentElapsed = total;
    _signals.advance(delta.inMicroseconds / Duration.microsecondsPerSecond);
  }

  void _syncTicker() {
    final shouldAnimate =
        !_reducedMotion &&
        _lifecycleResumed &&
        _tickerModeEnabled &&
        (widget.preview ? widget.animatePreview : _enginePlaying);
    if (shouldAnimate && !_ticker.isActive) {
      _ticker.start();
    } else if (!shouldAnimate && _ticker.isActive) {
      _elapsedOffset = _currentElapsed;
      _ticker.stop();
    }
    _signals.setMotionEnabled(shouldAnimate);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleResumed = state == AppLifecycleState.resumed;
    _syncTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnectFromAudio();
    _ticker.dispose();
    _signals.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _tickerModeEnabled = TickerMode.valuesOf(context).enabled;
    _syncTicker();

    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: SoundscapePainter(
          presetId: widget.presetId,
          signals: _signals,
          repaint: _signals,
        ),
      ),
    );
  }
}

class VisualizationModel extends ChangeNotifier
    implements VisualizationSignals {
  double _elapsedSeconds = 0;
  double _motionSeconds = 0;
  double _amplitude = 0.12;
  double _tonal = 0.16;
  double _texture = 0.08;
  double _piano = 0;
  double _focus = 0.35;
  double _targetAmplitude = 0.12;
  double _targetTonal = 0.16;
  double _targetTexture = 0.08;
  double _targetPiano = 0;
  double _targetFocus = 0.35;
  double _pianoPulse = 0;

  @override
  double get elapsedSeconds => _elapsedSeconds;
  @override
  double get motionSeconds => _motionSeconds;
  @override
  double get amplitude => _amplitude;
  @override
  double get tonal => _tonal;
  @override
  double get texture => _texture;
  @override
  double get piano => math.max(_piano, _pianoPulse).clamp(0.0, 1.0);
  @override
  double get pianoPulse => _pianoPulse.clamp(0.0, 1.0);
  @override
  double get focus => _focus;
  @override
  double get detail => (1 - _focus * 0.55).clamp(0.0, 1.0);
  bool _motionEnabled = false;

  void accept(AudioAnalysis analysis, {required bool motionEnabled}) {
    _targetAmplitude = _unit(analysis.amplitude);
    _targetTonal = _unit(analysis.tonalEnergy);
    _targetTexture = _unit(analysis.textureEnergy);
    _targetPiano = _unit(analysis.pianoActivity);
    _targetFocus = _unit(analysis.focusDepth);
    if (analysis.hasPianoEvent && motionEnabled) {
      _pianoPulse = math.max(_pianoPulse, 0.7 + _targetPiano * 0.3);
    }
    if (!motionEnabled) {
      _amplitude = _targetAmplitude;
      _tonal = _targetTonal;
      _texture = _targetTexture;
      _piano = _targetPiano;
      _focus = _targetFocus;
      _pianoPulse = 0;
    }
    notifyListeners();
  }

  void advance(double deltaSeconds) {
    if (!_motionEnabled || !deltaSeconds.isFinite || deltaSeconds <= 0) return;
    final dt = deltaSeconds.clamp(0.0, 0.1);
    final smoothing = 1 - math.exp(-dt * 1.7);
    _motionSeconds += dt;
    final phaseVelocity = 0.65 + (1 - _focus) * 0.6;
    _elapsedSeconds += dt * phaseVelocity;
    _amplitude += (_targetAmplitude - _amplitude) * smoothing;
    _tonal += (_targetTonal - _tonal) * smoothing;
    _texture += (_targetTexture - _texture) * smoothing;
    _piano += (_targetPiano - _piano) * smoothing;
    _focus += (_targetFocus - _focus) * smoothing;
    _pianoPulse *= math.exp(-dt * 2.4);
    if (_pianoPulse < 0.015) _pianoPulse = 0;
    notifyListeners();
  }

  void setMotionEnabled(bool value) {
    if (_motionEnabled == value) return;
    _motionEnabled = value;
    if (!value) _pianoPulse = 0;
    notifyListeners();
  }

  void clearPulse() {
    if (_pianoPulse == 0) return;
    _pianoPulse = 0;
    notifyListeners();
  }

  void clear() {
    _targetAmplitude = 0.12;
    _targetTonal = 0.16;
    _targetTexture = 0.08;
    _targetPiano = 0;
    _targetFocus = 0.35;
    _amplitude = 0.12;
    _tonal = 0.16;
    _texture = 0.08;
    _piano = 0;
    _focus = 0.35;
    _pianoPulse = 0;
    notifyListeners();
  }

  static double _unit(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0) : 0;
}
