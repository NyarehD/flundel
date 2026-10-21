import 'package:flutter/material.dart';
import 'package:flundel/visualization/generative/engine/visual_engine.dart';
import 'package:flundel/visualization/generative/engine/visual_parameters.dart';
import 'package:flundel/visualization/generative/engine/visual_seed.dart';
import 'package:flundel/visualization/generative/generative_sound_visual.dart';
import 'package:flundel/visualization/generative/profiles/deep_focus_visual_profile.dart';
import 'package:flundel/visualization/generative/profiles/focus_visual_profile.dart';
import 'package:flundel/visualization/generative/profiles/relax_visual_profile.dart';
import 'package:flundel/visualization/generative/profiles/sleep_visual_profile.dart';
import 'package:flundel/visualization/generative/profiles/visual_profile.dart';

/// Development-only debug control screen for tuning the Generative Visual Engine.
class GenerativeVisualDebugScreen extends StatefulWidget {
  const GenerativeVisualDebugScreen({super.key});

  @override
  State<GenerativeVisualDebugScreen> createState() =>
      _GenerativeVisualDebugScreenState();
}

class _GenerativeVisualDebugScreenState
    extends State<GenerativeVisualDebugScreen> {
  VisualProfile _selectedProfile = const FocusVisualProfile();
  GenerativeVisualSeed _seed = const GenerativeVisualSeed(
    sessionSeed: 42,
    patternSeed: 101,
  );
  GenerativeVisualQuality _quality = GenerativeVisualQuality.medium;
  late VisualParameters _params;
  bool _showPanel = true;

  @override
  void initState() {
    super.initState();
    _params = _selectedProfile.baseParameters;
  }

  void _onProfileChanged(VisualProfile? profile) {
    if (profile == null) return;
    setState(() {
      _selectedProfile = profile;
      _params = profile.baseParameters;
    });
  }

  void _randomizeSeed() {
    setState(() {
      _seed = GenerativeVisualSeed.random();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profiles = <VisualProfile>[
      const FocusVisualProfile(),
      const DeepFocusVisualProfile(),
      const RelaxVisualProfile(),
      const SleepVisualProfile(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GenerativeSoundVisual(
              profile: _selectedProfile,
              seed: _seed,
              quality: _quality,
              overrideParameters: _params,
              enableAudioState: false,
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: IconButton.filledTonal(
                  icon: Icon(_showPanel ? Icons.tune : Icons.tune_outlined),
                  onPressed: () {
                    setState(() {
                      _showPanel = !_showPanel;
                    });
                  },
                ),
              ),
            ),
          ),
          if (_showPanel)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.all(12.0),
                  padding: const EdgeInsets.all(16.0),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16.0),
                    border: .all(color: Colors.white24),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: .start,
                      mainAxisSize: .min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Visual Engine Tuning',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.casino, color: Colors.white),
                              onPressed: _randomizeSeed,
                              tooltip: 'Randomize Seed',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButton<VisualProfile>(
                                value: profiles.firstWhere(
                                  (p) => p.id == _selectedProfile.id,
                                ),
                                dropdownColor: Colors.grey[900],
                                isExpanded: true,
                                style: const TextStyle(color: Colors.white),
                                items: profiles.map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Text(p.name),
                                  );
                                }).toList(),
                                onChanged: _onProfileChanged,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButton<GenerativeVisualQuality>(
                                value: _quality,
                                dropdownColor: Colors.grey[900],
                                isExpanded: true,
                                style: const TextStyle(color: Colors.white),
                                items: GenerativeVisualQuality.values.map((q) {
                                  return DropdownMenuItem(
                                    value: q,
                                    child: Text('Quality: ${q.name.toUpperCase()}'),
                                  );
                                }).toList(),
                                onChanged: (q) {
                                  if (q != null) setState(() => _quality = q);
                                },
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 24),
                        _buildSlider('Energy', _params.energy, (v) {
                          setState(() => _params = _params.copyWith(energy: v));
                        }),
                        _buildSlider('Density', _params.density, (v) {
                          setState(() => _params = _params.copyWith(density: v));
                        }),
                        _buildSlider('Complexity', _params.complexity, (v) {
                          setState(() => _params = _params.copyWith(complexity: v));
                        }),
                        _buildSlider('Flow', _params.flow, (v) {
                          setState(() => _params = _params.copyWith(flow: v));
                        }),
                        _buildSlider('Pulse', _params.pulse, (v) {
                          setState(() => _params = _params.copyWith(pulse: v));
                        }),
                        _buildSlider('Turbulence', _params.turbulence, (v) {
                          setState(() => _params = _params.copyWith(turbulence: v));
                        }),
                        _buildSlider('Brightness', _params.brightness, (v) {
                          setState(() => _params = _params.copyWith(brightness: v));
                        }),
                        _buildSlider('Spatial Scale', _params.spatialScale, (v) {
                          setState(() => _params = _params.copyWith(spatialScale: v));
                        }),
                        _buildSlider('Speed', _params.speed, (v) {
                          setState(() => _params = _params.copyWith(speed: v));
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 2,
              ),
              child: Slider(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.lightBlueAccent,
                inactiveColor: Colors.white24,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
