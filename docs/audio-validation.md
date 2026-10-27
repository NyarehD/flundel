# Audio rebuild validation

Evidence updated on 2026-10-27. Further device validation is Android-only at the user’s request. The core implementation is in `docs/audio.md`.

## Automated checks

- Full Flutter suite: **108 tests passed** after the fuller pad and legacy checkpoint changes; the subsequent capture and generative subset passed 19 tests. Final full-suite capture validation is recorded below when complete.
- Analyzer: no errors or warnings with `flutter analyze --no-pub --no-fatal-infos`; 59 informational style findings remain under the newly configured strict lint rules. This is not a clean zero-findings analyzer run.
- Whitespace validation: `git diff --check` passed.
- Three-minute renders of all ten presets: **30 minutes of generated audio**, using the production renderer. No nonfinite or clipped PCM; maximum mixed peak 0.1986 (about -14.0 dBFS); minimum mono RMS retention 97.4%; maximum sampled procedural polyphony six voices. Another 30 minutes with every source and master at maximum remained unclipped before the native limiter (maximum peak 0.5259, minimum mono retention 96.8%, maximum sampled polyphony seven). Exact JSON checkpoint continuation checked repeatedly, including across chord transitions.
- Host AOT benchmark (Apple M5): worst default-preset p99 block rendering 5.642 ms; worst observed block 82.211 ms during concurrent native builds/tests, versus an 85.33 ms block duration. The isolated slowest block exceeds the half-block target; p99 meets it. The maximum-level run had p99 6.929 ms and maximum 30.174 ms. These host measurements do not certify phone performance.

Generated per-preset WAVs and machine-readable metrics are in the ignored local directory `build/audio-validation/`. Tests additionally cover arbitrary block partitions, isolated binaural carriers, gain/mute/solo, harmony coordination, stale worker updates, legacy checkpoints, restoration paused without counting downtime, storage failure on pause, retry after device startup failure, and actual-end session phases.

## Native playback

`tool/focus_audio_probe.dart` uses SoLoud's actual post-mixer output, not an offline approximation. It checks captures for every preset, silent zero intensity, coherent producer-stall recovery, pause/resume, exact consumed checkpoints, restoration paused, cleanup between sessions, and completion. The expanded probe also covers a genuine native underrun, mute overriding solo, master-zero silence, rapid updates, and a stop while rendering.

The first Android capture failed because the pinned native package's fixed-size chunk notification latch could remain set when more than one chunk arrived. Threshold capture, which drains the whole available batch, passed the same capture sequence. The earlier iOS long run reached 14 minutes before its simulator disconnected; that interrupted run is not counted as a completed 30-minute test.

The earlier iOS simulator run completed 1,803 seconds and saved its report in `build/audio-validation/native-ios-initial/`. One refill recovery occurred around hot reload and resumed with zero stem skew; it is not a zero-recovery soak. The earlier Android emulator disconnected after roughly 28 minutes and did not complete its report. A fresh isolated Android emulator is running the optimized revised mix for a replacement 30-minute test. Keep `report.json` as the pass artifact; `progress.json` alone does not establish completion.

Before the Android-only request, the revised iOS probe passed all ten captures, genuine underrun recovery, mute/solo, master-zero, rapid updates, stale-start cancellation, completion, and disposal. Saved disposal diagnostics confirm zero native voices, closed worker, and native backend deinitialized. The latest Android profile build began playback in 342 ms and passed the short control/recovery sequence before entering its soak. No further iOS testing is being performed.

## Memory evidence

During the iOS simulator run, VM retained-size inspection measured 4,978,160 bytes for the bounded 32-entry checkpoint history and 151,888 bytes for the current DSP renderer. Native queued PCM normally measured about 4.1–4.5 MB. The hard stream cap is 12,672,000 bytes across eleven stereo float stems. Ordinary native voice count remained twelve, including the parent bus.

These are measured components and explicit capacity limits, not a comprehensive native allocator audit. Process RSS includes Flutter, JIT/compiler state, graphics, and VM heaps. A physical-device peak audio-owned allocation measurement below 64 MiB remains an acceptance gate, especially during capture and checkpoint serialization.

## Matched-volume listening

Actual Deep Work captures are available locally at:

- `build/audio-previews/system-rebuild/before-matched.wav`
- `build/audio-previews/system-rebuild/after-matched.wav`

The first rebuilt capture measured -33.37 dBFS RMS versus -25.47 previously. The user found it too sparse/quiet, and also rejected the intermediate -27.65 dBFS revision as thin/quiet with audible hiss. The final revision adds a lower-octave pad foundation, richer harmonics, closer Deep Work/Coding phrases, and subdued filtered textures. Its 12-second native capture measured -21.11 dBFS RMS. Integrated output energy above 3 kHz fell from -62.42 to -79.82 dBFS between the intermediate and fuller revision (8192-sample Hann-window FFT, left channel); this is a signal measurement, not a subjective quality verdict.

The current Android native capture is `build/audio-previews/system-rebuild/android-full-warm.wav`. The earlier matched pair is retained for provenance. Fixed synthesis calibration is applied before user gains; no automatic gain compensation was introduced. Headphone acceptance of the final revision remains pending.

## Physical-device acceptance still required

- Android and iOS headphones: sustained listening, phrase density, warmth, fatigue, low-volume balance, and matched-loudness comparison.
- Background and lock-screen playback and controls; OS interruption and headphone-disconnect behavior; long background sessions.
- Release-build cold startup and rendering throughput on representative phones, including older hardware. Target: first playback within two seconds after initialization; rendering below 42.67 ms per block.
- Peak audio-owned memory below 64 MiB; native source and worker release after repeated sessions.
- Abrupt termination and reopening using real device storage: restore paused and lose no more than five seconds while checkpoint writes succeed.

Simulator results and automated signal measurements do not replace these checks.
