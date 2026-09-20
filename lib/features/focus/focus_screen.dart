import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flundel/session/session_view_model.dart';
import 'package:flundel/session/session_phase.dart';
import 'package:flundel/visualization/visualization_engine.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  bool _showControls = false;

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionViewModelProvider);
    final viewModel = ref.read(sessionViewModelProvider.notifier);

    final preset = sessionState.selectedPreset;
    final displayTime = sessionState.remainingSeconds != null
        ? _formatTime(sessionState.remainingSeconds!)
        : _formatTime(sessionState.elapsedSeconds);

    return Scaffold(
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Ambient generative visualization
            VisualizationWidget(visualPreset: preset.visualPreset),

            // Main ambient timer & phase
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  children: [
                    Text(
                      preset.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        letterSpacing: 3.0,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sessionState.phase.labelKey.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const Spacer(),

                    // Timer display
                    Text(
                      displayTime,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 72,
                            fontWeight: FontWeight.w200,
                          ),
                    ),

                    const Spacer(),

                    // Expandable controls or minimal stop button
                    if (_showControls) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            _buildSlider('controls.intensity'.tr(), preset.config.intensity),
                            _buildSlider('controls.warmth'.tr(), preset.config.warmth),
                            _buildSlider('controls.piano'.tr(), preset.config.piano),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: 140,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: sessionState.isLoading
                            ? null
                            : () async {
                                await viewModel.stopSession();
                                if (context.mounted) {
                                  context.go('/');
                                }
                              },
                        child: sessionState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                ),
                              )
                            : Text(
                                'actions.stop'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            onChanged: (val) {},
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
