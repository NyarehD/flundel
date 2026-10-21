#!/usr/bin/env python3
"""Validate generated PCM assets and write reproducible provenance metadata."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets/audio"
FILES = [
    "drone_root.wav",
    "pads/pad_ambient.wav",
    "texture_noise.wav",
    "nature/rain_loop.wav",
    "chimes/chime_1.wav",
    "chimes/chime_2.wav",
    "chimes/chime_3.wav",
    "chimes/chime_4.wav",
    "piano/note_1.wav",
    "piano/note_2.wav",
    "piano/note_3.wav",
    "piano/note_4.wav",
    "completion/gentle_completion.wav",
] + [f"pads/chords/{chord}.wav" for chord in (
    "am7", "cMaj7", "fMaj7", "em7", "dMaj7", "am9", "cMaj9", "fMaj7Sharp11"
)]


def inspect(path: Path) -> dict[str, object]:
    data = path.read_bytes()
    with wave.open(str(path), "rb") as wav:
        channels = wav.getnchannels()
        width = wav.getsampwidth()
        rate = wav.getframerate()
        frames = wav.readframes(wav.getnframes())
        frame_count = wav.getnframes()
    if channels != 2 or width != 2 or rate != 48000:
        raise ValueError(f"{path}: expected stereo 16-bit 48 kHz PCM")
    count = len(frames) // 2
    samples = struct.unpack("<" + "h" * count, frames)
    means = [sum(samples[c::channels]) / (frame_count * 32768) for c in range(channels)]
    peak = max(abs(sample) for sample in samples) / 32768
    rms = math.sqrt(sum((sample / 32768) ** 2 for sample in samples) / count)
    dc = max(abs(mean) for mean in means)
    seam_delta = max(
        abs(samples[channel] - samples[-channels + channel]) / 32768
        for channel in range(channels)
    )
    if rms <= 0 or peak >= 0.999:
        raise ValueError(f"{path}: silent or clipped PCM (rms={rms}, peak={peak})")
    if dc > 0.002:
        raise ValueError(f"{path}: excessive DC offset ({dc:.6f})")
    is_loop = path.name in {"drone_root.wav", "pad_ambient.wav", "texture_noise.wav", "rain_loop.wav"} or path.parent.name == "chords"
    if is_loop and seam_delta > 0.05:
        raise ValueError(f"{path}: loop seam delta too large ({seam_delta:.4f})")
    return {
        "sha256": hashlib.sha256(data).hexdigest(),
        "sample_rate_hz": rate,
        "channels": channels,
        "duration_seconds": round(frame_count / rate, 3),
        "rms_dbfs": round(20 * math.log10(rms), 2),
        "peak_dbfs": round(20 * math.log10(peak), 2),
        "max_dc_offset": round(dc, 6),
        "loop_seam_delta": round(seam_delta, 6) if is_loop else None,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write-manifest", action="store_true")
    args = parser.parse_args()
    existing_manifest_path = ASSETS / "provenance.json"
    existing_manifest = json.loads(existing_manifest_path.read_text()) if existing_manifest_path.exists() else {}
    imports = existing_manifest.get("imports", {})
    for name, metadata in imports.items():
        imported_path = ASSETS / name
        if not imported_path.is_file():
            raise ValueError(f"imported asset is missing: {name}")
        actual = inspect(imported_path)
        for field, value in actual.items():
            if metadata.get(field) != value:
                raise ValueError(f"import provenance is stale for {name}: {field}")
    manifest = {
        "provenance": "Generated in this repository by tool/generate_assets.dart. No third-party audio is bundled.",
        "generator": "Dart synthesis: PadSynth, NoiseEngine, EnvironmentalLayer, SyntheticAudio; 48 kHz stereo PCM; deterministic noise seeds 42 and 88.",
        "assets": {name: inspect(ASSETS / name) for name in FILES},
        "imports": imports,
    }
    result = json.dumps(manifest, indent=2, sort_keys=True) + "\n"
    manifest_path = existing_manifest_path
    if args.write_manifest:
        manifest_path.write_text(result)
    elif manifest_path.exists() and manifest_path.read_text() != result:
        raise ValueError("provenance.json is stale; rerun with --write-manifest")
    print(result, end="")


if __name__ == "__main__":
    main()
