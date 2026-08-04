#!/usr/bin/env python3
"""StillScout v11 — Cinematic Brand Film

Emotion first. Product last.
No app UI, no feature copy, no marketing mid-film.
Soft piano + ocean / wind / gulls. Earned end reveal.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path("/Users/sandeshsomyahang/stillscout/film")
FOOTAGE = Path("/Users/sandeshsomyahang/Downloads/New Folder With Items")
FF = str(ROOT / "bin" / "ffmpeg")
FP = str(ROOT / "bin" / "ffprobe")
WORK = ROOT / "work_v11"
EXPORT = ROOT / "export"
AUDIO = ROOT / "audio" / "src_v5"
AUDIO_V3 = ROOT / "audio" / "src_v3"
MARK = ROOT / "assets" / "stillscout_mark_light.png"
W, H, FPS = 2160, 3840, 30

# Premium natural subject — clean skin texture, sharp eyes, warm film highlights
FACE = (
    "format=yuv420p,"
    "hqdn3d=2.0:1.3:2.6:1.8,"
    "bilateral=sigmaS=2.0:sigmaR=0.07,"
    "eq=contrast=0.96:brightness=0.032:saturation=0.88:gamma=1.04,"
    "curves="
    "red='0/0.04 0.28/0.33 0.55/0.60 1/0.995':"
    "green='0/0.04 0.28/0.32 0.55/0.57 1/0.98':"
    "blue='0/0.05 0.28/0.30 0.55/0.53 1/0.955',"
    "colorbalance=rs=0.04:gs=0.012:bs=-0.022:rm=0.048:gm=0.014:bm=-0.028:rh=0.02:gh=0.008:bh=-0.012,"
    "split[base][glow];[glow]gblur=sigma=6.5[g];"
    "[base][g]blend=all_mode=screen:all_opacity=0.075,"
    "unsharp=5:5:0.52:5:5:0.16,"
    "vignette=PI/5.2,"
    "noise=alls=2:allf=t"
)

DETAIL = (
    "format=yuv420p,"
    "hqdn3d=1.6:1.1:2.2:1.6,"
    "eq=contrast=0.98:brightness=0.03:saturation=0.92:gamma=1.03,"
    "curves=all='0/0.03 0.5/0.54 1/0.99',"
    "colorbalance=rs=0.028:gs=0.01:bs=-0.016:rm=0.035:gm=0.012:bm=-0.018,"
    "unsharp=5:5:0.42:5:5:0.1,"
    "vignette=PI/5.6,"
    "noise=alls=2:allf=t"
)

WIDE = (
    "format=yuv420p,"
    "hqdn3d=1.4:1:2:1.4,"
    "eq=contrast=1.02:brightness=0.02:saturation=0.94:gamma=1.02,"
    "curves=all='0/0.025 0.5/0.52 1/0.985',"
    "colorbalance=rs=0.02:gs=0.008:bs=-0.014,"
    "unsharp=5:5:0.38:5:5:0.08,"
    "noise=alls=2:allf=t"
)


def run(cmd: list[str]) -> None:
    print("+", " ".join(str(c) for c in cmd[:10]), "...")
    subprocess.run(cmd, check=True)


def probe(path: Path) -> float:
    return float(subprocess.check_output(
        [FP, "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        text=True,
    ).strip())


def motion(kind: str, dur: float, crop_y: str) -> str:
    comma = r"\,"
    if kind == "push":
        y = crop_y.replace("(ih-oh)/2", f"(ih-oh)/2-(t/{dur:.3f})*min(ih*0.028{comma}70)")
        return (
            f"scale={int(W*1.12)}:{int(H*1.12)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2':y='{y}'"
        )
    if kind == "pull":
        y = crop_y.replace("(ih-oh)/2", f"(ih-oh)/2+(t/{dur:.3f})*min(ih*0.022{comma}55)")
        return (
            f"scale={int(W*1.14)}:{int(H*1.14)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2':y='{y}'"
        )
    if kind == "rise":
        y = crop_y.replace("(ih-oh)/2", f"(ih-oh)/2-(t/{dur:.3f})*min(ih*0.03{comma}75)")
        return (
            f"scale={int(W*1.11)}:{int(H*1.11)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2':y='{y}'"
        )
    if kind == "drift":
        return (
            f"scale={int(W*1.12)}:{int(H*1.12)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:"
            f"x='(iw-ow)/2+(t/{dur:.3f})*min(iw*0.02{comma}45)':"
            f"y='{crop_y}'"
        )
    return (
        f"scale={W}:{H}:force_original_aspect_ratio=increase:flags=lanczos,"
        f"crop={W}:{H}:(iw-ow)/2:{crop_y}"
    )


def render(
    src: str, dst: Path, *, start: float, duration: float, speed: float = 1.0,
    grade: str = "detail", fade_in: float = 0.0, fade_out: float = 0.0,
    crop_y: str = "(ih-oh)/2", kind: str = "push",
) -> float:
    out_dur = duration / speed
    g = {"face": FACE, "detail": DETAIL, "wide": WIDE}[grade]
    vf = f"deshake=rx=16:ry=16,setpts=PTS/{speed},{motion(kind, out_dur, crop_y)},{g}"
    if fade_in:
        vf += f",fade=t=in:st=0:d={fade_in}"
    if fade_out:
        vf += f",fade=t=out:st={max(0.01, out_dur - fade_out)}:d={fade_out}"
    run([
        FF, "-y", "-ss", f"{start:.2f}", "-t", f"{duration:.2f}",
        "-i", str(FOOTAGE / src), "-vf", vf, "-an", "-r", str(FPS),
        "-c:v", "h264_videotoolbox", "-b:v", "48M", "-pix_fmt", "yuv420p",
        "-t", f"{out_dur:.3f}", str(dst),
    ])
    return probe(dst)


def assemble(clips: list[Path], durs: list[float], dst: Path, xfade: float = 0.48) -> float:
    inputs: list[str] = []
    for c in clips:
        inputs += ["-i", str(c)]
    parts = [f"[0:v][1:v]xfade=transition=fade:duration={xfade}:offset={durs[0] - xfade:.3f}[v01]"]
    prev, acc = "v01", durs[0] + durs[1] - xfade
    for i in range(2, len(clips)):
        offset = acc - xfade
        out = "vout" if i == len(clips) - 1 else f"v{i:02d}"
        parts.append(
            f"[{prev}][{i}:v]xfade=transition=fade:duration={xfade}:offset={offset:.3f}[{out}]"
        )
        prev = out
        acc += durs[i] - xfade
    total = sum(durs) - xfade * (len(clips) - 1)
    run([
        FF, "-y", *inputs, "-filter_complex", ";".join(parts),
        "-map", "[vout]",
        "-c:v", "h264_videotoolbox", "-b:v", "48M",
        "-pix_fmt", "yuv420p", "-t", f"{total:.3f}", str(dst),
    ])
    return probe(dst)


def render_book_logo(dst: Path) -> float:
    """Hand-drawn mark in the notebook — bridge into brand."""
    duration, speed = 3.2, 0.90
    out_dur = duration / speed
    comma = r"\,"
    vf = (
        f"deshake=rx=16:ry=16,setpts=PTS/{speed},"
        f"scale={int(W*1.20)}:{int(H*1.20)}:force_original_aspect_ratio=increase:flags=lanczos,"
        f"crop={W}:{H}:"
        f"x='(iw-ow)*0.68+(t/{out_dur:.3f})*min(iw*0.018{comma}36)':"
        f"y='(ih-oh)/2-(t/{out_dur:.3f})*min(ih*0.025{comma}60)',"
        f"{DETAIL},fade=t=in:st=0:d=0.4"
    )
    run([
        FF, "-y", "-ss", "0.55", "-t", f"{duration:.2f}",
        "-i", str(FOOTAGE / "MVI_0390.MP4"), "-vf", vf, "-an", "-r", str(FPS),
        "-c:v", "h264_videotoolbox", "-b:v", "48M", "-pix_fmt", "yuv420p",
        "-t", f"{out_dur:.3f}", str(dst),
    ])
    return probe(dst)


def end_logo_plate(dst: Path, *, dur: float = 6.0) -> float:
    logo = MARK if MARK.exists() else ROOT / "assets" / "stillscout_mark.png"
    comma = r"\,"
    fc = (
        f"color=c=0x0C0B0A:s={W}x{H}:d={dur}:r={FPS},format=yuv420p,"
        f"vignette=PI/3.5[bg];"
        f"[0:v]format=rgba,scale=720:720,"
        f"fade=t=in:st=0:d=0.85:alpha=1,"
        f"fade=t=out:st={dur-1.35:.2f}:d=1.2:alpha=1[lg];"
        f"[bg][lg]overlay=x='(W-w)/2':"
        f"y='H*0.28-h/2+32*(1-min(1{comma}max(0{comma}(t-0.4)/1.0)))':"
        f"format=auto[v1];"
        f"[v1]"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Didot.ttc:"
        f"text='StillScout':fontsize=138:fontcolor=0xFFFAF5@0.0:"
        f"x=(w-text_w)/2:y=h*0.60:"
        f"alpha='if(lt(t,1.1),0,if(lt(t,2.1),(t-1.1)/1.0,if(gt(t,{dur-1.25:.2f}),"
        f"({dur:.2f}-t)/1.25,0.98)))',"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Georgia.ttf:"
        f"text='Scout the perfect still.':fontsize=56:fontcolor=0xF2E8DA@0.0:"
        f"x=(w-text_w)/2:y=h*0.60+150:"
        f"alpha='if(lt(t,1.9),0,if(lt(t,2.8),(t-1.9)/0.9,if(gt(t,{dur-1.2:.2f}),"
        f"({dur:.2f}-t)/1.2,0.93)))',"
        f"drawbox=x=(iw-360)/2:y=ih*0.565:w=360:h=2:color=0xD4B88C@0.9:t=fill:"
        f"enable='between(t,1.0,{dur-1.2:.2f})',"
        f"fade=t=in:st=0:d=0.3,fade=t=out:st={dur-1.25:.2f}:d=1.25[vout]"
    )
    run([
        FF, "-y", "-loop", "1", "-i", str(logo),
        "-filter_complex", fc, "-map", "[vout]",
        "-t", f"{dur:.3f}",
        "-c:v", "h264_videotoolbox", "-b:v", "40M", "-pix_fmt", "yuv420p",
        str(dst),
    ])
    return probe(dst)


def end_book_to_brand(dst: Path) -> float:
    book = WORK / "clips" / "09a_book.mp4"
    plate = WORK / "clips" / "09b_plate.mp4"
    d_book = render_book_logo(book)
    d_plate = end_logo_plate(plate, dur=6.0)
    xfade = 0.90
    offset = max(0.2, d_book - xfade)
    total = d_book + d_plate - xfade
    run([
        FF, "-y", "-i", str(book), "-i", str(plate),
        "-filter_complex",
        f"[0:v][1:v]xfade=transition=fade:duration={xfade}:offset={offset:.3f}[vout]",
        "-map", "[vout]",
        "-c:v", "h264_videotoolbox", "-b:v", "48M", "-pix_fmt", "yuv420p",
        "-t", f"{total:.3f}", str(dst),
    ])
    return probe(dst)


def mix_audio(total: float, marks: dict[str, float], dst: Path) -> None:
    def ms(s: float) -> int:
        return max(0, int(s * 1000))

    piano = AUDIO_V3 / "km_peaceful.mp3"
    if not piano.exists() or piano.stat().st_size < 5000:
        piano = AUDIO / "piano.mp3"

    t_hands = marks["hands"]
    t_profile = marks["profile"]
    t_face = marks["face"]
    t_harbor = marks["harbor"]
    t_sky = marks["sky"]
    t_end = marks["end"]
    # Piano sits under full VO; harder duck at brand for tagline
    brand_duck = max(0.5, t_end + 0.8)
    scribble_len = max(2.0, t_profile - t_hands + 0.4)

    fc = (
        # beds — always audible under VO
        f"[0:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=65,lowpass=f=9000,volume=0.38,"
        f"afade=t=in:st=0:d=2.0,afade=t=out:st={total-2.6}:d=2.6[ocean];"
        f"[1:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=180,lowpass=f=3400,volume=0.10,"
        f"afade=t=in:st=0:d=2.2[wind];"
        f"[2:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"volume=0.09,highpass=f=850,lowpass=f=5600,"
        f"afade=t=in:st={t_harbor:.2f}:d=2.2,afade=t=out:st={total-3.0}:d=2.5[gulls];"
        # soft emotional piano — VO headroom body, duck at brand reveal
        f"[3:a]adelay={ms(1.8)}|{ms(1.8)},atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=90,lowpass=f=5400,"
        f"acompressor=threshold=-24dB:ratio=2.4:attack=60:release=350,"
        f"volume=0.24,afade=t=in:st=0:d=3.5,"
        f"volume='if(lt(t,{brand_duck:.2f}),1.0,0.22)',"
        f"afade=t=out:st={total-2.8}:d=2.8[piano];"
        # light Foley — never loud enough to feel like an ad
        f"[4:a]aloop=loop=-1:size=2e+09,atrim=0:{scribble_len:.2f},asetpts=N/SR/TB,"
        f"adelay={ms(t_hands)}|{ms(t_hands)},"
        f"highpass=f=800,lowpass=f=9500,volume=0.55,"
        f"afade=t=in:st=0:d=0.25,afade=t=out:st={scribble_len-0.6:.2f}:d=0.6,"
        f"atrim=0:{total},asetpts=N/SR/TB[scribble];"
        f"[5:a]adelay={ms(0.3)}|{ms(0.3)},volume=0.55,atrim=0:{total},asetpts=N/SR/TB[book];"
        f"[6:a]adelay={ms(0.9)}|{ms(0.9)},volume=0.42,atrim=0:{total},asetpts=N/SR/TB[page1];"
        f"[6:a]adelay={ms(t_end+0.2)}|{ms(t_end+0.2)},volume=0.48,atrim=0:{total},asetpts=N/SR/TB[page2];"
        f"[7:a]adelay={ms(t_profile)}|{ms(t_profile)},volume=0.28,atrim=0:{total},asetpts=N/SR/TB[fab];"
        f"[8:a]adelay={ms(t_harbor)}|{ms(t_harbor)},volume=0.22,lowpass=f=3800,atrim=0:{total},asetpts=N/SR/TB[whoosh1];"
        f"[8:a]adelay={ms(t_end+3.4)}|{ms(t_end+3.4)},volume=0.20,lowpass=f=2600,atrim=0:{total},asetpts=N/SR/TB[whoosh2];"
        f"[ocean][wind][gulls][piano][scribble][book][page1][page2][fab][whoosh1][whoosh2]"
        f"amix=inputs=11:normalize=0:dropout_transition=2,"
        f"equalizer=f=220:t=q:w=1:g=-1.5,"
        f"equalizer=f=3600:t=q:w=1:g=1.2,"
        f"alimiter=limit=0.90,loudnorm=I=-16:TP=-1.5:LRA=10[aout]"
    )
    inputs = [
        AUDIO / "ocean.mp3", AUDIO / "wind.mp3", AUDIO / "seagulls.mp3", piano,
        AUDIO / "writing_1.mp3", AUDIO / "book_open.mp3", AUDIO / "page_turn_soft.mp3",
        AUDIO / "fabric_2.mp3", AUDIO / "soft_whoosh.mp3",
    ]
    # soft_whoosh may be named air_whoosh
    if not inputs[-1].exists():
        inputs[-1] = AUDIO / "air_whoosh.mp3"
    cmd = [FF, "-y"]
    for p in inputs:
        cmd += ["-i", str(p)]
    cmd += [
        "-filter_complex", fc, "-map", "[aout]", "-t", str(total),
        "-c:a", "aac", "-b:a", "320k", str(dst),
    ]
    run(cmd)


def export_safe(src: Path, mp4: Path, mov: Path) -> None:
    run([
        FF, "-y", "-i", str(src),
        "-vf", "scale=1080:1920:flags=lanczos,format=yuv420p",
        "-c:v", "libx264", "-preset", "fast", "-crf", "17",
        "-profile:v", "high", "-level", "4.1",
        "-pix_fmt", "yuv420p",
        "-colorspace", "bt709", "-color_primaries", "bt709",
        "-color_trc", "bt709", "-color_range", "tv",
        "-movflags", "+faststart",
        "-c:a", "aac", "-b:a", "256k",
        str(mp4),
    ])
    run([FF, "-y", "-i", str(mp4), "-c", "copy", str(mov)])


def write_narration(total: float, marks: dict[str, float]) -> None:
    """Canonical VO — timed to actual picture marks."""
    t0 = 0.0
    t_nb = marks.get("notebook", 3.5)
    t_hands = marks["hands"]
    t_profile = marks["profile"]
    t_face = marks["face"]
    t_harbor = marks["harbor"]
    t_sky = marks["sky"]
    t_settle = marks.get("settle", marks["end"] - 3.0)
    t_end = marks["end"]
    # Brand wordmark lands ~3.5s into end block (after book → logo dissolve)
    t_brand = t_end + 3.5
    t_brand_end = max(t_brand + 3.0, total - 0.6)

    def mmss(s: float) -> str:
        m = int(s // 60)
        sec = s - m * 60
        return f"{m}:{sec:05.2f}" if m else f"0:{sec:05.2f}"

    text = f"""# StillScout — Cinematic Brand Film VO (v11)

