import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flundel/audio/audio_engine.dart';
import 'package:flundel/audio/audio_engine_impl.dart';
import 'package:flundel/domain/models/soundscape_config.dart';

class DebugAudioScreen extends ConsumerStatefulWidget {
  const DebugAudioScreen({super.key});

  @override
  ConsumerState<DebugAudioScreen> createState() => _DebugAudioScreenState();
}

class _DebugAudioScreenState extends ConsumerState<DebugAudioScreen> {
  Timer? _diagnosticsTimer;

  double _masterVolume = 0.9;
  double _noiseVol = 0.5;
  double _padVol = 0.5;
  double _pianoVol = 0.4;
  double _binauralVol = 0.3;
  double _natureVol = 0.3;

  double _focusDepth = 0.5;
  double _warmth = 0.5;
  double _complexity = 0.5;
  double _cutoffHz = 1200;
  double _reverbSend = 0.3;

  @override
  void initState() {
    super.initState();
    _diagnosticsTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _diagnosticsTimer?.cancel();
    super.dispose();
  }

  void _applyConfigUpdates() {
    final engine = ref.read(audioEngineProvider);
    engine.updateConfig(SoundscapeConfig(
      noise: _noiseVol,
      pad: _padVol,
      piano: _pianoVol,
      binaural: _binauralVol,
      nature: _natureVol,
      warmth: _warmth,
      complexity: _complexity,
    ));
    engine.setFocusDepth(_focusDepth);
  }

  @override
  Widget build(BuildContext context) {
    final engine = ref.read(audioEngineProvider);
    final engineImpl = engine is AudioEngineImpl ? engine : null;
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
                  Text('Active Piano Voices: ${diag['activePianoVoices']} / ${diag['maxPolyphony']}', style: _diagStyle),
                  Text('Sample Rate: ${diag['sampleRateHz']} Hz | Buffer: ${diag['bufferSizeFrames']} frames', style: _diagStyle),
                  Text('Underruns: ${diag['underrunsCount']}', style: _diagStyle),
                  Text('Current Chord: ${diag['currentChord']}', style: _diagStyle),
                  Text('Focus Depth: ${(diag['focusDepth'] as double? ?? 0.0).toStringAsFixed(2)}', style: _diagStyle),
                  Text('Peak Amp: ${(diag['peakAmplitudeDbfs'] as double? ?? 0.0).toStringAsFixed(2)}', style: _diagStyle),
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
                    if (engineImpl != null) {
                      engineImpl.audioBus.masterVolume.setTarget(v);
                    }
                  }),
                  _buildSlider('Warmth', _warmth, (v) {
                    setState(() => _warmth = v);
                    _applyConfigUpdates();
                  }),
                  _buildSlider('Complexity', _complexity, (v) {
                    setState(() => _complexity = v);
                    _applyConfigUpdates();
                  }),
                  _buildSlider('Filter Cutoff (Hz)', _cutoffHz, (v) {
                    setState(() => _cutoffHz = v);
                    if (engineImpl != null) {
                      engineImpl.noiseEngine.cutoffHz.setTarget(v);
                    }
                  }, min: 200, max: 4000),
                  _buildSlider('Reverb Send', _reverbSend, (v) {
                    setState(() => _reverbSend = v);
                    if (engineImpl != null) {
                      engineImpl.audioBus.reverbBusSend.setTarget(v);
                    }
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
                  _buildLayerRow('Noise', _noiseVol, 'noise', engineImpl, (v) {
                    setState(() => _noiseVol = v);
                    _applyConfigUpdates();
                  }),
                  _buildLayerRow('Pad / Synth', _padVol, 'pad', engineImpl, (v) {
                    setState(() => _padVol = v);
                    _applyConfigUpdates();
                  }),
                  _buildLayerRow('Piano', _pianoVol, 'piano', engineImpl, (v) {
                    setState(() => _pianoVol = v);
                    _applyConfigUpdates();
                  }),
                  _buildLayerRow('Binaural', _binauralVol, 'binaural', engineImpl, (v) {
                    setState(() => _binauralVol = v);
                    _applyConfigUpdates();
                  }),
                  _buildLayerRow('Nature', _natureVol, 'nature', engineImpl, (v) {
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
                      if (engineImpl != null) {
                        for (final key in engineImpl.layerMuted.keys) {
                          engineImpl.layerMuted[key] = false;
                          engineImpl.layerSolo[key] = false;
                        }
                      }
                      setState(() {
                        _masterVolume = 0.9;
                        _noiseVol = 0.5;
                        _padVol = 0.5;
                        _pianoVol = 0.4;
                        _binauralVol = 0.3;
                        _natureVol = 0.3;
                        _focusDepth = 0.5;
                      });
                      _applyConfigUpdates();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
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
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double val, ValueChanged<double> onChanged, {double min = 0.0, double max = 1.0}) {
    return Row(
      children: [
        SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Expanded(
          child: Slider(
            value: val.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 45, child: Text(val.toStringAsFixed(2), style: const TextStyle(color: Colors.white54, fontSize: 11))),
      ],
    );
  }

  Widget _buildLayerRow(String name, double val, String key, AudioEngineImpl? engineImpl, ValueChanged<double> onChanged) {
    final isMuted = engineImpl?.layerMuted[key] ?? false;
    final isSolo = engineImpl?.layerSolo[key] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 12))),
          Expanded(
            child: Slider(
              value: val.clamp(0.0, 1.0),
              onChanged: onChanged,
            ),
          ),
          IconButton(
            icon: Icon(Icons.volume_off, color: isMuted ? Colors.red : Colors.white30, size: 20),
            onPressed: () {
              if (engineImpl != null) {
                setState(() => engineImpl.layerMuted[key] = !isMuted);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.headset, color: isSolo ? Colors.amber : Colors.white30, size: 20),
            onPressed: () {
              if (engineImpl != null) {
                setState(() => engineImpl.layerSolo[key] = !isSolo);
              }
            },
          ),
        ],
      ),
    );
  }

  static const _diagStyle = TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 13, height: 1.4);
}
