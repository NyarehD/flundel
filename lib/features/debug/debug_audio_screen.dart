import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flundel/audio/audio_engine.dart';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flundel/session/session_view_model.dart';

class DebugAudioScreen extends ConsumerStatefulWidget {
  const DebugAudioScreen({super.key});

  @override
  ConsumerState<DebugAudioScreen> createState() => _DebugAudioScreenState();
}

class _DebugAudioScreenState extends ConsumerState<DebugAudioScreen> {
  Timer? _diagnosticsTimer;

  double _masterVolume = 0.9;
  double _intensity = 0.7;
  // Match the built-in Deep Work preset so a debug capture represents the
  // default listening balance rather than a different hand-tuned mixture.
  double _noiseVol = 0.7;
  double _padVol = 0.5;
  double _pianoVol = 0.2;
  double _binauralVol = 0.4;
  double _natureVol = 0.2;
  double _beatsVol = 0.4;
  double _bassVol = 0.28;
  int _beatsBpm = 72;

  double _focusDepth = 0.5;
  double _warmth = 0.6;
  double _complexity = 0.3;
  double _cutoffHz = 1200;
  double _reverbSend = 0.3;
  bool _capturingPreview = false;
  bool _startingPreview = false;
  String? _previewPath;

  Future<void> _capturePreview(AudioEngine engine) async {
    setState(() => _capturingPreview = true);
    try {
      final bytes = await engine.captureOutputPreview(
        const Duration(seconds: 12),
      );
      final dir = await Directory.systemTemp.createTemp(
        'flundel-audio-preview-',
      );
      final file = File('${dir.path}/mixer-output-preview.wav');
      await file.writeAsBytes(bytes, flush: true);
      if (mounted) setState(() => _previewPath = file.path);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preview capture failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturingPreview = false);
    }
  }

  Future<void> _togglePreviewSession(AudioEngine engine) async {
    if (_startingPreview) return;
    setState(() => _startingPreview = true);
    try {
      if (engine.getDiagnostics()['state'] == 'playing') {
        await engine.stop();
      } else {
        await engine.start(
          SoundscapeConfig(
            intensity: 0.7,
            noise: _noiseVol,
            pad: _padVol,
            piano: _pianoVol,
            binaural: _binauralVol,
            nature: _natureVol,
            beats: _beatsVol,
            bass: _bassVol,
            beatsBpm: _beatsBpm,
            warmth: _warmth,
            complexity: _complexity,
          ),
          sessionSeed: 42,
        );
        await engine.setFocusDepth(_focusDepth);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preview playback failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _startingPreview = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final activeConfig = ref
        .read(sessionViewModelProvider)
        .currentSession
        ?.preset
        .config;
    if (activeConfig != null) {
      _intensity = activeConfig.intensity;
      _noiseVol = activeConfig.noise;
      _padVol = activeConfig.pad;
      _pianoVol = activeConfig.piano;
      _binauralVol = activeConfig.binaural;
      _natureVol = activeConfig.nature;
      _beatsVol = activeConfig.beats;
      _bassVol = activeConfig.bass;
      _beatsBpm = activeConfig.beatsBpm;
      _warmth = activeConfig.warmth;
      _complexity = activeConfig.complexity;
    }
    _diagnosticsTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _diagnosticsTimer?.cancel();
    super.dispose();
  }

  Future<void> _applyConfigUpdates() async {
    final engine = ref.read(audioEngineProvider);
    try {
      await engine.updateConfig(
        SoundscapeConfig(
          intensity: _intensity,
          noise: _noiseVol,
          pad: _padVol,
          piano: _pianoVol,
          binaural: _binauralVol,
          nature: _natureVol,
          beats: _beatsVol,
          bass: _bassVol,
          beatsBpm: _beatsBpm,
          warmth: _warmth,
          complexity: _complexity,
        ),
      );
      await engine.setFocusDepth(_focusDepth);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Config update failed: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = ref.read(audioEngineProvider);
    final diag = engine.getDiagnostics();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Engine Diagnostics & Tuning'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFF121418),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel 1: Diagnostics
            _buildSectionCard(
              title: 'Diagnostics',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('State: ${diag['state']}', style: _diagStyle),
                  Text(
                    'Piano Voices: ${diag['activePianoVoices']} / ${diag['maxPianoVoices']}',
                    style: _diagStyle,
                  ),
                  Text(
                    'All Voices: ${diag['activeVoiceHandles']} / ${diag['nativeConfiguredMaxActiveVoices']}',
                    style: _diagStyle,
                  ),
                  Text(
                    'Sample Rate: ${diag['sampleRateHz']} Hz | Buffer: ${diag['bufferSizeFrames']} frames',
                    style: _diagStyle,
                  ),
                  Text(
                    'Focus Depth: ${(diag['focusDepth'] as double? ?? 0.0).toStringAsFixed(2)}',
                    style: _diagStyle,
                  ),
                  Text(
                    'Peak Amplitude: ${(diag['peakAmplitude'] as double? ?? 0.0).toStringAsFixed(3)}',
                    style: _diagStyle,
                  ),
                  Text(
                    'Output Peak dBFS: ${(diag['outputPeakDbfs'] as double? ?? -120.0).toStringAsFixed(1)}',
                    style: _diagStyle,
                  ),
                  Text(
                    'Underruns: ${diag['underrunsCount'] ?? 'not available'}',
                    style: _diagStyle,
                  ),
                  Text('Backend: ${diag['backend']}', style: _diagStyle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _startingPreview
                            ? null
                            : () => _togglePreviewSession(engine),
                        icon: Icon(
                          diag['state'] == 'playing'
                              ? Icons.stop
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          _startingPreview
                              ? 'Starting…'
                              : diag['state'] == 'playing'
                              ? 'Stop preview session'
                              : 'Start preview session',
                        ),
                      ),
                      FilledButton.icon(
                        onPressed:
                            _capturingPreview || diag['state'] != 'playing'
                            ? null
                            : () => _capturePreview(engine),
                        icon: const Icon(Icons.graphic_eq),
                        label: Text(
                          _capturingPreview
                              ? 'Capturing 12s…'
                              : 'Capture actual mixer preview',
                        ),
                      ),
                    ],
                  ),
                  if (_previewPath != null)
                    SelectableText(
                      'Preview WAV: $_previewPath',
                      style: _diagStyle,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Panel 2: Master & Focus Controls
            _buildSectionCard(
              title: 'Master & Macro Controls',
              child: Column(
                children: [
                  _buildSlider('Focus Depth', _focusDepth, (v) {
                    setState(() => _focusDepth = v);
                    _applyConfigUpdates();
                  }),
                  _buildSlider('Master Gain', _masterVolume, (v) {
                    setState(() => _masterVolume = v);
                    engine.setMasterVolume(v);
                  }),
                  _buildSlider('Warmth', _warmth, (v) {
                    setState(() => _warmth = v);
                    _applyConfigUpdates();
                  }),
                  _buildSlider('Complexity', _complexity, (v) {
                    setState(() => _complexity = v);
                    _applyConfigUpdates();
                  }),
                  _buildSlider(
                    'Filter Cutoff (Hz)',
                    _cutoffHz,
                    (v) {
                      setState(() => _cutoffHz = v);
                      engine.setFilterCutoff(v);
                    },
                    min: 200,
                    max: 4000,
                  ),
                  _buildSlider('Reverb Send', _reverbSend, (v) {
                    setState(() => _reverbSend = v);
                    engine.setReverbMix(v);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Panel 3: Layer Volume, Solo & Mute Toggles
            _buildSectionCard(
              title: 'Layer Mix & Solos / Mutes',
              child: Column(
                children: [
                  _buildLayerRow('Noise', _noiseVol, 'noise', engine, (v) {
                    setState(() => _noiseVol = v);
                    _applyConfigUpdates();
                  }),
                  _buildLayerRow('Pad / Synth', _padVol, 'pad', engine, (v) {
                    setState(() => _padVol = v);
                    _applyConfigUpdates();
                  }),
                  _buildLayerRow('Piano', _pianoVol, 'piano', engine, (v) {
                    setState(() => _pianoVol = v);
                    _applyConfigUpdates();
                  }),
                  _buildLayerRow('Beats', _beatsVol, 'beats', engine, (v) {
                    setState(() => _beatsVol = v);
                    _applyConfigUpdates();
                  }),
                  _buildLayerRow('Bass', _bassVol, 'bass', engine, (v) {
                    setState(() => _bassVol = v);
                    _applyConfigUpdates();
                  }),
                  _buildLayerRow('Binaural', _binauralVol, 'binaural', engine, (
                    v,
                  ) {
                    setState(() => _binauralVol = v);
                    _applyConfigUpdates();
                  }),
                  _buildLayerRow('Nature', _natureVol, 'nature', engine, (v) {
                    setState(() => _natureVol = v);
                    _applyConfigUpdates();
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Panel 4: Quick Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      for (final key in [
                        'noise',
                        'pad',
                        'piano',
                        'beats',
                        'bass',
                        'binaural',
                        'nature',
                      ]) {
                        engine.setLayerMuted(key, false);
                        engine.setLayerSolo(key, false);
                      }
                      setState(() {
                        _masterVolume = 0.9;
                        _intensity = 0.7;
                        _noiseVol = 0.7;
                        _padVol = 0.5;
                        _pianoVol = 0.2;
                        _beatsVol = 0.4;
                        _bassVol = 0.28;
                        _beatsBpm = 72;
                        _binauralVol = 0.4;
                        _natureVol = 0.2;
                        _focusDepth = 0.5;
                      });
                      _applyConfigUpdates();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                    ),
                    child: const Text('Reset All Parameters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white24, height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double val,
    ValueChanged<double> onChanged, {
    double min = 0.0,
    double max = 1.0,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: Slider(
            value: val.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 45,
          child: Text(
            val.toStringAsFixed(2),
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildLayerRow(
    String name,
    double val,
    String key,
    AudioEngine engine,
    ValueChanged<double> onChanged,
  ) {
    final diagnostics = engine.getDiagnostics();
    final muted = diagnostics['layerMuted'] as Map<String, bool>? ?? const {};
    final solo = diagnostics['layerSolo'] as Map<String, bool>? ?? const {};
    final isMuted = muted[key] ?? false;
    final isSolo = solo[key] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Expanded(
            child: Slider(value: val.clamp(0.0, 1.0), onChanged: onChanged),
          ),
          IconButton(
            icon: Icon(
              Icons.volume_off,
              color: isMuted ? Colors.red : Colors.white30,
              size: 20,
            ),
            onPressed: () {
              engine.setLayerMuted(key, !isMuted);
              setState(() {});
            },
          ),
          IconButton(
            icon: Icon(
              Icons.headset,
              color: isSolo ? Colors.amber : Colors.white30,
              size: 20,
            ),
            onPressed: () {
              engine.setLayerSolo(key, !isSolo);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  static const _diagStyle = TextStyle(
    color: Colors.greenAccent,
    fontFamily: 'monospace',
    fontSize: 13,
    height: 1.4,
  );
}