**Length:** ~{total:.1f}s  
**File:** `StillScout_PLAY_ME_1080x1920.mov`  
**Tone:** quiet, close, timeless — like reading a letter aloud  
**Rule:** emotion first. Brand lines only after the logo reveal.

---

## Canonical VO (exact words)

```
Some moments pass before we even realize they're happening.
A smile. A glance. A quiet breath.
Time keeps moving, whether we're ready or not.
But some moments deserve more than a memory—they deserve to last forever.

StillScout.
Scout the perfect still.
```

---

## Timed to picture

| Window | Picture | Say |
|--------|---------|-----|
| {mmss(t0)} – {mmss(t_nb + 0.4)} | Horizon / notebook | *(short breath — optional silence)* |
| {mmss(t_nb)} – {mmss(t_profile)} | Notebook → hands | Some moments pass before we even realize they're happening. |
| {mmss(t_hands + 0.6)} – {mmss(t_face)} | Hands → profile | A smile. A glance. A quiet breath. |
| {mmss(t_face)} – {mmss(t_sky)} | Face → harbor | Time keeps moving, whether we're ready or not. |
| {mmss(t_harbor + 0.3)} – {mmss(t_end)} | Harbor → sky → settle | But some moments deserve more than a memory—they deserve to last forever. |
| {mmss(t_end)} – {mmss(t_brand)} | Book logo | *(hold — let the page become the mark)* |
| {mmss(t_brand)} – {mmss(t_brand_end)} | Real logo | **StillScout.** Scout the perfect still. |

