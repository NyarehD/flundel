import 'dart:async';

import 'package:flundel/audio/audio_analysis.dart';
import 'package:flundel/audio/audio_engine.dart';
import 'package:flundel/visualization/generative/engine/visual_engine.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/engine/visual_seed.dart';
import 'package:flundel/visualization/generative/engine/visual_state.dart';
import 'package:flundel/visualization/generative/painters/generative_visual_painter.dart';
import 'package:flundel/visualization/generative/profiles/focus_visual_profile.dart';
import 'package:flundel/visualization/generative/profiles/visual_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reusable Generative Visual Engine Widget.
///
/// Continuously renders calm, abstract, non-repeating procedural visual patterns
/// synchronized with soundscape states.
class GenerativeSoundVisual extends ConsumerStatefulWidget {

  const GenerativeSoundVisual({
    super.key,
    this.profile = const FocusVisualProfile(),
    this.seed,
    this.quality = GenerativeVisualQuality.medium,
    this.overrideParameters,
    this.animate = true,
    this.enableAudioState = true,
  });
  final VisualProfile profile;
  final GenerativeVisualSeed? seed;
  final GenerativeVisualQuality quality;
  final VisualParameters? overrideParameters;
  final bool animate;
  final bool enableAudioState;

  @override
  ConsumerState<GenerativeSoundVisual> createState() =>
      _GenerativeSoundVisualState();
}

class _GenerativeSoundVisualState extends ConsumerState<GenerativeSoundVisual>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  late final VisualEngine _engine;
  StreamSubscription<AudioAnalysis>? _analysisSubscription;
  StreamSubscription<AudioEngineState>? _engineStateSubscription;

  Duration _elapsedOffset = Duration.zero;
  Duration _currentElapsed = Duration.zero;
  bool _lifecycleResumed = true;
  bool _tickerModeEnabled = true;
  bool _reducedMotion = false;

  ColorPalette _activePalette = ColorPalette.focus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _activePalette = widget.profile.palette;
    _engine = VisualEngine(
      seed: widget.seed,
      initialParameters: widget.overrideParameters ?? widget.profile.baseParameters,
      quality: widget.quality,
    );

    _ticker = createTicker(_onTick);
    if (widget.enableAudioState) {
      _connectToAudioEngine();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _tickerModeEnabled = TickerMode.valuesOf(context).enabled;
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant GenerativeSoundVisual oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.seed != widget.seed && widget.seed != null) {
      _engine.setSeed(widget.seed!);
    }

    if (oldWidget.quality != widget.quality) {
      _engine.setQuality(widget.quality);
    }

    if (oldWidget.profile != widget.profile) {
      _activePalette = widget.profile.palette;
      _engine.setTargetParameters(
        widget.overrideParameters ?? widget.profile.baseParameters,
      );
    } else if (oldWidget.overrideParameters != widget.overrideParameters &&
        widget.overrideParameters != null) {
      _engine.setTargetParameters(widget.overrideParameters!);
    }

    if (oldWidget.animate != widget.animate) {
      _syncTicker();
    }
  }

  void _connectToAudioEngine() {
    try {
      final audioEngine = ref.read(audioEngineProvider);
      _analysisSubscription = audioEngine.analysisStream.listen((analysis) {
        if (!_lifecycleResumed || !_tickerModeEnabled) return;
        final state = AudioVisualState.fromAudioAnalysis(analysis);
        _engine.updateAudioState(state);
      });

      _engineStateSubscription = audioEngine.stateStream.listen((state) {
        _syncTicker();
      });
    } catch (_) {
      // Standalone mode without active audio provider initialization
    }
  }

  void _disconnectFromAudioEngine() {
    _analysisSubscription?.cancel();
    _analysisSubscription = null;
    _engineStateSubscription?.cancel();
    _engineStateSubscription = null;
  }

  void _onTick(Duration elapsed) {
    final total = _elapsedOffset + elapsed;
    final delta = total - _currentElapsed;
    _currentElapsed = total;

    _engine.advance(
      delta.inMicroseconds / Duration.microsecondsPerSecond,
      reducedMotion: _reducedMotion,
    );
  }

  void _syncTicker() {
    final shouldAnimate = widget.animate && _lifecycleResumed && _tickerModeEnabled;
    if (shouldAnimate && !_ticker.isActive) {
      _ticker.start();
    } else if (!shouldAnimate && _ticker.isActive) {
      _elapsedOffset = _currentElapsed;
      _ticker.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleResumed = state == AppLifecycleState.resumed;
    _syncTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnectFromAudioEngine();
    _ticker.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _tickerModeEnabled = TickerMode.valuesOf(context).enabled;
    _syncTicker();

    final params = widget.overrideParameters ?? _engine.parameters;

    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: GenerativeVisualPainter(
          profile: widget.profile,
          engine: _engine,
          params: params,
          palette: _activePalette,
          repaint: _engine,
        ),
      ),
    );
  }
}
