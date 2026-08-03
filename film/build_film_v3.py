#!/usr/bin/env python3
"""StillScout v3 — handsome beauty grade + cinematic audio remake."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path("/Users/sandeshsomyahang/stillscout/film")
FOOTAGE = Path("/Users/sandeshsomyahang/Downloads/New Folder With Items")
FF = str(ROOT / "bin" / "ffmpeg")
FP = str(ROOT / "bin" / "ffprobe")
WORK = ROOT / "work_v3"
EXPORT = ROOT / "export"
AUDIO = ROOT / "audio" / "src_v3"
W, H, FPS = 2160, 3840, 30

# Korean-drama beauty: soft skin, warm healthy tones, creamy highlights, lifted blacks
# bilateral softens skin; bloom via gblur screen blend; warm midtones for face
BEAUTY = (
    "format=yuv420p,"
    "hqdn3d=3:2:4:3,"
    "bilateral=sigmaS=3.5:sigmaR=0.12,"
    "eq=contrast=0.86:brightness=0.045:saturation=0.78:gamma=1.06,"
    "curves="
    "red='0/0.06 0.3/0.36 0.55/0.60 1/0.985':"
    "green='0/0.055 0.3/0.34 0.55/0.57 1/0.975':"
    "blue='0/0.07 0.3/0.33 0.55/0.55 1/0.96',"
    "colorbalance=rs=0.035:gs=0.012:bs=-0.02:"
    "rm=0.045:gm=0.015:bm=-0.025:"
    "rh=0.02:gh=0.01:bh=-0.01,"
    "split[base][glow];"
    "[glow]gblur=sigma=10[g];"
    "[base][g]blend=all_mode=screen:all_opacity=0.12,"
    "unsharp=5:5:0.35:5:5:0.0,"
    "vignette=PI/5"
)

# Lighter grade for wide/establishing (less beauty blur needed)
WIDE = (
    "format=yuv420p,"
    "hqdn3d=2:1.5:3:2,"
    "eq=contrast=0.88:brightness=0.03:saturation=0.80:gamma=1.04,"
    "curves=all='0/0.05 0.5/0.54 1/0.97',"
    "colorbalance=rs=0.02:gs=0.01:bs=-0.012:rm=0.025:gm=0.01:bm=-0.015,"
    "split[base][glow];[glow]gblur=sigma=8[g];"
    "[base][g]blend=all_mode=screen:all_opacity=0.10,"
    "unsharp=5:5:0.3:5:5:0.0"
)


def run(cmd: list[str]) -> None:
    print("+", " ".join(str(c) for c in cmd[:12]), "...")
    subprocess.run(cmd, check=True)


def probe_duration(path: Path) -> float:
    out = subprocess.check_output(
        [FP, "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        text=True,
    ).strip()
    return float(out)


def render(
    src_name: str,
    dst: Path,
    *,
    start: float,
    duration: float,
    speed: float = 1.0,
    beauty: bool = False,
    fade_in: float = 0.0,
    fade_out: float = 0.0,
    # crop bias: shift crop window (positive y = crop more from top = favor lower subject / face)
    crop_y: str = "(ih-oh)/2",
    crop_x: str = "(iw-ow)/2",
) -> None:
    src = FOOTAGE / src_name
    out_dur = duration / speed
    grade = BEAUTY if beauty else WIDE
    vf = (
        f"deshake=rx=16:ry=16,"
        f"setpts=PTS/{speed},"
        f"scale={W}:{H}:force_original_aspect_ratio=increase:flags=lanczos,"
        f"crop={W}:{H}:{crop_x}:{crop_y},"
        f"{grade}"
    )
    if fade_in:
        vf += f",fade=t=in:st=0:d={fade_in}"
    if fade_out:
        vf += f",fade=t=out:st={max(0.01, out_dur - fade_out)}:d={fade_out}"

    run([
        FF, "-y",
        "-ss", f"{start:.2f}", "-t", f"{duration:.2f}",
        "-i", str(src),
        "-vf", vf,
        "-an", "-r", str(FPS),
        "-c:v", "h264_videotoolbox", "-b:v", "42M",
        "-pix_fmt", "yuv420p",
        "-t", f"{out_dur:.3f}",
        str(dst),
    ])


def render_end(dst: Path) -> None:
    tmp = WORK / "clips" / "08_base.mp4"
    # Notebook pages — soft grade, slight push framing
    render(
        "MVI_0387.MP4", tmp,
        start=1.5, duration=5.2, speed=0.90,
        beauty=True, fade_in=0.5,
        crop_y="(ih-oh)/2-80",
    )
    run([
        FF, "-y", "-i", str(tmp),
        "-vf",
        "drawbox=x=0:y=ih*0.72:w=iw:h=ih*0.28:color=black@0.28:t=fill,"
        "drawtext=fontfile=/System/Library/Fonts/Supplemental/Didot.ttc:"
        "text='StillScout':fontsize=128:fontcolor=0xFFFAF5@0.96:"
        "x=(w-text_w)/2:y=h*0.80:enable='gte(t,1.0)',"
        "drawtext=fontfile=/System/Library/Fonts/Supplemental/Georgia.ttf:"
        "text='Scout the perfect still.':fontsize=54:fontcolor=0xFFF8F0@0.90:"
        "x=(w-text_w)/2:y=h*0.80+140:enable='gte(t,1.5)',"
        "fade=t=out:st=4.5:d=1.3",
        "-c:v", "h264_videotoolbox", "-b:v", "42M", "-pix_fmt", "yuv420p",
        str(dst),
    ])


def mix_audio(total: float, dst: Path) -> None:
    """Cinematic mix: long ocean bed + wind + sparse gulls + soft piano + location air."""
    waves = AUDIO / "sfx_1206.mp3"  # 120s ocean
    waves2 = AUDIO / "sfx_1208.mp3"
    gulls = AUDIO / "seagulls.mp3"
    piano = AUDIO / "km_dreams.mp3"  # Kevin MacLeod — Dreams Become Real
    if not piano.exists():
        piano = AUDIO / "piano_288.mp3"
    loc = AUDIO / "loc" / "MVI_0350.wav"
    wind = AUDIO / "sfx_1267.mp3"

    # Piano enters gently at 7s; location air under; waves dominant early
    # EQ: highpass rumble out of waves, lowpass piano softness, duck-ish via volume curve
    fc = (
        f"[0:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=80,lowpass=f=9000,volume=0.48,"
        f"afade=t=in:st=0:d=1.8,afade=t=out:st={total-2.5}:d=2.5[waves];"
        f"[1:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=100,volume=0.22,"
        f"afade=t=in:st=1:d=2,afade=t=out:st={total-2}:d=2[waves2];"
        f"[2:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"volume=0.10,highpass=f=800,lowpass=f=6000,"
        f"afade=t=in:st=4:d=3,afade=t=out:st={total-3}:d=3[gulls];"
        f"[3:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=200,lowpass=f=3500,volume=0.14,"
        f"afade=t=in:st=0:d=2[wind];"
        f"[4:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=120,lowpass=f=5000,volume=0.11,"
        f"afade=t=in:st=0:d=1.5,afade=t=out:st={total-2}:d=2[loc];"
        # Soft piano — delayed, EQ warm, never overpower
        f"[5:a]adelay=7000|7000,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=100,lowpass=f=6000,acompressor=threshold=-22dB:ratio=3:attack=50:release=300,"
        f"volume=0.28,afade=t=in:st=0:d=3.5,afade=t=out:st={total-3}:d=3[piano];"
        f"[waves][waves2][gulls][wind][loc][piano]amix=inputs=6:normalize=0:dropout_transition=3,"
        f"equalizer=f=250:t=q:w=1:g=-2,equalizer=f=3500:t=q:w=1:g=1.5,"
        f"alimiter=limit=0.92,loudnorm=I=-17:TP=-1.8:LRA=9[aout]"
    )
    run([
        FF, "-y",
        "-i", str(waves),
        "-i", str(waves2),
        "-i", str(gulls),
        "-i", str(wind if wind.exists() else waves),
        "-i", str(loc if loc.exists() else waves),
        "-i", str(piano),
        "-filter_complex", fc,
        "-map", "[aout]", "-t", str(total),
        "-c:a", "aac", "-b:a", "320k",
        str(dst),
    ])


def main() -> int:
    clips = WORK / "clips"
    clips.mkdir(parents=True, exist_ok=True)
    EXPORT.mkdir(parents=True, exist_ok=True)

    # 1 Breath — harbor (no face)
    render("MVI_0372.MP4", clips / "01_breath.mp4",
           start=0.6, duration=3.4, speed=0.88, fade_in=1.0)

    # 2 Lead from behind — cinematic, handsome silhouette
    render("MVI_0350.MP4", clips / "02_gaze.mp4",
           start=8.0, duration=4.5, speed=0.86,
           crop_y="(ih-oh)/2+120")  # favor subject lower third

    # 3 Best profile — writing under palm (most flattering)
    render("MVI_0358.MP4", clips / "03_profile.mp4",
           start=2.0, duration=5.0, speed=0.88, beauty=True,
           crop_y="(ih-oh)/2+40")

    # 4 Hands detail
    render("MVI_0356.MP4", clips / "04_hands.mp4",
           start=4.0, duration=3.6, speed=0.82, beauty=True)

    # 5 Handsome face — 0353 three-quarter with soft ocean bokeh (better than harsh 0355)
    render("MVI_0353.MP4", clips / "05_face.mp4",
           start=14.0, duration=4.2, speed=0.85, beauty=True,
           crop_y="(ih-oh)/2+200")  # pull face up in frame

    # 6 Soft face writing — shorter, beauty heavy, flattering angle
    render("MVI_0355.MP4", clips / "06_face_write.mp4",
           start=6.0, duration=3.5, speed=0.85, beauty=True,
           crop_y="(ih-oh)/2+160")

    # 7 Scout moment — phone to sea
    render("MVI_0363.MP4", clips / "07_scout.mp4",
           start=8.0, duration=4.5, speed=0.88,
           crop_y="(ih-oh)/2+100")

    # 8 Phone + notebook by ocean
    render("MVI_0376.MP4", clips / "08_still.mp4",
           start=3.0, duration=4.0, speed=0.88, beauty=True)

    # 9 End title
    render_end(clips / "09_end.mp4")

    ordered = [clips / f"{n}.mp4" for n in [
        "01_breath", "02_gaze", "03_profile", "04_hands",
        "05_face", "06_face_write", "07_scout", "08_still", "09_end",
    ]]
    for c in ordered:
        print(f"  {c.name}: {probe_duration(c):.2f}s")

    inputs: list[str] = []
    for c in ordered:
        inputs += ["-i", str(c)]
    n = len(ordered)
    fc = "".join(f"[{i}:v]" for i in range(n)) + f"concat=n={n}:v=1:a=0[v]"
    silent = WORK / "picture.mp4"
    run([
        FF, "-y", *inputs, "-filter_complex", fc, "-map", "[v]",
        "-c:v", "h264_videotoolbox", "-b:v", "45M", "-pix_fmt", "yuv420p",
        str(silent),
    ])
    total = probe_duration(silent)
    print("Total:", total)

    audio = WORK / "mix.m4a"
    mix_audio(total, audio)

    master = EXPORT / "StillScout_ThePerfectStill_4K_9x16.mp4"
    run([
        FF, "-y", "-i", str(silent), "-i", str(audio),
        "-map", "0:v", "-map", "1:a",
        "-c:v", "copy", "-c:a", "aac", "-b:a", "320k",
        "-movflags", "+faststart", "-shortest",
        str(master),
    ])
    social = EXPORT / "StillScout_ThePerfectStill_1080x1920.mp4"
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
        "title": "StillScout — The Perfect Still (v3 beauty + audio)",
        "duration_sec": probe_duration(master),
        "music": "Kevin MacLeod — Dreams Become Real (CC BY / incompetech)",
        "ambience": "Mixkit ocean/wind + location air from MVI_0350",
        "master": str(master),
        "social": str(social),
    }
    (EXPORT / "manifest.json").write_text(json.dumps(meta, indent=2))
    (EXPORT / "AUDIO_CREDITS.txt").write_text(
        "Music: Dreams Become Real — Kevin MacLeod (incompetech.com)\n"
        "Licensed under Creative Commons: By Attribution 4.0\n"
        "https://creativecommons.org/licenses/by/4.0/\n\n"
        "SFX: Mixkit ocean waves / wind / seagulls (Mixkit License)\n"
        "Location ambience: recorded on source clips\n"
    )
    print(json.dumps(meta, indent=2))
    print("DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