### Cue marks (seconds)

- VO body start: **{t_nb:.1f}s** (or soft from **{t_hands:.1f}s**)
- VO body end (before brand): **{t_end:.1f}s**
- Brand lines: **{t_brand:.1f}s – {t_brand_end:.1f}s**
- Film end: **{total:.1f}s**

### Picture marks

```
horizon  {marks.get('horizon', 0):.2f}
notebook {marks.get('notebook', 0):.2f}
hands    {marks['hands']:.2f}
profile  {marks['profile']:.2f}
face     {marks['face']:.2f}
harbor   {marks['harbor']:.2f}
sky      {marks['sky']:.2f}
settle   {t_settle:.2f}
end      {t_end:.2f}
```

---

## Recording notes

1. Soft, close mic — unhurried. Leave air after each short beat (“A smile. A glance.”).
2. Do **not** say StillScout until the clean mark is on screen (~{t_brand:.0f}s).
3. Piano ducks at brand; ocean / wind stay under you the whole way.
4. Bed file: `StillScout_VO_BED_1080x1920.mp4`
"""
    (EXPORT / "NARRATION_SCRIPT.md").write_text(text)
    (EXPORT / "NARRATION_SCRIPT_v11.md").write_text(text)


def main() -> int:
    clips = WORK / "clips"
    clips.mkdir(parents=True, exist_ok=True)
    EXPORT.mkdir(parents=True, exist_ok=True)

    plan: list[tuple[Path, float, str]] = []

    # 1 Cold open — gaze to the horizon (movie trailer open)
    d = render("MVI_0350.MP4", clips / "01_horizon.mp4",
               start=8.2, duration=3.6, speed=0.88, grade="wide", fade_in=1.0,
               crop_y="(ih-oh)/2+90", kind="rise")
    plan.append((clips / "01_horizon.mp4", d, "horizon"))

    # 2 Notebook — intimate detail, no brand yet
    d = render("MVI_0387.MP4", clips / "02_pages.mp4",
               start=0.8, duration=3.2, speed=0.90, grade="detail",
               crop_y="(ih-oh)/2-40", kind="push")
    plan.append((clips / "02_pages.mp4", d, "notebook"))

    # 3 Hands — wind / writing texture
    d = render("MVI_0356.MP4", clips / "03_hands.mp4",
               start=5.0, duration=3.5, speed=0.78, grade="detail",
               crop_y="(ih-oh)/2", kind="drift")
    plan.append((clips / "03_hands.mp4", d, "hands"))

    # 4 Hero profile — luxury linger
    d = render("MVI_0358.MP4", clips / "04_profile.mp4",
               start=2.3, duration=5.2, speed=0.84, grade="face",
               crop_y="(ih-oh)/2+35", kind="rise")
    plan.append((clips / "04_profile.mp4", d, "profile"))

    # 5 Eyes / face — shallow, natural catchlights
    d = render("MVI_0353.MP4", clips / "05_face.mp4",
               start=16.8, duration=4.4, speed=0.82, grade="face",
               crop_y="(ih-oh)/2+300", kind="rise")
    plan.append((clips / "05_face.mp4", d, "face"))

    # 6 World opens — harbor
    d = render("MVI_0343.MP4", clips / "06_harbor.mp4",
               start=0.9, duration=4.0, speed=0.90, grade="wide",
               crop_y="(ih-oh)/2+55", kind="pull")
    plan.append((clips / "06_harbor.mp4", d, "harbor"))

    # 7 Sky breath — wind in hair / air
    d = render("MVI_0365.MP4", clips / "07_sky.mp4",
               start=8.2, duration=4.0, speed=0.88, grade="wide",
               crop_y="(ih-oh)/2", kind="push")
    plan.append((clips / "07_sky.mp4", d, "sky"))

    # 8 Soft settle — genuine, quiet
    d = render("MVI_0359.MP4", clips / "08_settle.mp4",
               start=5.0, duration=3.0, speed=0.90, grade="face",
               crop_y="(ih-oh)/2+75", kind="rise")
    plan.append((clips / "08_settle.mp4", d, "settle"))

    # 9 Earned reveal — book logo → StillScout
    end = clips / "09_brand.mp4"
    d = end_book_to_brand(end)
    plan.append((end, d, "end"))

    marks_raw: dict[str, float] = {}
    cum = 0.0
    for path, dur, name in plan:
        marks_raw[name] = cum
        print(f"  {path.name}: {dur:.2f}s @{cum:.2f}")
        cum += dur

    paths = [p for p, _, _ in plan]
    durs = [d for _, d, _ in plan]
    xfade = 0.48
    picture = WORK / "picture.mp4"
    total = assemble(paths, durs, picture, xfade=xfade)
    marks = {n: max(0.0, marks_raw[n] - xfade * i) for i, (_, _, n) in enumerate(plan)}
    print("Picture:", total)
    print("Marks:", {k: round(v, 2) for k, v in marks.items()})

    audio = WORK / "mix.m4a"
    mix_audio(total, marks, audio)

    master = WORK / "master.mp4"
    run([
        FF, "-y", "-i", str(picture), "-i", str(audio),
        "-map", "0:v", "-map", "1:a",
        "-c:v", "copy", "-c:a", "aac", "-b:a", "320k",
        "-shortest", "-movflags", "+faststart", str(master),
    ])

    play = EXPORT / "StillScout_PLAY_ME_1080x1920.mp4"
    mov = EXPORT / "StillScout_PLAY_ME_1080x1920.mov"
    best = EXPORT / "StillScout_Best_1080x1920.mp4"
    vo = EXPORT / "StillScout_VO_BED_1080x1920.mp4"
    brand4k = EXPORT / "StillScout_BrandFilm_4K_9x16.mp4"
    export_safe(master, play, mov)
    run(["cp", str(play), str(best)])
    run(["cp", str(play), str(vo)])
    run(["cp", str(master), str(brand4k)])

    write_narration(total, marks)

    meta = {
        "title": "StillScout — Cinematic Brand Film (v11)",
        "duration_sec": probe(play),
        "creative": [
            "emotion first — no app mention until final reveal",
            "long breathing shots + soft dissolves",
            "premium natural subject grade",
            "soft piano + ocean / wind / gulls throughout",
            "book logo (MVI_0390) → StillScout mark animation",
            "player-safe x264 + mov",
        ],
        "marks": {k: round(v, 2) for k, v in marks.items()},
        "vo_body_sec": [round(marks.get("notebook", marks["hands"]), 1), round(marks["end"], 1)],
        "brand_line_sec": [round(marks["end"] + 3.5, 1), round(total - 0.6, 1)],
        "canonical_vo": (
            "Some moments pass before we even realize they're happening. "
            "A smile. A glance. A quiet breath. "
            "Time keeps moving, whether we're ready or not. "
            "But some moments deserve more than a memory—they deserve to last forever."
        ),
        "brand_vo": "StillScout. Scout the perfect still.",
        "play_mp4": str(play),
        "play_mov": str(mov),
        "master_4k": str(brand4k),
    }
    (EXPORT / "manifest_v11.json").write_text(json.dumps(meta, indent=2))
    (EXPORT / "AUDIO_CREDITS_v11.txt").write_text(
        "Music: Peaceful Desolation — Kevin MacLeod (incompetech.com) CC BY 4.0\n"
        "Ambience: Mixkit ocean / wind / seagulls\n"
        "Foley: soft page / fabric / whoosh (picture-locked, low)\n"
    )
    print(json.dumps(meta, indent=2))
    print("DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
