# Continuous audio system

## Production path

`AudioEngine` remains the app-facing API. `AudioEngineImpl` delegates composition and DSP to a persistent `RenderWorker` isolate, transport ordering to `PlaybackLifecycle`, and native playback to `NativeStreamMixer`. `OfflineRenderer` and the validation tool use the **same** `CompositionPlanner` and `SoundscapeRenderer` as playback. The implementation contains original procedural audio and requires no network, sensor permissions, or external sound library.

The renderer produces 48 kHz stereo float PCM in 4,096-frame blocks (85.33 ms). Oscillator phases, filters, envelopes, random streams, pending events, chord crossfades, and reverb delay lines survive block boundaries. Absolute sample positions schedule events; a 100 Hz composition grid makes decisions independent of block sizes. Harmony, rhythm, melody, ambience, and texture synthesis have separate seeded random state. Muting changes native gain without changing future composition.

The native adapter uses eleven released streaming buffers under one parent SoLoud bus: pads, piano, chimes, noise, nature, wind, water, birds, rhythm, bass, and binaural. Each buffer has a three-second hard limit; the normal preparation target is one second. One native parent pause freezes all stems. The bus uses `48000 / 44100` relative speed because SoLoud 5.2.1 creates bus voices with a 44.1 kHz base rate. This selects the intended 48 kHz child mixer rate. The refill timer never schedules notes.

A 180 ms native fade applies layer levels, mute, solo, and master changes. Synthesis updates reach the next block after the existing approximately one-second queue. Session activity and depth approach their targets over 20 and 15 seconds. Pads crossfade chords over six seconds with nearest-register voice leading. Unplayed melodic notes follow a new chord; sounding voices retain their release tails. Bass follows the same chord and rhythm timeline. Event voices are bounded (eight piano voices, two per other event kind), with twelve native handles during ordinary playback: eleven stems plus the parent.

## Authored arrangements and gain staging

Preset IDs and persisted user levels are unchanged. The built-in config supplies the layer balance; `ArrangementProfile` supplies musical limits:

| Preset | Character | Base chord hold | Base phrase spacing |
| --- | --- | ---: | ---: |
| Deep Work | Warm sustained pads, restrained pulses | 42 s | 16 s |
| Coding | More active pulses and harmonic movement | 32 s | 12 s |
| Reading | Sparse melodic phrasing | 36 s | 15 s |
| Quiet Focus | Narrow, minimal movement | 58 s | 38 s |
| Piano Focus | Three-note piano phrases, wider register | 34 s | 7 s |
| Night Focus | Lower register, very slow movement | 60 s | 32 s |
| Ocean Drift | Flowing textures, broad slow movement | 52 s | 34 s |
| Zen Meditation | Spacious sustained harmony | 56 s | 26 s |
| Lo-Fi Study | Recognizable kick, snare, hats, and bass | 30 s | 13 s |
| Forest Stream | Water, wind, birds, and sparse harmony | 48 s | 25 s |

Actual spacing evolves with seeded decisions and session phase. Deep Work and Coding have a fixed 1.15 pad-presence balance. Pad synthesis includes a phase-continuous lower-octave foundation and gentle even/odd harmonics, with fixed soft saturation containing coincident chord peaks. Focus profiles attenuate continuous textures (Deep Work 0.15, Coding 0.20, Quiet/Night Focus 0.12); Ocean Drift and Forest Stream retain full environmental texture. A warmth-dependent low-pass filter suppresses upper-frequency hiss in the noise bed. These source balances preserve stored control values and never compensate for muting or attenuation. Profiles also constrain register, stereo width, modulation, brightness, pulse density, and environmental motion. BPM and rhythm voice are fixed during an active session; changing presets starts a new composition.

Pads and melodic stems have separate diffuse spaces. Bass and binaural carriers remain dry; the binaural left and right carriers never enter the reverb. Source amplitude and `AudioMixPolicy` provide explicit attenuation, followed by a 0.82 parent gain and the user's master gain (default 0.9). The final native limiter has a -6 dB threshold and -1 dB ceiling as protection. There is no normalization or automatic gain compensation after a user lowers a control. New native voices start at zero and fade to their requested levels.

## Lifecycle and recovery

