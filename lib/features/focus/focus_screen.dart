import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flundel/session/session_phase.dart';
import 'package:flundel/session/session_state.dart';
import 'package:flundel/session/session_view_model.dart';
import 'package:flundel/visualization/visualization_engine.dart';
import 'package:flundel/domain/models/soundscape_preset.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  bool _showControls = false;
  bool _showSecondaryInfo = true;
  Map<String, double> _dragValues = {};
  Future<bool>? _lastControlUpdate;

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }

  double _displayValue(String key, double current) =>
      _dragValues[key] ?? current;

  void _changeControl(String key, double value) {
    setState(() => _dragValues = {..._dragValues, key: value});
    final viewModel = ref.read(sessionViewModelProvider.notifier);
    _lastControlUpdate = switch (key) {
      'intensity' => viewModel.updateSessionControls(intensity: value),
      'warmth' => viewModel.updateSessionControls(warmth: value),
      'piano' => viewModel.updateSessionControls(piano: value),
      'beats' => viewModel.updateSessionControls(beats: value),
      'bass' => viewModel.updateSessionControls(bass: value),
      'nature' => viewModel.updateSessionControls(nature: value),
      'binaural' => viewModel.updateSessionControls(binaural: value),
      'noise' => viewModel.updateSessionControls(noise: value),
      'pad' => viewModel.updateSessionControls(pad: value),
      _ => Future.value(false),
    };
  }

  Future<void> _finishControlChange(String key) async {
    final update = _lastControlUpdate;
    if (update == null) return;
    final success = await update;
    if (!mounted) return;
    setState(() {
      _dragValues = {..._dragValues}..remove(key);
    });
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('controls.update_failed'.tr()),
          backgroundColor: const Color(0xFF242424),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionViewModelProvider);
    final viewModel = ref.read(sessionViewModelProvider.notifier);
    final preset =
        sessionState.currentSession?.preset ?? sessionState.selectedPreset;
    final duration =
        sessionState.remainingSeconds ?? sessionState.elapsedSeconds;
    final displayTime = _formatTime(duration);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          VisualizationWidget(
            presetId: preset.id,
            isActive: sessionState.isActive && !sessionState.isPaused,
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () =>
                setState(() => _showSecondaryInfo = !_showSecondaryInfo),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final viewportHeight = constraints.maxHeight;
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (viewportHeight - 38).clamp(
                            0.0,
                            double.infinity,
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildHeader(
                                sessionState: sessionState,
                                viewModel: viewModel,
                                presetId: preset.id,
                                displayTime: displayTime,
                              ),
                              _buildFooter(
                                sessionState: sessionState,
                                viewModel: viewModel,
                                preset: preset,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required SessionState sessionState,
    required SessionViewModel viewModel,
    required String presetId,
    required String displayTime,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: sessionState.isPaused
                  ? 'actions.resume'.tr()
                  : 'actions.pause'.tr(),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              padding: EdgeInsets.zero,
              onPressed: !sessionState.isActive || sessionState.isLoading
                  ? null
                  : () => sessionState.isPaused
                        ? viewModel.resumeSession()
                        : viewModel.pauseSession(),
              icon: Icon(
                sessionState.isPaused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _showSecondaryInfo ? 1 : 0.08,
                child: Column(
                  children: [
                    Text(
                      'presets.$presetId'.tr().toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.6,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      sessionState.isPaused
                          ? 'player.paused'.tr()
                          : sessionState.phase.labelKey.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 0.5,
                        color: Colors.white54,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        displayTime,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 23,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.5,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'actions.customize'.tr(),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              padding: EdgeInsets.zero,
              onPressed: () => setState(() => _showControls = !_showControls),
              icon: Icon(
                _showControls ? Icons.tune : Icons.tune_outlined,
                color: Colors.white70,
                size: 19,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter({
    required SessionState sessionState,
    required SessionViewModel viewModel,
    required SoundscapePreset preset,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: _showControls
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    children: [
                      MergeSemantics(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'controls.completion_sound'.tr(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: sessionState.completionCueEnabled,
                              onChanged: sessionState.isLoading
                                  ? null
                                  : viewModel.setCompletionCueEnabled,
                              activeTrackColor: Colors.white70,
                              activeThumbColor: Colors.black,
                              inactiveTrackColor: Colors.white12,
                              inactiveThumbColor: Colors.white54,
                            ),
                          ],
                        ),
                      ),
                      _ControlSlider(
                        label: 'controls.intensity'.tr(),
                        value: _displayValue(
                          'intensity',
                          preset.config.intensity,
                        ),
                        onChanged:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (value) => _changeControl('intensity', value),
                        onChangeEnd:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (_) => _finishControlChange('intensity'),
                      ),
                      _ControlSlider(
                        label: 'controls.warmth'.tr(),
                        value: _displayValue('warmth', preset.config.warmth),
                        onChanged:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (value) => _changeControl('warmth', value),
                        onChangeEnd:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (_) => _finishControlChange('warmth'),
                      ),
                      _ControlSlider(
                        label: 'controls.piano'.tr(),
                        value: _displayValue('piano', preset.config.piano),
                        onChanged:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (value) => _changeControl('piano', value),
                        onChangeEnd:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (_) => _finishControlChange('piano'),
                      ),
                      _ControlSlider(
                        label: 'controls.beats'.tr(),
                        value: _displayValue('beats', preset.config.beats),
                        onChanged:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (value) => _changeControl('beats', value),
                        onChangeEnd:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (_) => _finishControlChange('beats'),
                      ),
                      _ControlSlider(
                        label: 'controls.bass'.tr(),
                        value: _displayValue('bass', preset.config.bass),
                        onChanged:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (value) => _changeControl('bass', value),
                        onChangeEnd:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (_) => _finishControlChange('bass'),
                      ),
                      _ControlSlider(
                        label: 'controls.nature'.tr(),
                        value: _displayValue('nature', preset.config.nature),
                        onChanged:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (value) => _changeControl('nature', value),
                        onChangeEnd:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (_) => _finishControlChange('nature'),
                      ),
                      _ControlSlider(
                        label: 'controls.binaural'.tr(),
                        value: _displayValue('binaural', preset.config.binaural),
                        onChanged:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (value) => _changeControl('binaural', value),
                        onChangeEnd:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (_) => _finishControlChange('binaural'),
                      ),
                      _ControlSlider(
                        label: 'controls.noise'.tr(),
                        value: _displayValue('noise', preset.config.noise),
                        onChanged:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (value) => _changeControl('noise', value),
                        onChangeEnd:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (_) => _finishControlChange('noise'),
                      ),
                      _ControlSlider(
                        label: 'controls.pad'.tr(),
                        value: _displayValue('pad', preset.config.pad),
                        onChanged:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (value) => _changeControl('pad', value),
                        onChangeEnd:
                            !sessionState.isActive ||
                                sessionState.isPaused ||
                                sessionState.isLoading
                            ? null
                            : (_) => _finishControlChange('pad'),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        SizedBox(
          width: 152,
          height: 48,
          child: OutlinedButton(
            onPressed: sessionState.isLoading
                ? null
                : () async {
                    await viewModel.stopSession();
                    if (mounted) context.go('/');
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.42)),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: sessionState.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: Colors.white70,
                    ),
                  )
                : Text(
                    'actions.stop'.tr(),
                    style: const TextStyle(fontSize: 10, letterSpacing: 2.3),
                  ),
          ),
        ),
        const SizedBox(height: 7),
        if (!_showControls)
          Text(
            'player.customize_hint'.tr(),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
              letterSpacing: 0.6,
            ),
          ),
      ],
    );
  }
}

class _ControlSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  const _ControlSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(11);
    final stacked = textScale >= 15 || MediaQuery.sizeOf(context).width < 360;
    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 1,
        activeTrackColor: Colors.white70,
        inactiveTrackColor: Colors.white24,
        disabledActiveTrackColor: Colors.white24,
        disabledInactiveTrackColor: Colors.white12,
        thumbColor: Colors.white,
        overlayColor: Colors.white10,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
      ),
      child: Slider(
        value: value.clamp(0.0, 1.0),
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
        semanticFormatterCallback: (current) =>
            '$label, ${(current * 100).round()} percent',
      ),
    );
    final labelStyle = TextStyle(
      color: Colors.white70,
      fontSize: 11,
      letterSpacing: 0.3,
    );
    final valueLabel = Text(
      '${(value * 100).round()}',
      textAlign: TextAlign.right,
      style: const TextStyle(color: Colors.white38, fontSize: 9),
    );

    if (stacked) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: labelStyle)),
                valueLabel,
              ],
            ),
            slider,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 74, child: Text(label, style: labelStyle)),
          Expanded(child: slider),
          SizedBox(width: 34, child: valueLabel),
        ],
      ),
    );
  }
}
