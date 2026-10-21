import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flundel/audio/audio_analysis.dart';
import 'package:flundel/visualization/painters/soundscape_painter.dart';
import 'package:flundel/visualization/visualization_engine.dart';

Future<Uint8List> _rasterize(
  String presetId,
  VisualizationSignals signals,
) async {
  final repaint = ChangeNotifier();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  SoundscapePainter(
    presetId: presetId,
    signals: signals,
    repaint: repaint,
  ).paint(canvas, const Size(180, 220));
  final picture = recorder.endRecording();
  final image = await picture.toImage(180, 220);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = Uint8List.fromList(
    byteData!.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    ),
  );
  image.dispose();
  picture.dispose();
  repaint.dispose();
  return bytes;
}

class _FixedSignals implements VisualizationSignals {
  const _FixedSignals({
    required this.elapsedSeconds,
    required this.motionSeconds,
    this.texture = 0.35,
    this.pianoPulse = 0,
  });

  @override
  final double elapsedSeconds;
  @override
  final double motionSeconds;
  @override
  double get amplitude => 0.3;
  @override
  double get tonal => 0.4;
  @override
  final double texture;
  @override
  double get piano => 0.2;
  @override
  final double pianoPulse;
  @override
  double get focus => 0.9;
  @override
  double get detail => 0.5;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the built-in presets paint distinct monochrome patterns', () async {
    const presetIds = [
      'deep_work',
      'coding',
      'reading',
      'quiet_focus',
      'piano_focus',
      'night_focus',
      'ocean_drift',
      'zen_meditation',
      'lofi_study',
      'forest_stream',
    ];
    final images = <String>[];

    for (final presetId in presetIds) {
      final model = VisualizationModel()..advance(0.08);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      SoundscapePainter(
        presetId: presetId,
        signals: model,
        repaint: model,
      ).paint(canvas, const Size(180, 220));
      final picture = recorder.endRecording();
      final image = await picture.toImage(180, 220);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      images.add(String.fromCharCodes(bytes!.buffer.asUint8List()));
      image.dispose();
      picture.dispose();
      model.dispose();
    }

