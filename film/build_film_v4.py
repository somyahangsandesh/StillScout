#!/usr/bin/env python3
"""StillScout v4 — 'Before the Capture'
Creative alternate cut: detail → face → world opens → sky breath → scout → brand.
Soft crossfades. Different music. Does not overwrite v3."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path("/Users/sandeshsomyahang/stillscout/film")
FOOTAGE = Path("/Users/sandeshsomyahang/Downloads/New Folder With Items")
FF = str(ROOT / "bin" / "ffmpeg")
FP = str(ROOT / "bin" / "ffprobe")
WORK = ROOT / "work_v4"
EXPORT = ROOT / "export"
AUDIO = ROOT / "audio" / "src_v3"
W, H, FPS = 2160, 3840, 30

BEAUTY = (
    "format=yuv420p,"
    "hqdn3d=3:2:4:3,"
    "bilateral=sigmaS=3.8:sigmaR=0.13,"
    "eq=contrast=0.84:brightness=0.05:saturation=0.76:gamma=1.07,"
    "curves="
    "red='0/0.07 0.3/0.37 0.55/0.61 1/0.99':"
    "green='0/0.06 0.3/0.35 0.55/0.58 1/0.98':"
    "blue='0/0.08 0.3/0.34 0.55/0.55 1/0.96',"
    "colorbalance=rs=0.04:gs=0.015:bs=-0.022:rm=0.05:gm=0.018:bm=-0.028:rh=0.025:gh=0.01:bh=-0.012,"
    "split[base][glow];[glow]gblur=sigma=12[g];"
    "[base][g]blend=all_mode=screen:all_opacity=0.14,"
    "unsharp=5:5:0.3:5:5:0.0,"
    "vignette=PI/5.5"
)

WIDE = (
    "format=yuv420p,"
    "hqdn3d=2:1.5:3:2,"
    "eq=contrast=0.87:brightness=0.035:saturation=0.78:gamma=1.05,"
    "curves=all='0/0.06 0.5/0.55 1/0.975',"
    "colorbalance=rs=0.025:gs=0.01:bs=-0.015:rm=0.03:gm=0.012:bm=-0.018,"
    "split[base][glow];[glow]gblur=sigma=9[g];"
    "[base][g]blend=all_mode=screen:all_opacity=0.11,"
    "unsharp=5:5:0.28:5:5:0.0"
)


def run(cmd: list[str]) -> None:
    print("+", " ".join(str(c) for c in cmd[:11]), "...")
    subprocess.run(cmd, check=True)


def probe(path: Path) -> float:
    return float(subprocess.check_output(
        [FP, "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        text=True,
    ).strip())


def render(
    src: str, dst: Path, *, start: float, duration: float, speed: float = 1.0,
    beauty: bool = False, fade_in: float = 0.0, fade_out: float = 0.0,
    crop_y: str = "(ih-oh)/2",
) -> float:
    out_dur = duration / speed
    grade = BEAUTY if beauty else WIDE
    vf = (
        f"deshake=rx=16:ry=16,setpts=PTS/{speed},"
        f"scale={W}:{H}:force_original_aspect_ratio=increase:flags=lanczos,"
        f"crop={W}:{H}:(iw-ow)/2:{crop_y},{grade}"
    )
    if fade_in:
        vf += f",fade=t=in:st=0:d={fade_in}"
    if fade_out:
        vf += f",fade=t=out:st={max(0.01, out_dur - fade_out)}:d={fade_out}"
    run([
        FF, "-y", "-ss", f"{start:.2f}", "-t", f"{duration:.2f}",
        "-i", str(FOOTAGE / src), "-vf", vf, "-an", "-r", str(FPS),
        "-c:v", "h264_videotoolbox", "-b:v", "42M", "-pix_fmt", "yuv420p",
        "-t", f"{out_dur:.3f}", str(dst),
    ])
    return out_dur


def assemble_with_xfades(clips: list[Path], durs: list[float], dst: Path, xfade: float = 0.7) -> float:
    """Chain soft crossfades between all clips for dreamy memory feel."""
    if len(clips) == 1:
        run(["cp", str(clips[0]), str(dst)])
        return durs[0]

    inputs: list[str] = []
    for c in clips:
        inputs += ["-i", str(c)]

    # Build nested xfade filter
    # offset_i = sum(dur[0..i]) - xfade * i  (approx for chain)
    parts = []
    # First pair
    offset = durs[0] - xfade
    parts.append(
        f"[0:v][1:v]xfade=transition=fade:duration={xfade}:offset={offset:.3f}[v01]"
    )
    prev = "v01"
    acc = durs[0] + durs[1] - xfade
    for i in range(2, len(clips)):
        offset = acc - xfade
        out = f"v{i:02d}" if i < len(clips) - 1 else "vout"
        # last label vout
        if i == len(clips) - 1:
            out = "vout"
        parts.append(
            f"[{prev}][{i}:v]xfade=transition=fade:duration={xfade}:offset={offset:.3f}[{out}]"
        )
        prev = out
        acc = acc + durs[i] - xfade

    # If only 2 clips, rename
    if len(clips) == 2:
        fc = f"[0:v][1:v]xfade=transition=fade:duration={xfade}:offset={durs[0]-xfade:.3f}[vout]"
    else:
        fc = ";".join(parts)

    total = sum(durs) - xfade * (len(clips) - 1)
    run([
        FF, "-y", *inputs,
        "-filter_complex", fc,
        "-map", "[vout]",
        "-c:v", "h264_videotoolbox", "-b:v", "45M",
        "-pix_fmt", "yuv420p",
        "-t", f"{total:.3f}",
        str(dst),
    ])
    return probe(dst)


def mix_audio(total: float, dst: Path) -> None:
    piano = AUDIO / "km_peaceful.mp3"
    if not piano.exists() or piano.stat().st_size < 10000:
        piano = AUDIO / "piano_200.mp3"
    waves = AUDIO / "sfx_1206.mp3"
    waves2 = AUDIO / "sfx_1193.mp3" if (AUDIO / "sfx_1193.mp3").exists() else AUDIO / "sfx_1208.mp3"
    gulls = AUDIO / "seagulls.mp3"
    loc = AUDIO / "loc" / "MVI_0363.wav"
    wind = AUDIO / "sfx_1267.mp3"

    # Piano starts almost immediately but whisper-quiet, blooms mid-film
    fc = (
        f"[0:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=70,lowpass=f=8500,volume=0.50,"
        f"afade=t=in:st=0:d=2.5,afade=t=out:st={total-3}:d=3[w1];"
        f"[1:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=90,volume=0.18,afade=t=in:st=0:d=2[w2];"
        f"[2:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"volume=0.08,highpass=f=900,lowpass=f=5500,"
        f"afade=t=in:st=8:d=4,afade=t=out:st={total-4}:d=3[gulls];"
        f"[3:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=180,lowpass=f=3200,volume=0.12,afade=t=in:st=0:d=2[wind];"
        f"[4:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=150,lowpass=f=4500,volume=0.10,afade=t=in:st=0:d=1.5[loc];"
        # Peaceful piano from 2s, rises then settles
        f"[5:a]adelay=2000|2000,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=90,lowpass=f=5500,"
        f"acompressor=threshold=-24dB:ratio=2.5:attack=80:release=400,"
        f"volume=0.32,afade=t=in:st=0:d=4,afade=t=out:st={total-3.5}:d=3.5[piano];"
        f"[w1][w2][gulls][wind][loc][piano]amix=inputs=6:normalize=0:dropout_transition=3,"
        f"equalizer=f=200:t=q:w=1:g=-1.5,equalizer=f=4000:t=q:w=1:g=1.2,"
        f"alimiter=limit=0.90,loudnorm=I=-17:TP=-2.0:LRA=8[aout]"
    )
    run([
        FF, "-y",
        "-i", str(waves), "-i", str(waves2), "-i", str(gulls),
        "-i", str(wind if wind.exists() else waves),
        "-i", str(loc if loc.exists() else waves),
        "-i", str(piano),
        "-filter_complex", fc,
        "-map", "[aout]", "-t", str(total),
        "-c:a", "aac", "-b:a", "320k",
        str(dst),
    ])


def main() -> int:
    clips_dir = WORK / "clips"
    clips_dir.mkdir(parents=True, exist_ok=True)
    EXPORT.mkdir(parents=True, exist_ok=True)

    plan = []  # (path, duration)

    # 1 — Open on the notebook (mystery: what is he writing?)
    d = render("MVI_0387.MP4", clips_dir / "01_pages.mp4",
               start=0.8, duration=3.2, speed=0.88, beauty=True, fade_in=1.0,
               crop_y="(ih-oh)/2-60")
    plan.append((clips_dir / "01_pages.mp4", d))

    # 2 — Hands writing
    d = render("MVI_0356.MP4", clips_dir / "02_hands.mp4",
               start=6.0, duration=3.8, speed=0.80, beauty=True)
    plan.append((clips_dir / "02_hands.mp4", d))

    # 3 — Handsome profile (keep the look that worked)
    d = render("MVI_0358.MP4", clips_dir / "03_profile.mp4",
               start=3.5, duration=4.8, speed=0.86, beauty=True,
               crop_y="(ih-oh)/2+60")
    plan.append((clips_dir / "03_profile.mp4", d))

    # 4 — Soft face, ocean bokeh
    d = render("MVI_0353.MP4", clips_dir / "04_face.mp4",
               start=18.0, duration=4.0, speed=0.84, beauty=True,
               crop_y="(ih-oh)/2+220")
    plan.append((clips_dir / "04_face.mp4", d))

    # 5 — NEW: world opens — him under palm facing the harbor
    d = render("MVI_0343.MP4", clips_dir / "05_harbor.mp4",
               start=1.2, duration=4.5, speed=0.90,
               crop_y="(ih-oh)/2+80")
    plan.append((clips_dir / "05_harbor.mp4", d))

    # 6 — NEW: empty sky breath (Ghibli pause — no face, just longing)
    d = render("MVI_0365.MP4", clips_dir / "06_sky.mp4",
               start=10.0, duration=4.2, speed=0.85)
    plan.append((clips_dir / "06_sky.mp4", d))

    # 7 — Phone raised to the sea (the decision to capture)
    d = render("MVI_0363.MP4", clips_dir / "07_raise.mp4",
               start=10.0, duration=4.2, speed=0.88,
               crop_y="(ih-oh)/2+80")
    plan.append((clips_dir / "07_raise.mp4", d))

    # 8 — Over-shoulder: the still already on his screen
    d = render("MVI_0378.MP4", clips_dir / "08_screen.mp4",
               start=4.0, duration=3.8, speed=0.90, beauty=True)
    plan.append((clips_dir / "08_screen.mp4", d))

    # 9 — Sit with notebook resting (aftermath of the still)
    d = render("MVI_0359.MP4", clips_dir / "09_rest.mp4",
               start=6.0, duration=3.6, speed=0.88, beauty=True,
               crop_y="(ih-oh)/2+100")
    plan.append((clips_dir / "09_rest.mp4", d))

    # 10 — End card on notebook
    base = clips_dir / "10_end_base.mp4"
    d = render("MVI_0387.MP4", base,
               start=3.0, duration=5.0, speed=0.90, beauty=True, fade_in=0.3,
               crop_y="(ih-oh)/2-40")
    end = clips_dir / "10_end.mp4"
    run([
        FF, "-y", "-i", str(base),
        "-vf",
        "drawbox=x=0:y=ih*0.70:w=iw:h=ih*0.30:color=black@0.32:t=fill,"
        "drawtext=fontfile=/System/Library/Fonts/Supplemental/Didot.ttc:"
        "text='StillScout':fontsize=126:fontcolor=0xFFFAF5@0.96:"
        "x=(w-text_w)/2:y=h*0.78:enable='gte(t,0.9)',"
        "drawtext=fontfile=/System/Library/Fonts/Supplemental/Georgia.ttf:"
        "text='Scout the perfect still.':fontsize=52:fontcolor=0xFFF8F0@0.90:"
        "x=(w-text_w)/2:y=h*0.78+138:enable='gte(t,1.4)',"
        "fade=t=out:st=4.2:d=1.4",
        "-c:v", "h264_videotoolbox", "-b:v", "42M", "-pix_fmt", "yuv420p",
        str(end),
    ])
    plan.append((end, probe(end)))

    for p, dur in plan:
        print(f"  {p.name}: {dur:.2f}s")

    paths = [p for p, _ in plan]
    durs = [d for _, d in plan]
    picture = WORK / "picture.mp4"
    total = assemble_with_xfades(paths, durs, picture, xfade=0.65)
    print("Picture with xfade:", total)

    audio = WORK / "mix.m4a"
    mix_audio(total, audio)

    master = EXPORT / "StillScout_BeforeTheCapture_4K_9x16.mp4"
    social = EXPORT / "StillScout_BeforeTheCapture_1080x1920.mp4"

    run([
        FF, "-y", "-i", str(picture), "-i", str(audio),
        "-map", "0:v", "-map", "1:a",
        "-c:v", "copy", "-c:a", "aac", "-b:a", "320k",
        "-movflags", "+faststart", "-shortest",
        str(master),
    ])
    run([
        FF, "-y", "-i", str(master),
        "-vf", "scale=1080:1920:flags=lanczos",
        "-c:v", "h264_videotoolbox", "-b:v", "14M",
        "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-c:a", "copy",
        str(social),
    ])

    err = subprocess.run(
        [FF, "-v", "error", "-i", str(master), "-f", "null", "-"],
        capture_output=True, text=True,
    )
    print("DECODE:", "CLEAN" if not err.stderr.strip() else err.stderr[:300])

    meta = {
        "title": "StillScout — Before the Capture",
        "version": "v4 creative alternate",
        "concept": "Start inside the notebook, open to the harbor, breathe with the sky, then the phone finds the still.",
        "duration_sec": probe(master),
        "music": "Kevin MacLeod — Peaceful Desolation (or Mixkit soft piano fallback)",
        "v3_preserved": str(EXPORT / "StillScout_ThePerfectStill_v3_1080x1920.mp4"),
        "master": str(master),
        "social": str(social),
    }
    (EXPORT / "manifest_v4.json").write_text(json.dumps(meta, indent=2))
    (EXPORT / "AUDIO_CREDITS_v4.txt").write_text(
        "Music: Peaceful Desolation — Kevin MacLeod (incompetech.com)\n"
        "Licensed under Creative Commons: By Attribution 4.0\n"
        "https://creativecommons.org/licenses/by/4.0/\n\n"
        "SFX: Mixkit ocean / wind / seagulls\n"
        "Location ambience from source footage\n"
    )
    print(json.dumps(meta, indent=2))
    print("DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
