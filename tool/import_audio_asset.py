#!/usr/bin/env python3
"""Import a licensed audio file as app-ready stereo 48 kHz/16-bit PCM.

Requires ffmpeg. The source audio is never bundled; only the converted output
and explicit source/license attribution are copied into the repository.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import tempfile
import math
import struct
import wave
from pathlib import Path

from validate_audio_assets import ASSETS, inspect

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ASSETS / "provenance.json"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path, help="Source audio file")
    parser.add_argument("destination", help="Relative path under assets/audio")
    parser.add_argument("--license", required=True, help="License identifier or exact permission")
    parser.add_argument("--source-url", required=True, help="Original asset page or source URL")
    parser.add_argument("--attribution", default="", help="Required attribution text, if any")
    parser.add_argument("--output-dir", type=Path, default=ASSETS,
                        help="Output root (defaults to assets/audio; useful for validation in a temp directory)")
    parser.add_argument("--target-rms-dbfs", type=float, default=-24.0,
                        help="DC-removed target RMS, capped at -1 dBFS peak")
    parser.add_argument("--loop-crossfade-ms", type=float, default=0,
                        help="Optional circular equal-power loop crossfade; trims the overlapped span")
    args = parser.parse_args()

    source = args.source.expanduser().resolve()
    relative = Path(args.destination)
    if relative.is_absolute() or ".." in relative.parts:
        raise SystemExit("destination must stay inside assets/audio")
    if not source.is_file():
        raise SystemExit(f"source does not exist: {source}")
    output_dir = args.output_dir.expanduser().resolve()
    destination = (output_dir / relative).resolve()
    if output_dir not in destination.parents:
        raise SystemExit("destination must stay inside output-dir")
    destination.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.NamedTemporaryFile(suffix=".wav") as converted:
        subprocess.run(
            [
                "ffmpeg", "-v", "error", "-y", "-i", str(source), "-vn",
                "-ac", "2", "-ar", "48000", "-c:a", "pcm_s16le", converted.name,
            ],
            check=True,
        )
        converted_path = Path(converted.name)
        with wave.open(str(converted_path), "rb") as wav:
            frame_count = wav.getnframes()
            raw = wav.readframes(frame_count)
        pcm = list(struct.unpack("<" + "h" * (len(raw) // 2), raw))
        channels = 2
        means = [sum(pcm[c::channels]) / frame_count for c in range(channels)]
        centered = [pcm[i] - means[i % channels] for i in range(len(pcm))]
        if args.loop_crossfade_ms > 0:
            overlap = min(round(48_000 * args.loop_crossfade_ms / 1000), frame_count // 4)
            if overlap < 2:
                raise SystemExit("source is too short for requested loop crossfade")
            blended = []
            for frame in range(overlap):
                phase = (frame + 0.5) / overlap * math.pi / 2
                tail_at = (frame_count - overlap + frame) * channels
                head_at = frame * channels
                for channel in range(channels):
                    blended.append(centered[tail_at + channel] * math.cos(phase) +
                                   centered[head_at + channel] * math.sin(phase))
            centered = blended + centered[overlap * channels:(frame_count - overlap) * channels]
            frame_count = len(centered) // channels
        rms = math.sqrt(sum(x * x for x in centered) / len(centered))
        peak = max(abs(x) for x in centered)
        if rms < 1:
            raise SystemExit("source is silent after DC removal")
        target = 32768 * 10 ** (args.target_rms_dbfs / 20)
        gain = min(target / rms, 32768 * 10 ** (-1 / 20) / max(peak, 1))
        normalized = [max(-32768, min(32767, round(x * gain))) for x in centered]
        with wave.open(str(converted_path), "wb") as wav:
            wav.setnchannels(channels)
            wav.setsampwidth(2)
            wav.setframerate(48_000)
            wav.writeframes(struct.pack("<" + "h" * len(normalized), *normalized))
        metrics = inspect(converted_path)
        destination.write_bytes(converted_path.read_bytes())

    manifest_path = output_dir / "provenance.json"
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    imports = manifest.setdefault("imports", {})
    imports[relative.as_posix()] = {
            **metrics,
            "license": args.license,
            "source_url": args.source_url,
            "attribution": args.attribution,
            "converted_by": "tool/import_audio_asset.py + ffmpeg, DC removal and RMS calibration",
            "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
    }
    manifest.setdefault("provenance", "Imported audio with explicit source and license metadata.")
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"Imported {relative.as_posix()} ({metrics['duration_seconds']}s, {metrics['rms_dbfs']} dBFS RMS)")


if __name__ == "__main__":
    main()