    expect(images.toSet(), hasLength(presetIds.length));
  });

  test(
    'reading tiles cover portrait corners after the centered rotation',
    () async {
      const width = 180;
      const height = 220;
      const cornerWidth = 44;
      const cornerHeight = 54;
      final pixels = await _rasterize(
        'reading',
        const _FixedSignals(elapsedSeconds: 2.4, motionSeconds: 2.4),
      );

      for (final corner in [
        (0, 0),
        (width - cornerWidth, 0),
        (0, height - cornerHeight),
        (width - cornerWidth, height - cornerHeight),
      ]) {
        var litPixels = 0;
        for (var y = corner.$2; y < corner.$2 + cornerHeight; y++) {
          for (var x = corner.$1; x < corner.$1 + cornerWidth; x++) {
            if (pixels[(y * width + x) * 4] > 8) litPixels++;
          }
        }
        expect(
          litPixels,
          greaterThan(80),
          reason: 'reading tiles should cover corner ${corner.$1},${corner.$2}',
        );
      }
    },
  );

  test('all preset families visibly evolve over three seconds', () async {
    const presetIds = [
      'deep_work',
      'coding',
      'reading',
      'quiet_focus',
      'piano_focus',
      'night_focus',
      'ocean_drift',
      'zen_meditation',
      'lofi_study',
      'forest_stream',
    ];

    for (final presetId in presetIds) {
      final model = VisualizationModel();
      model.accept(
        const AudioAnalysis(
          amplitude: 0.04,
          tonalEnergy: 0.05,
          textureEnergy: 0.01,
          pianoActivity: 0,
          focusDepth: 0.85,
        ),
        motionEnabled: false,
      );
      model.setMotionEnabled(true);
      final start = await _rasterize(presetId, model);
      for (var frame = 0; frame < 30; frame++) {
        model.advance(0.1);
      }
      final later = await _rasterize(presetId, model);
      var changedPixels = 0;
      for (var pixel = 0; pixel < start.length; pixel += 4) {
        if ((start[pixel] - later[pixel]).abs() > 8) changedPixels++;
      }
      expect(
        changedPixels,
        greaterThan(40),
        reason: '$presetId should show visible motion within three seconds',
      );
      model.dispose();
    }
  });

  test('painter motion follows the focus-weighted phase clock', () async {
    final deepFocusPhase = await _rasterize(
      'coding',
      const _FixedSignals(elapsedSeconds: 1.95, motionSeconds: 3),
    );
    final fullPhase = await _rasterize(
      'coding',
      const _FixedSignals(elapsedSeconds: 3, motionSeconds: 3),
    );
    var changedPixels = 0;
    for (var pixel = 0; pixel < deepFocusPhase.length; pixel += 4) {
      if ((deepFocusPhase[pixel] - fullPhase[pixel]).abs() > 8) {
        changedPixels++;
      }
    }
    expect(changedPixels, greaterThan(40));
  });

  test('small level changes stay bounded after long elapsed time', () async {
    const quarterFramePixels = 180 * 220 ~/ 4;
    for (final presetId in ['deep_work', 'coding', 'quiet_focus']) {
      Future<int> signalDeltaAt(double elapsedSeconds) async {
        final lower = await _rasterize(
          presetId,
          _FixedSignals(
            elapsedSeconds: elapsedSeconds,
            motionSeconds: elapsedSeconds,
            texture: 0.5,
            pianoPulse: 0.5,
          ),
        );
        final higher = await _rasterize(
          presetId,
          _FixedSignals(
            elapsedSeconds: elapsedSeconds,
            motionSeconds: elapsedSeconds,
            texture: 0.51,
            pianoPulse: 0.51,
          ),
        );
        var changed = 0;
        for (var pixel = 0; pixel < lower.length; pixel += 4) {
          if ((lower[pixel] - higher[pixel]).abs() > 8) changed++;
        }
        return changed;
      }

      final longSessionDelta = await signalDeltaAt(600);
      expect(
        longSessionDelta,
        lessThan(quarterFramePixels),
        reason:
            '$presetId small signal changes should stay below a quarter-frame jump',
      );
    }
  });

  test(
    'reduced motion keeps patterns static and discards piano events',
    () async {
      final model = VisualizationModel()..setMotionEnabled(false);
      model.accept(
        const AudioAnalysis(
          amplitude: 0.4,
          tonalEnergy: 0.6,
          textureEnergy: 0.3,
          pianoActivity: 0.8,
          focusDepth: 0.7,
          hasPianoEvent: true,
        ),
        motionEnabled: false,
      );
      final before = await _rasterize('reading', model);
      for (var frame = 0; frame < 30; frame++) {
        model.advance(0.1);
      }
      final after = await _rasterize('reading', model);

      expect(model.motionSeconds, 0);
      expect(model.elapsedSeconds, 0);
      expect(model.pianoPulse, 0);
      expect(after, orderedEquals(before));
      model.dispose();
    },
  );

  test('analysis is smoothed and piano events decay to a bounded pulse', () {
    final model = VisualizationModel();
    model.setMotionEnabled(true);
    model.accept(
      const AudioAnalysis(
        amplitude: 1,
        tonalEnergy: 0.8,
        textureEnergy: 0.7,
        pianoActivity: 0.4,
        focusDepth: 0.9,
        hasPianoEvent: true,
      ),
      motionEnabled: true,
    );

    expect(model.amplitude, lessThan(1));
    expect(model.piano, lessThanOrEqualTo(1));
    final eventPulse = model.piano;
    model.advance(0.08);
    expect(model.elapsedSeconds, greaterThan(0));
    expect(model.piano, lessThan(eventPulse));

    for (var i = 0; i < 120; i++) {
      model.advance(0.08);
    }
    expect(model.piano, closeTo(0.4, 0.01));
    model.dispose();
  });

  test('stopping motion clears event pulses without replaying them', () {
    final model = VisualizationModel()..setMotionEnabled(true);
    model.accept(
      const AudioAnalysis(
        amplitude: 0.4,
        tonalEnergy: 0.4,
        textureEnergy: 0.2,
        pianoActivity: 0.1,
        focusDepth: 0.5,
        hasPianoEvent: true,
      ),
      motionEnabled: true,
    );
    expect(model.piano, greaterThan(0.6));

    model.setMotionEnabled(false);
    expect(model.piano, lessThan(0.2));
    model.setMotionEnabled(true);
    expect(model.piano, lessThan(0.2));
    model.dispose();
  });

  test('focus depth slows phase time and reduces pattern detail', () {
    AudioAnalysis analysisWithFocus(double focusDepth) => AudioAnalysis(
      amplitude: 0.3,
      tonalEnergy: 0.3,
      textureEnergy: 0.3,
      pianoActivity: 0,
      focusDepth: focusDepth,
    );

    final settling = VisualizationModel();
    settling.accept(analysisWithFocus(0), motionEnabled: false);
    settling.setMotionEnabled(true);
    settling.advance(0.08);

    final deepFocus = VisualizationModel();
    deepFocus.accept(analysisWithFocus(0.9), motionEnabled: false);
    deepFocus.setMotionEnabled(true);
    deepFocus.advance(0.08);

    expect(deepFocus.elapsedSeconds, lessThan(settling.elapsedSeconds));
    expect(deepFocus.detail, lessThan(settling.detail));
    settling.dispose();
    deepFocus.dispose();
  });

  test(
    'unknown presets fall back to a regular grid and signals stay bounded',
    () async {
      final model = VisualizationModel()..setMotionEnabled(true);
      model.accept(
        const AudioAnalysis(
          amplitude: double.nan,
          tonalEnergy: double.infinity,
          textureEnergy: double.negativeInfinity,
          pianoActivity: double.nan,
          focusDepth: double.infinity,
          hasPianoEvent: true,
        ),
        motionEnabled: true,
      );
      model.advance(double.nan);
      expect(model.amplitude.isFinite, isTrue);
      expect(model.tonal.isFinite, isTrue);
      expect(model.texture.isFinite, isTrue);
      expect(model.piano.isFinite, isTrue);
      expect(model.focus.isFinite, isTrue);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      SoundscapePainter(
        presetId: 'unrecognized',
        signals: model,
        repaint: model,
      ).paint(canvas, const Size(180, 220));
      final picture = recorder.endRecording();
      final image = await picture.toImage(180, 220);
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      expect(
        List.generate(
          bytes.length ~/ 4,
          (index) => bytes[index * 4],
        ).any((red) => red > 5),
        isTrue,
      );
      image.dispose();
      picture.dispose();
      model.dispose();
    },
  );
}
