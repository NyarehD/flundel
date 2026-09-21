import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

enum SoundscapeMode { focus, relax, sleep }

class SoundscapeEngine {
  final SoLoud _soloud = SoLoud.instance;
  final Random _rng = Random();

  AudioSource? _droneSource;
  AudioSource? _noiseSource;
  final List<AudioSource> _chimeSources = [];

  SoundHandle? _droneHandle;
  SoundHandle? _noiseHandle;

  Timer? _generativeTimer;
  bool _isRunning = false;
  bool _isInitialized = false;

  /// Initializes the audio backend with explicit buffer sizing to prevent underruns.
  Future<void> init() async {
    if (_isInitialized) return;

    if (!_soloud.isInitialized) {
      await _soloud.init(
        bufferSize: 2048,   // Prevents hardware buffer starvation on Android
        sampleRate: 48000,  // Standard hardware clock
      );
    }

    _isInitialized = true;
    await _loadPriorityAssets();
  }

  /// Loads critical loop beds first, then queues stems asynchronously.
  Future<void> _loadPriorityAssets() async {
    try {
      _droneSource = await _soloud.loadAsset(
        'assets/audio/drone_root.wav',
        mode: LoadMode.memory,
      );

      _noiseSource = await _soloud.loadAsset(
        'assets/audio/texture_noise.wav',
        mode: LoadMode.disk, // Stream larger background textures
      );
    } catch (e) {
      debugPrint('Failed to load priority beds: $e');
    }

    // Secondary assets loaded without blocking
    _loadSecondaryStems();
  }

  void _loadSecondaryStems() async {
    const chimePaths = [
      'assets/audio/chimes/chime_1.wav',
      'assets/audio/chimes/chime_2.wav',
      'assets/audio/chimes/chime_3.wav',
      'assets/audio/chimes/chime_4.wav',
    ];

    for (final path in chimePaths) {
      try {
        final source = await _soloud.loadAsset(path, mode: LoadMode.memory);
        _chimeSources.add(source);
      } catch (e) {
        debugPrint('Failed to load stem: $path -> $e');
      }
    }
  }

  /// Starts playback with exponential volume ramps to prevent DAC click/pop.
  Future<void> start(SoundscapeMode mode) async {
    if (!_isInitialized) await init();
    if (_isRunning) stop();
    _isRunning = true;

    // 1. Start Drone Layer
    if (_droneSource != null && _isRunning) {
      final handle = await _soloud.play(
        _droneSource!,
        volume: 0.001,
        looping: true,
      );
      _droneHandle = handle;
      _soloud.fadeVolume(handle, 0.5, const Duration(milliseconds: 2500));
    }

    // 2. Start Noise / Bed Layer
    if (_noiseSource != null && _isRunning) {
      final handle = await _soloud.play(
        _noiseSource!,
        volume: 0.001,
        looping: true,
      );
      _noiseHandle = handle;
      _soloud.fadeVolume(handle, 0.15, const Duration(milliseconds: 3000));
    }

    // 3. Initiate Generative Chime Loop
    _scheduleNextChime(mode);
  }

  void _scheduleNextChime(SoundscapeMode mode) {
    if (!_isRunning) return;

    final (minSec, maxSec) = switch (mode) {
      SoundscapeMode.focus => (4, 8),
      SoundscapeMode.relax => (7, 14),
      SoundscapeMode.sleep => (12, 22),
    };

    final interval = minSec + _rng.nextInt(maxSec - minSec + 1);

    _generativeTimer = Timer(Duration(seconds: interval), () {
      _triggerGentleChime();
      _scheduleNextChime(mode);
    });
  }

  void _triggerGentleChime() {
    if (_chimeSources.isEmpty || !_isRunning) return;

    final source = _chimeSources[_rng.nextInt(_chimeSources.length)];
    final targetVol = 0.20 + (_rng.nextDouble() * 0.10);

    _soloud.play(
      source,
      volume: targetVol,
      looping: false,
    );
  }

  /// Modulates intensity smoothly (e.g., linked to sensors or user state).
  void setIntensity(double value) {
    if (_noiseHandle == null) return;
    final targetVolume = (0.05 + (value.clamp(0.0, 1.0) * 0.25));

    _soloud.fadeVolume(
      _noiseHandle!,
      targetVolume,
      const Duration(milliseconds: 300),
    );
  }

  /// Smoothly fades out all active voices before stopping them.
  void stop() {
    _isRunning = false;
    _generativeTimer?.cancel();

    if (_droneHandle != null) {
      _soloud.fadeVolume(_droneHandle!, 0.0, const Duration(milliseconds: 800));
      Future.delayed(const Duration(milliseconds: 850), () {
        if (_droneHandle != null) _soloud.stop(_droneHandle!);
      });
    }

    if (_noiseHandle != null) {
      _soloud.fadeVolume(_noiseHandle!, 0.0, const Duration(milliseconds: 800));
      Future.delayed(const Duration(milliseconds: 850), () {
        if (_noiseHandle != null) _soloud.stop(_noiseHandle!);
      });
    }
  }

  void dispose() {
    stop();
    _soloud.deinit();
  }
}
