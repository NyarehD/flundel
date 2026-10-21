import 'dart:io';

import 'package:flundel/audio/dsp/environmental_layer.dart';
import 'package:flundel/audio/dsp/noise_engine.dart';
import 'package:flundel/audio/dsp/pad_synth.dart';
import 'package:flundel/audio/synthetic_audio.dart';

void main() {
  print('Generating high-fidelity audio asset stems...');

  Directory('assets/audio/chimes').createSync(recursive: true);
  Directory('assets/audio/nature').createSync(recursive: true);
  Directory('assets/audio/pads').createSync(recursive: true);
  Directory('assets/audio/textures').createSync(recursive: true);

  final padSynth = PadSynth();
  padSynth.updateParameters(padLevel: 0.8, detune: 2.0, reverbSendLevel: 0.4, cutoffFrequencyHz: 1200.0);

  final droneBytes = padSynth.generatePadWavBytes(
    baseFrequencies: [110.0, 164.81, 220.0, 261.63], // A2, E3, A3, C4
    durationSeconds: 6.0,
    sampleRate: 48000,
  );
  File('assets/audio/drone_root.wav').writeAsBytesSync(droneBytes);
  File('assets/audio/pads/pad_ambient.wav').writeAsBytesSync(droneBytes);
  print('Generated drone_root.wav & pad_ambient.wav');

  final noiseEngine = NoiseEngine();
  noiseEngine.updateParameters(noiseLevel: 0.6, warmthValue: 0.65, cutoffFrequencyHz: 1400.0);

  final noiseBytes = noiseEngine.generateWavBytes(durationSeconds: 6.0, sampleRate: 48000);
  File('assets/audio/texture_noise.wav').writeAsBytesSync(noiseBytes);
  print('Generated texture_noise.wav');

  final chime1 = SyntheticAudio.createTranquilChimeWavBytes(freqHz: 523.25, durationSeconds: 3.0, sampleRate: 48000); // C5
  final chime2 = SyntheticAudio.createTranquilChimeWavBytes(freqHz: 659.25, durationSeconds: 3.0, sampleRate: 48000); // E5
  final chime3 = SyntheticAudio.createTranquilChimeWavBytes(freqHz: 783.99, durationSeconds: 3.0, sampleRate: 48000); // G5
  final chime4 = SyntheticAudio.createTranquilChimeWavBytes(freqHz: 987.77, durationSeconds: 3.0, sampleRate: 48000); // B5

  File('assets/audio/chimes/chime_1.wav').writeAsBytesSync(chime1);
  File('assets/audio/chimes/chime_2.wav').writeAsBytesSync(chime2);
  File('assets/audio/chimes/chime_3.wav').writeAsBytesSync(chime3);
  File('assets/audio/chimes/chime_4.wav').writeAsBytesSync(chime4);
  print('Generated chime stems (1 to 4)');

  final env = EnvironmentalLayer();
  env.updateParameters(natureLevel: 0.7);
  final rainBytes = env.generateRainWavBytes(durationSeconds: 6.0, sampleRate: 48000);
  File('assets/audio/nature/rain_loop.wav').writeAsBytesSync(rainBytes);
  print('Generated rain_loop.wav');

  print('Audio asset generation complete!');
}
