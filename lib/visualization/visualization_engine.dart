import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flundel/audio/audio_analysis.dart';
import 'package:flundel/visualization/painters/soundscape_painter.dart';

import 'package:flundel/audio/audio_engine.dart';

class VisualizationWidget extends ConsumerStatefulWidget {
  final String visualPreset;

  const VisualizationWidget({
    super.key,
    required this.visualPreset,
  });

  @override
  ConsumerState<VisualizationWidget> createState() => _VisualizationWidgetState();
}

class _VisualizationWidgetState extends ConsumerState<VisualizationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  AudioAnalysis? _latestAnalysis;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    final audioEngine = ref.read(audioEngineProvider);
    audioEngine.analysisStream.listen((analysis) {
      if (mounted) {
        setState(() {
          _latestAnalysis = analysis;
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: SoundscapePainter(
            animationValue: _animController.value,
            analysis: _latestAnalysis,
            visualPreset: widget.visualPreset,
          ),
        );
      },
    );
  }
}
