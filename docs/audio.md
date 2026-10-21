# Audio assets and playback verification

## Asset workflow

The bundled soundscape is original, deterministic synthesis from this repository; it contains no downloaded recordings or NCS music. `assets/audio/provenance.json` records the generated files, hashes, measured loudness, peak level, DC offset, loop seam, generator description, and any later imports. Regenerate the synthesized layers and validate their manifest with:

```sh
dart run tool/generate_assets.dart
python3 tool/validate_audio_assets.py --write-manifest
python3 tool/validate_audio_assets.py
```

To import audio, first verify that the license permits embedding and redistributing the file in this app. The importer converts with ffmpeg to stereo 48 kHz PCM16, removes DC, targets -24 dBFS RMS subject to a -1 dBFS peak ceiling, and can prepare a circular loop crossfade. It records the source hash, URL, license, attribution, conversion, and measured output in `provenance.json`:

```sh
python3 tool/import_audio_asset.py source.wav nature/new_loop.wav \
  --license 'CC0-1.0' --source-url 'https://example.org/asset' \
  --attribution 'Author, if required' --loop-crossfade-ms 300
python3 tool/validate_audio_assets.py --write-manifest
python3 tool/validate_audio_assets.py
```

Use `--output-dir /tmp/audio-import-check` to exercise the importer without changing bundled assets. Do not import audio unless the exact app-distribution rights and attribution requirements are clear. The optional [CC0 rain candidate](https://freesound.org/people/Rvgerxini/sounds/527658/) was not downloaded; the app keeps its generated rain layer. NCS tracks are also not bundled because permission for app distribution has not been confirmed. Review the current [NCS Usage Policy](https://ncs.io/usage-policy) and [NCS contact page](https://ncs.io/contact) for uses outside its creator policy before considering a track.

## Playback and preview

Playback, soundscape buses, and the debug capture use `flutter_soloud` 5.2.1. `lib/audio/soloud_bus_meter_adapter.dart` isolates the version-pinned native bus-visualization binding required to read actual bus meters; update and recheck this adapter when changing the package version. `OfflineRenderer` is a legacy synthetic fixture renderer. Its output is not evidence of the live engine's routing, effects, limiter, or sound quality.

Piano phrases are deterministic and drawn from the current chord and passing-note vocabulary. Deep Work uses four-note phrases with a 2–4 second first entrance and roughly 8–12 second phrase starts; Piano Focus uses five-note phrases, and Quiet Focus remains sparse. The engine caps piano polyphony at eight source voices.

Lo-fi drums and a chord-following bassline use separate level controls. Rhythm loops are original four-bar PCM stems generated deterministically from the session seed on a worker isolate. Drum and bass stems use the same exact frame count and are scheduled together on SoLoud's absolute mixer clock; hit timing does not depend on Dart timers. Authored BPMs are Deep Work 72, Coding 84, Reading 68, Piano Focus 76, and Quiet/Night Focus 72. Tempo has no user control and is fixed for a session. Bass chord sources share the same groove and are phase-seeked before a scheduled native crossfade, so chord changes retain the drum transport phase. Pause stops active and pending rhythm voices and resumes both layers from the saved loop phase; completion cancels transitions and fades/stops rhythm before its cue. Beats and bass have separate dry buses for independent live level/mute/solo handling.

The rhythm engine's worst case is eighteen source voices (including two overlapping bass voices during a chord transition) plus four mixer-bus voices, or 22 active voices. SoLoud is configured for 24, leaving two voices of headroom. Diagnostics report both bus meters, BPM and transport phase.

For an actual engine preview, open the in-app Debug Audio screen, select **Start preview session**, then **Capture actual mixer preview**. The captured stereo PCM comes from SoLoud's output capture callback and is exported as a WAV under the system temporary directory; the screen shows the file path. Check that the file is non-silent, unclipped, and has the expected 48 kHz stereo format. The diagnostic peak is the measured output peak in dBFS; tonal and texture levels are native bus meters, gated/scaled by the master output level. Select **Stop preview session** when done.

## Native lifecycle checks

On Android and iOS simulators/devices, verify each item with both a short session and a session long enough to background the app:

- Start playback, lock the screen, and confirm audio continues with lock-screen play/pause controls.
- Pause and resume from the lock screen; confirm both sound and the session timer pause/resume together.
- Stop and complete a session; confirm media controls become idle and the optional completion cue plays only on automatic completion.
- Trigger an audio interruption (for example, a phone call or system audio focus change); confirm playback and timer pause together. Confirm automatic resume only when playback was active before a temporary interruption and the user did not manually pause.
- Disconnect headphones; confirm the app pauses and does not resume unexpectedly when the headset is reconnected.
- Resume in the app and verify that mute, master level, layer controls, and the completion-cue preference remain effective.

Build success and unit tests do not replace these device lifecycle checks. Record simulator/device, OS version, actions, and observed media/timer behavior when completing them.
