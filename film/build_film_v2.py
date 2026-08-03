#!/usr/bin/env python3
"""StillScout v2 — rebuild with lead from Canon MVI footage."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path("/Users/sandeshsomyahang/stillscout/film")
FOOTAGE = Path("/Users/sandeshsomyahang/Downloads/New Folder With Items")
FF = str(ROOT / "bin" / "ffmpeg")
FP = str(ROOT / "bin" / "ffprobe")
WORK = ROOT / "work_v2"
EXPORT = ROOT / "export"
AUDIO = ROOT / "audio"
W, H, FPS = 2160, 3840, 30

GRADE = (
    "eq=contrast=0.90:brightness=0.03:saturation=0.82,"
    "curves=all='0/0.05 0.25/0.30 0.5/0.54 0.75/0.78 1/0.96',"
    "colorbalance=rs=0.015:gs=0.008:bs=-0.01:rm=0.02:gm=0.01:bm=-0.012,"
    "gblur=sigma=0.45,unsharp=5:5:0.4:5:5:0.0"
)


def run(cmd: list[str]) -> None:
    print("+", " ".join(str(c) for c in cmd[:10]), "...")
    subprocess.run(cmd, check=True)


def probe_duration(path: Path) -> float:
    out = subprocess.check_output(
        [FP, "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        text=True,
    ).strip()
    return float(out)


def render_clip(
    src_name: str,
    dst: Path,
    *,
    start: float,
    duration: float,
    speed: float = 1.0,
    fade_in: float = 0.0,
    fade_out: float = 0.0,
) -> None:
    src = FOOTAGE / src_name
    out_dur = duration / speed
    vf = (
        f"format=yuv420p,"
        f"deshake=rx=16:ry=16,"
        f"setpts=PTS/{speed},"
        f"scale={W}:{H}:force_original_aspect_ratio=increase:flags=lanczos,"
        f"crop={W}:{H},{GRADE}"
    )
    if fade_in:
        vf += f",fade=t=in:st=0:d={fade_in}"
    if fade_out:
        vf += f",fade=t=out:st={max(0.01, out_dur - fade_out)}:d={fade_out}"

    run([
        FF, "-y",
        "-ss", f"{start:.2f}",
        "-t", f"{duration:.2f}",
        "-i", str(src),
        "-vf", vf,
        "-an",
        "-r", str(FPS),
        "-c:v", "h264_videotoolbox",
        "-b:v", "40M",
        "-pix_fmt", "yuv420p",
        "-t", f"{out_dur:.3f}",
        str(dst),
    ])


def render_end_with_title(src_name: str, dst: Path, *, start: float, duration: float) -> None:
    """Notebook end card with StillScout typography."""
    src = FOOTAGE / src_name
    tmp = WORK / "clips" / "08_notebook_base.mp4"
    render_clip(src_name, tmp, start=start, duration=duration, speed=0.92, fade_in=0.4)

    # Burn titles
    run([
        FF, "-y", "-i", str(tmp),
        "-vf",
        "drawtext=fontfile=/System/Library/Fonts/Supplemental/Didot.ttc:"
        "text='StillScout':fontsize=130:fontcolor=white@0.95:"
        "borderw=0:x=(w-text_w)/2:y=h*0.82:enable='gte(t,1.0)',"
        "drawtext=fontfile=/System/Library/Fonts/Supplemental/Georgia.ttf:"
        "text='Scout the perfect still.':fontsize=56:fontcolor=white@0.88:"
        "x=(w-text_w)/2:y=h*0.82+145:enable='gte(t,1.5)',"
        "fade=t=out:st=4.6:d=1.2",
        "-c:v", "h264_videotoolbox", "-b:v", "40M", "-pix_fmt", "yuv420p",
        str(dst),
    ])


def mix_audio(total: float, dst: Path) -> None:
    src = AUDIO / "src"
    filter_complex = (
        f"[0:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"volume=0.52,afade=t=in:st=0:d=1.2,afade=t=out:st={total-2}:d=2[waves];"
        f"[1:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"volume=0.16,afade=t=in:st=2.5:d=2,afade=t=out:st={total-2.5}:d=2.5[gulls];"
        f"[2:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"volume=0.20,afade=t=in:st=0:d=1.5,highpass=f=180,lowpass=f=4500[wind];"
        f"[3:a]adelay=9000|9000,atrim=0:{total},asetpts=N/SR/TB,"
        f"volume=0.36,afade=t=in:st=0:d=2.2,afade=t=out:st={total-2.2}:d=2.2,"
        f"lowpass=f=7500[piano];"
        f"[waves][gulls][wind][piano]amix=inputs=4:normalize=0:dropout_transition=2,"
        f"alimiter=limit=0.95,loudnorm=I=-16:TP=-1.5:LRA=11[aout]"
    )
    run([
        FF, "-y",
        "-i", str(src / "waves2.mp3"),
        "-i", str(src / "seagulls.mp3"),
        "-i", str(src / "breeze.mp3"),
        "-i", str(src / "soft_piano.mp3"),
        "-filter_complex", filter_complex,
        "-map", "[aout]", "-t", str(total),
        "-c:a", "aac", "-b:a", "320k",
        str(dst),
    ])


def main() -> int:
    clips = WORK / "clips"
    clips.mkdir(parents=True, exist_ok=True)
    EXPORT.mkdir(parents=True, exist_ok=True)

    # Shot plan
    render_clip("MVI_0372.MP4", clips / "01_breath.mp4",
                start=0.8, duration=3.6, speed=0.90, fade_in=0.8)
    render_clip("MVI_0350.MP4", clips / "02_lead_gaze.mp4",
                start=4.0, duration=4.8, speed=0.88)
    render_clip("MVI_0358.MP4", clips / "03_writing.mp4",
                start=1.5, duration=4.5, speed=0.90)
    render_clip("MVI_0356.MP4", clips / "04_hands.mp4",
                start=2.0, duration=4.0, speed=0.85)
    render_clip("MVI_0355.MP4", clips / "05_face.mp4",
                start=3.0, duration=4.0, speed=0.88)
    render_clip("MVI_0363.MP4", clips / "06_scout.mp4",
                start=5.0, duration=5.0, speed=0.90)
    render_clip("MVI_0376.MP4", clips / "07_phone_sea.mp4",
                start=2.0, duration=4.5, speed=0.90)
    render_end_with_title("MVI_0387.MP4", clips / "08_end.mp4",
                          start=2.0, duration=5.5)

    ordered = [
        clips / f"{n}.mp4"
        for n in [
            "01_breath", "02_lead_gaze", "03_writing", "04_hands",
            "05_face", "06_scout", "07_phone_sea", "08_end",
        ]
    ]
    for c in ordered:
        print(f"  {c.name}: {probe_duration(c):.2f}s")

    # Concat + mux
    inputs = []
    for c in ordered:
        inputs += ["-i", str(c)]
    n = len(ordered)
    fc = "".join(f"[{i}:v]" for i in range(n)) + f"concat=n={n}:v=1:a=0[v]"

    silent = WORK / "picture.mp4"
    run([
        FF, "-y", *inputs,
        "-filter_complex", fc,
        "-map", "[v]",
        "-c:v", "h264_videotoolbox", "-b:v", "45M",
        "-pix_fmt", "yuv420p",
        str(silent),
    ])
    total = probe_duration(silent)
    print("Total:", total)

    audio = WORK / "mix.m4a"
    mix_audio(total, audio)

    master = EXPORT / "StillScout_ThePerfectStill_4K_9x16.mp4"
    run([
        FF, "-y", "-i", str(silent), "-i", str(audio),
        "-map", "0:v:0", "-map", "1:a:0",
        "-c:v", "copy", "-c:a", "aac", "-b:a", "320k",
        "-movflags", "+faststart", "-shortest",
        str(master),
    ])

    social = EXPORT / "StillScout_ThePerfectStill_1080x1920.mp4"
    run([
        FF, "-y", "-i", str(master),
        "-vf", "scale=1080:1920:flags=lanczos",
        "-c:v", "h264_videotoolbox", "-b:v", "12M",
        "-pix_fmt", "yuv420p", "-movflags", "+faststart",
        "-c:a", "copy",
        str(social),
    ])

    # Decode check
    err = subprocess.run(
        [FF, "-v", "error", "-i", str(master), "-f", "null", "-"],
        capture_output=True, text=True,
    )
    print("DECODE:", "CLEAN" if not err.stderr.strip() else err.stderr[:400])

    meta = {
        "title": "StillScout — The Perfect Still (v2 with lead)",
        "duration_sec": probe_duration(master),
        "footage": str(FOOTAGE),
        "master": str(master),
        "social": str(social),
        "screenplay": str(ROOT / "SCREENPLAY_v2.md"),
    }
    (EXPORT / "manifest.json").write_text(json.dumps(meta, indent=2))
    print(json.dumps(meta, indent=2))
    print("DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