Start, configuration, pause, resume, stop, completion, and recovery are serialized. Session epochs reject renders from a stopped/replaced session; synthesis revisions reject older configuration updates. The session timer and audible musical events use **consumed native frames**, not render-ahead frames or wall-clock time. Wind-down lasts until the true session end; endless sessions stay in sustained deep focus.

A low buffer pauses the parent transport before refilling. An actual underrun or stem skew additionally reconstructs the worker from a consumed-position checkpoint and recreates all native streams together. Time spent buffering does not count toward the focus session. Rendering failures pause playback and notify the session controller.

The worker retains 32 bounded block-start snapshots (2.73 seconds). A checkpoint reconstructs the exact consumed frame from the latest earlier snapshot, including DSP tails. The session controller persists every four consumed seconds (leaving margin for the five-second recovery target), on pause, and on inactive/background transitions. Hive flushes each saved checkpoint and compacts after eight obsolete records. Stored envelopes include the config, seed, checkpoint version, musical/DSP state, and consumed position.

Reopening always prepares audio **paused**. Downtime is not added to progress. Legacy sessions keep their settings and receive reconstructed DSP state; unsupported checkpoint schemas retain their consumed position. A device startup failure preserves the durable session so Play can retry. Engine disposal closes native streams, sources, subscriptions, callbacks, and the isolate. The five-second abrupt-termination target assumes checkpoint writes are succeeding; persistent storage failures cannot provide that guarantee.

## Validation commands

```sh
flutter test --no-pub
flutter analyze --no-pub
# Three minutes per preset, bounded-memory WAV writing and JSON metrics:
dart compile exe tool/validate_streaming_audio.dart -o build/validate_streaming_audio
build/validate_streaming_audio 180 build/audio-validation
# Every source and master at maximum, without the native limiter:
build/validate_streaming_audio 180 build/audio-validation/max-levels --max-levels
# Actual native mixer capture and lifecycle probe:
flutter run --no-pub -d <device-id> -t tool/focus_audio_probe.dart \
  --dart-define=AUDIO_SOAK_SECONDS=1800
```

Native preview capture converts callback PCM directly into one preallocated PCM16 WAV, bounded to 60 seconds (11,520,044 bytes), without retaining a float copy. The native probe captures post-mixer WAVs, checks all ten presets, zero-intensity silence, a forced slow producer, synchronized pause/resume, consumed-position checkpoints, paused restoration, repeated session cleanup, completion, buffer limits, and a 30-minute soak. It writes `report.json` only after success, `progress.json` during the soak, and `failure.json` on failure. `STREAM_PROBE_PASS` identifies its temporary output directory. Process RSS is recorded separately from native audio buffer bytes; process RSS includes Flutter, the VM, and graphics and is not an audio-owned allocation measurement.

Capture uses threshold notifications that drain the available batch. SoLoud 5.2.1 fixed-size PCM notifications can leave their notification latch set when an Android device callback supplies more than one chunk. The application avoids that path without modifying the package cache.

Tests cover arbitrary block boundaries, exact JSON continuation, independent muted layers, gain/solo behavior, isolated binaural channels, bounded voices, coordinated harmonic transitions, stale synthesis revisions, worker checkpoints, old schema reconstruction, paused restoration, device failure retry, and true-end phases. The long-render validator additionally checks finite/unclipped PCM, mono retention, discontinuities at block boundaries, and rendering cost.

## Assets and acceptance evidence

`pubspec.yaml` no longer bundles the large audio loops, and the production engine does not load them. Existing generated WAVs, provenance, import/generation tools, and their fixture tests remain in the repository to preserve prior work. They are historical fixtures, not the live renderer. The bus meter adapter and old loop DSP helpers are likewise outside the production playback path.

Validation results and remaining acceptance gates are recorded in `docs/audio-validation.md`. Automated metrics do not establish listening quality. Compare before/after recordings at matched loudness on headphones. Physical Android and iOS acceptance must include background/lock-screen playback and controls, interruptions, headphone disconnection, long sessions, startup latency, and audio-owned memory profiling. The target is rendering below half a block duration, startup below two seconds after initialization, and audio-owned memory below 64 MiB. Simulator and host benchmarks are not physical-device performance certification.
