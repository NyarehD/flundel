import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flundel/domain/models/soundscape_config.dart';
import 'package:flundel/audio/procedural/procedural_controller.dart';
import 'package:flundel/audio/dsp/noise_engine.dart';
import 'package:flundel/audio/dsp/pad_synth.dart';
import 'package:flundel/audio/dsp/binaural_generator.dart';
import 'package:flundel/audio/dsp/environmental_layer.dart';
import 'package:flundel/audio/dsp/audio_bus.dart';

class OfflineRenderResult {
  final Uint8List wavBytes;
  final int totalSamples;
  final double durationSeconds;
  final int pianoEventsTriggered;

  const OfflineRenderResult({
    required this.wavBytes,
    required this.totalSamples,
    required this.durationSeconds,
    required this.pianoEventsTriggered,
  });
}

class OfflineRenderer {
  /// Offline procedural audio rendering tool for automated testing and quality inspection.
  static OfflineRenderResult renderAudio({
    required SoundscapeConfig config,
    required int sessionSeed,
    double durationSeconds = 30.0,
    int sampleRate = 44100,
  }) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final dataSize = numSamples * 4; // Stereo 16-bit
    final fileSize = 36 + dataSize;

    final bytes = Uint8List(44 + dataSize);
    final bd = ByteData.sublistView(bytes);

    _writeWavHeader(bd, bytes, fileSize, dataSize, channels: 2, sampleRate: sampleRate);

    final procedural = ProceduralController()..initialize(sessionSeed, config);
    final noise = NoiseEngine();
    final pad = PadSynth();
    final binaural = BinauralGenerator();
    final env = EnvironmentalLayer();
    final bus = AudioBus();

    int pianoEventsCount = 0;
    int offset = 44;

    const controlTickSamples = 882; // ~20ms control tick at 44.1kHz
    double currentTime = 0.0;

    for (int i = 0; i < numSamples; i += controlTickSamples) {
      final tickDuration = min(controlTickSamples, numSamples - i) / sampleRate;
      currentTime += tickDuration;

      procedural.tick(tickDuration, config);

      final event = procedural.checkAndGeneratePianoEvent(
        currentTimeSeconds: currentTime,
        config: config,
      );
      if (event != null) {
        pianoEventsCount++;
      }

      noise.updateParameters(
        noiseLevel: config.noise * config.intensity,
        warmthValue: config.warmth,
        cutoffFrequencyHz: procedural.noiseCutoffHz,
      );

      pad.updateParameters(
        padLevel: config.pad * config.intensity,
        detune: procedural.padDetuneCents,
        reverbSendLevel: bus.reverbBusSend.value,
      );

      binaural.updateParameters(
        level: config.binaural * config.intensity,
        carrierFrequency: 180.0,
        differenceHz: 10.0,
      );

      env.updateParameters(natureLevel: config.nature * config.intensity);

      // Render block of audio samples
      final blockSamples = min(controlTickSamples, numSamples - i);
      for (int s = 0; s < blockSamples; s++) {
        final t = (i + s) / sampleRate;

        // Tonal signal
        final chord = procedural.harmonyController.currentChord.chordFrequencies;
        final padSample = sin(2 * pi * chord.first * t) * pad.volume.value * 0.4;
        final binSample = sin(2 * pi * 180.0 * t) * binaural.volume.value * 0.3;

        // Texture signal
        final noiseSample = ((Random(i + s).nextDouble() * 2.0) - 1.0) * noise.volume.value * 0.3;

        final rawCombined = (padSample + binSample + noiseSample);
        final limited = bus.applyMasterLimiter(rawCombined);

        final sampleVal = (limited * 32000.0).toInt().clamp(-32768, 32767);

        bd.setInt16(offset, sampleVal, Endian.little);
        bd.setInt16(offset + 2, sampleVal, Endian.little);
        offset += 4;
      }
    }

    return OfflineRenderResult(
      wavBytes: bytes,
      totalSamples: numSamples,
      durationSeconds: durationSeconds,
      pianoEventsTriggered: pianoEventsCount,
    );
  }

  static void _writeWavHeader(
    ByteData bd,
    Uint8List bytes,
    int fileSize,
    int dataSize, {
    required int channels,
    required int sampleRate,
  }) {
    bytes.setRange(0, 4, ascii.encode('RIFF'));
    bd.setUint32(4, fileSize, Endian.little);
    bytes.setRange(8, 12, ascii.encode('WAVE'));

    bytes.setRange(12, 16, ascii.encode('fmt '));
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, channels, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * channels * 2, Endian.little);
    bd.setUint16(32, channels * 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);

    bytes.setRange(36, 40, ascii.encode('data'));
    bd.setUint32(40, dataSize, Endian.little);
  }
}
