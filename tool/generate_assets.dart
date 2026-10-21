import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flundel/audio/dsp/environmental_layer.dart';
import 'package:flundel/audio/dsp/noise_engine.dart';
import 'package:flundel/audio/dsp/pad_synth.dart';
import 'package:flundel/audio/synthetic_audio.dart';
import 'package:flundel/audio/procedural/harmony_controller.dart';

void main() {
  stdout.writeln('Generating deterministic Flundel audio assets...');

  Directory('assets/audio/chimes').createSync(recursive: true);
  Directory('assets/audio/piano').createSync(recursive: true);
  Directory('assets/audio/nature').createSync(recursive: true);
  Directory('assets/audio/pads').createSync(recursive: true);
  Directory('assets/audio/textures').createSync(recursive: true);

  final padSynth = PadSynth();
  padSynth.updateParameters(
    padLevel: 0.8,
    detune: 2.0,
    reverbSendLevel: 0.4,
    cutoffFrequencyHz: 1200.0,
  );
  padSynth.detuneCents.setImmediate(2.0);
  padSynth.cutoffHz.setImmediate(1200.0);

  final droneBytes = padSynth.generatePadWavBytes(
    baseFrequencies: [110.0, 164.81, 220.0, 261.63], // A2, E3, A3, C4
    durationSeconds: 6.0,
    sampleRate: 48000,
    gainMultiplier: 2.5,
  );
  File('assets/audio/drone_root.wav')
      .writeAsBytesSync(_calibrateWav(droneBytes));
  File('assets/audio/pads/pad_ambient.wav')
      .writeAsBytesSync(_calibrateWav(droneBytes));
  Directory('assets/audio/pads/chords').createSync(recursive: true);
  for (final entry in HarmonyController.chords.entries) {
    final chordBytes = padSynth.generatePadWavBytes(
      baseFrequencies: entry.value.chordFrequencies,
      durationSeconds: 6.0,
      sampleRate: 48000,
      gainMultiplier: 2.5,
    );
    File('assets/audio/pads/chords/${entry.key.name}.wav')
        .writeAsBytesSync(_calibrateWav(chordBytes));
  }
  stdout.writeln('Generated drone_root.wav & pad_ambient.wav');

  final noiseEngine = NoiseEngine();
  noiseEngine.updateParameters(
    noiseLevel: 0.6,
    warmthValue: 0.65,
    cutoffFrequencyHz: 1400.0,
  );
  noiseEngine.warmth.setImmediate(0.65);
  noiseEngine.cutoffHz.setImmediate(1400.0);

  final noiseBytes = noiseEngine.generateWavBytes(
    durationSeconds: 6.0,
    sampleRate: 48000,
    gainMultiplier: 8.0,
  );
  File('assets/audio/texture_noise.wav')
      .writeAsBytesSync(_calibrateWav(noiseBytes));
  stdout.writeln('Generated texture_noise.wav');

  final chime1 = SyntheticAudio.createTranquilChimeWavBytes(
    freqHz: 523.25,
    durationSeconds: 3.0,
    sampleRate: 48000,
  ); // C5
  final chime2 = SyntheticAudio.createTranquilChimeWavBytes(
    freqHz: 659.25,
    durationSeconds: 3.0,
    sampleRate: 48000,
  ); // E5
  final chime3 = SyntheticAudio.createTranquilChimeWavBytes(
    freqHz: 783.99,
    durationSeconds: 3.0,
    sampleRate: 48000,
  ); // G5
  final chime4 = SyntheticAudio.createTranquilChimeWavBytes(
    freqHz: 987.77,
    durationSeconds: 3.0,
    sampleRate: 48000,
  ); // B5

  File('assets/audio/chimes/chime_1.wav').writeAsBytesSync(
    _calibrateWav(chime1, targetRmsDbfs: -26, loopSeamless: false),
  );
  File('assets/audio/chimes/chime_2.wav').writeAsBytesSync(
    _calibrateWav(chime2, targetRmsDbfs: -26, loopSeamless: false),
  );
  File('assets/audio/chimes/chime_3.wav').writeAsBytesSync(
    _calibrateWav(chime3, targetRmsDbfs: -26, loopSeamless: false),
  );
  File('assets/audio/chimes/chime_4.wav').writeAsBytesSync(
    _calibrateWav(chime4, targetRmsDbfs: -26, loopSeamless: false),
  );
  final pianoNotes = <double>[523.25, 659.25, 783.99, 987.77];
  for (var i = 0; i < pianoNotes.length; i++) {
    File('assets/audio/piano/note_${i + 1}.wav').writeAsBytesSync(
      _calibrateWav(
        SyntheticAudio.createTranquilChimeWavBytes(
          freqHz: pianoNotes[i],
          durationSeconds: 2.8,
          sampleRate: 48000,
          softPiano: true,
        ),
        targetRmsDbfs: -27,
        loopSeamless: false,
      ),
    );
  }
  Directory('assets/audio/completion').createSync(recursive: true);
  File('assets/audio/completion/gentle_completion.wav').writeAsBytesSync(
    _calibrateWav(
      SyntheticAudio.createTranquilChimeWavBytes(
        freqHz: 659.25,
        durationSeconds: 2.4,
        sampleRate: 48000,
      ),
      targetRmsDbfs: -30,
      peakCeiling: 0.35,
      loopSeamless: false,
    ),
  );
  stdout.writeln(
    'Generated four chimes and the separate gentle completion cue',
  );

  final env = EnvironmentalLayer();
  env.updateParameters(natureLevel: 0.7);
  env.volume.setImmediate(0.7);
  final rainBytes = env.generateRainWavBytes(
    durationSeconds: 6.0,
    sampleRate: 48000,
    gainMultiplier: 13.0,
  );
  File('assets/audio/nature/rain_loop.wav')
      .writeAsBytesSync(_calibrateWav(rainBytes));
  stdout.writeln('Generated rain_loop.wav');

  stdout.writeln(
    'Audio asset generation complete. Run python3 tool/validate_audio_assets.py --write-manifest.',
  );
}

Uint8List _calibrateWav(
  Uint8List bytes, {
  double targetRmsDbfs = -24,
  double peakCeiling = 0.72,
  bool loopSeamless = true,
}) {
  if (loopSeamless) {
    bytes = _crossfadeLoop(bytes);
  }
  final data = ByteData.sublistView(bytes);
  final channels = data.getUint16(22, Endian.little);
  final bits = data.getUint16(34, Endian.little);
  if (channels != 2 || bits != 16) {
    throw const FormatException('Expected stereo 16-bit PCM');
  }
  final count = (bytes.length - 44) ~/ 2;
  final means = List<double>.filled(channels, 0);
  final peaks = List<double>.filled(channels, 0);
  for (var frame = 0; frame < count ~/ channels; frame++) {
    for (var channel = 0; channel < channels; channel++) {
      final value =
          data.getInt16(
            44 + ((frame * channels + channel) * 2),
            Endian.little,
          ) /
          32768;
      means[channel] += value;
    }
  }
  final frames = count ~/ channels;
  for (var channel = 0; channel < channels; channel++) {
    means[channel] /= frames;
  }
  var sumSquares = 0.0;
  for (var frame = 0; frame < frames; frame++) {
    for (var channel = 0; channel < channels; channel++) {
      final offset = 44 + ((frame * channels + channel) * 2);
      final value =
          data.getInt16(offset, Endian.little) / 32768 - means[channel];
      sumSquares += value * value;
      peaks[channel] = max(peaks[channel], value.abs());
    }
  }
  final rms = sqrt(sumSquares / count);
  final peak = peaks.reduce(max);
  if (rms == 0 || peak == 0) {
    throw const FormatException('Audio asset is silent');
  }
  final targetRms = pow(10, targetRmsDbfs / 20).toDouble();
  final gain = min(targetRms / rms, peakCeiling / peak);
  for (var frame = 0; frame < frames; frame++) {
    for (var channel = 0; channel < channels; channel++) {
      final offset = 44 + ((frame * channels + channel) * 2);
      final value =
          (data.getInt16(offset, Endian.little) / 32768 - means[channel]) *
          gain;
      data.setInt16(
        offset,
        (value * 32767).round().clamp(-32768, 32767),
        Endian.little,
      );
    }
  }
  return bytes;
}

Uint8List _crossfadeLoop(Uint8List bytes) {
  final source = ByteData.sublistView(bytes);
  final channels = source.getUint16(22, Endian.little);
  final bits = source.getUint16(34, Endian.little);
  final rate = source.getUint32(24, Endian.little);
  if (channels != 2 || bits != 16) {
    throw const FormatException('Expected stereo 16-bit PCM');
  }
  final frameCount = (bytes.length - 44) ~/ (channels * 2);
  final fadeFrames = min((rate * 0.30).round(), frameCount ~/ 5);
  final middleFrames = frameCount - 2 * fadeFrames;
  final outputFrames = middleFrames + fadeFrames;
  final result = Uint8List(44 + outputFrames * channels * 2);
  result.setRange(0, 44, bytes);
  final out = ByteData.sublistView(result);
  out.setUint32(4, result.length - 8, Endian.little);
  out.setUint32(40, result.length - 44, Endian.little);
  for (var frame = 0; frame < middleFrames; frame++) {
    for (var channel = 0; channel < channels; channel++) {
      final sample = source.getInt16(
        44 + ((frame + fadeFrames) * channels + channel) * 2,
        Endian.little,
      );
      out.setInt16(
        44 + (frame * channels + channel) * 2,
        sample,
        Endian.little,
      );
    }
  }
  for (var frame = 0; frame < fadeFrames; frame++) {
    final progress = frame / max(1, fadeFrames - 1);
    final fadeOut = cos(progress * pi / 2);
    final fadeIn = sin(progress * pi / 2);
    for (var channel = 0; channel < channels; channel++) {
      final tail = source.getInt16(
        44 + ((frameCount - fadeFrames + frame) * channels + channel) * 2,
        Endian.little,
      );
      final head = source.getInt16(
        44 + (frame * channels + channel) * 2,
        Endian.little,
      );
      final mixed = (tail * fadeOut + head * fadeIn).round().clamp(
        -32768,
        32767,
      );
      out.setInt16(
        44 + ((middleFrames + frame) * channels + channel) * 2,
        mixed,
        Endian.little,
      );
    }
  }
  return result;
}
