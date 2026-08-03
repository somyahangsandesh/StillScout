#!/usr/bin/env python3
"""StillScout short film — The Perfect Still
Build pipeline: grade, assemble, mix, title, export 4K 9:16.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageOps

ROOT = Path("/Users/sandeshsomyahang/stillscout/film")
FOOTAGE = Path("/Users/sandeshsomyahang/Downloads/New Folder With Items 2")
FF = str(ROOT / "bin" / "ffmpeg")
FP = str(ROOT / "bin" / "ffprobe")
WORK = ROOT / "work"
EXPORT = ROOT / "export"
AUDIO = ROOT / "audio"
W, H = 2160, 3840
FPS = 30

# Korean-drama style grade after Rec.709
GRADE = (
    "eq=contrast=0.90:brightness=0.035:saturation=0.80,"
    "curves=all='0/0.05 0.25/0.30 0.5/0.54 0.75/0.78 1/0.96',"
    "colorbalance=rs=0.02:gs=0.008:bs=-0.012:rm=0.02:gm=0.01:bm=-0.015:rh=0.01:gh=0.005:bh=-0.008,"
    "gblur=sigma=0.55,"
    "unsharp=7:7:0.45:5:5:0.0"
)

TONEMAP = (
    "zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,"
    "tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p"
)


def run(cmd: list[str], check: bool = True) -> subprocess.CompletedProcess:
    print("+", " ".join(cmd[:8]), "..." if len(cmd) > 8 else "")
    return subprocess.run(cmd, check=check)


def probe_duration(path: Path) -> float:
    out = subprocess.check_output(
        [FP, "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        text=True,
    ).strip()
    return float(out)


def scale_pad_filter(extra: str = "") -> str:
    """Fit any frame into 2160x3840 with soft cover crop, then grade."""
    base = (
        f"scale={W}:{H}:force_original_aspect_ratio=increase:flags=lanczos,"
        f"crop={W}:{H},"
        f"{GRADE}"
    )
    if extra:
        return f"{extra},{base}"
    return base


def render_video_clip(
    src: Path,
    dst: Path,
    *,
    start: float,
    duration: float,
    speed: float = 1.0,
    hlg: bool = True,
    fade_in: float = 0.0,
    fade_out: float = 0.0,
) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    # setpts for speed; trim after decode
    vf_parts = []
    if hlg:
        vf_parts.append(TONEMAP)
    # Mild deshake for handheld
    vf_parts.append("deshake=rx=16:ry=16")
    vf_parts.append(scale_pad_filter())
    out_dur = duration / speed
    if fade_in > 0:
        vf_parts.append(f"fade=t=in:st=0:d={fade_in}")
    if fade_out > 0:
        vf_parts.append(f"fade=t=out:st={max(0, out_dur - fade_out)}:d={fade_out}")
    vf = ",".join(vf_parts)
    # Apply speed via setpts after filters that care about time? Apply before fade times in out timebase
    # Rebuild with setpts integrated:
    vf_parts = []
    if hlg:
        vf_parts.append(TONEMAP)
    vf_parts.append("deshake=rx=16:ry=16")
    vf_parts.append(f"setpts=PTS/{speed}")
    vf_parts.append(scale_pad_filter())
    if fade_in > 0:
        vf_parts.append(f"fade=t=in:st=0:d={fade_in}")
    if fade_out > 0:
        vf_parts.append(f"fade=t=out:st={max(0.01, out_dur - fade_out)}:d={fade_out}")
    vf = ",".join(vf_parts)

    cmd = [
        FF, "-y",
        "-ss", str(start),
        "-t", str(duration),
        "-i", str(src),
        "-vf", vf,
        "-an",
        "-r", str(FPS),
        "-c:v", "libx264",
        "-preset", "medium",
        "-crf", "16",
        "-pix_fmt", "yuv420p",
        "-t", f"{out_dur:.3f}",
        str(dst),
    ]
    run(cmd)


def grade_still(src: Path, dst: Path) -> None:
    """Load still, rotate if needed, apply soft K-drama look with Pillow, save PNG."""
    im = Image.open(src)
    im = ImageOps.exif_transpose(im)
    im = im.convert("RGB")

    # Soft contrast / lifted blacks via point curves
    def lift(v: int) -> int:
        x = v / 255.0
        # soft S with lifted floor
        y = 0.05 + 0.91 * (x ** 0.95)
        y = min(1.0, max(0.0, y))
        return int(y * 255)

    im = im.point(lift)
    im = ImageEnhance.Color(im).enhance(0.82)
    im = ImageEnhance.Brightness(im).enhance(1.04)
    im = ImageEnhance.Contrast(im).enhance(0.92)
    # Gentle bloom
    blur = im.filter(ImageFilter.GaussianBlur(radius=2.2))
    im = Image.blend(im, blur, 0.18)
    dst.parent.mkdir(parents=True, exist_ok=True)
    im.save(dst, quality=95)


def ken_burns(
    still_graded: Path,
    dst: Path,
    *,
    seconds: float,
    zoom_end: float = 1.12,
    fade_in: float = 0.0,
    fade_out: float = 0.0,
) -> None:
    """Slow push-in Ken Burns into 9:16."""
    frames = int(seconds * FPS)
    # Pre-cover into tall canvas
    im = Image.open(still_graded).convert("RGB")
    # Scale to cover
    scale = max(W / im.width, H / im.height) * zoom_end
    base_w = int(im.width * scale)
    base_h = int(im.height * scale)
    im = im.resize((base_w, base_h), Image.Resampling.LANCZOS)
    # Center crop at start zoom=1.0 relative to zoom_end canvas... simpler: zoompan in ffmpeg
    tmp = WORK / "stills" / f"{still_graded.stem}_full.jpg"
    tmp.parent.mkdir(parents=True, exist_ok=True)
    # Make oversized image for zoompan
    cover = Image.open(still_graded).convert("RGB")
    # Ensure portrait-friendly canvas at least 2160x3840 * zoom
    target_w, target_h = int(W * zoom_end), int(H * zoom_end)
    # cover-fit
    r = max(target_w / cover.width, target_h / cover.height)
    nw, nh = int(cover.width * r), int(cover.height * r)
    cover = cover.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - target_w) // 2
    top = (nh - target_h) // 2
    cover = cover.crop((left, top, left + target_w, top + target_h))
    cover.save(tmp, quality=95)

    # zoom from 1.0 to zoom_end over frames on the oversized image sized target
    # Use ffmpeg zoompan on image looped
    z_expr = f"min(1+({zoom_end}-1)*on/{frames},{zoom_end})"
    x_expr = f"(iw-iw/zoom)/2"
    y_expr = f"(ih-ih/zoom)/2"
    vf = (
        f"zoompan=z='{z_expr}':x='{x_expr}':y='{y_expr}':d={frames}:s={W}x{H}:fps={FPS},"
        f"{GRADE}"
    )
    if fade_in > 0:
        vf += f",fade=t=in:st=0:d={fade_in}"
    if fade_out > 0:
        vf += f",fade=t=out:st={max(0.01, seconds - fade_out)}:d={fade_out}"

    cmd = [
        FF, "-y",
        "-loop", "1",
        "-i", str(tmp),
        "-vf", vf,
        "-frames:v", str(frames),
        "-r", str(FPS),
        "-c:v", "libx264",
        "-preset", "medium",
        "-crf", "16",
        "-pix_fmt", "yuv420p",
        str(dst),
    ]
    run(cmd)


def make_end_card_overlay(notebook_still: Path, dst: Path, seconds: float = 6.0) -> None:
    """Ken Burns notebook + elegant StillScout typography burned in."""
    graded = WORK / "stills" / "notebook_graded.jpg"
    grade_still(notebook_still, graded)

    # Render text frame PNG transparent
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    try:
        font_title = ImageFont.truetype(
            "/System/Library/Fonts/Supplemental/Didot.ttc", 140
        )
        font_sub = ImageFont.truetype(
            "/System/Library/Fonts/Supplemental/Georgia.ttf", 64
        )
    except OSError:
        font_title = ImageFont.load_default()
        font_sub = font_title

    title = "StillScout"
    sub = "Scout the perfect still."
    # Measure
    tb = draw.textbbox((0, 0), title, font=font_title)
    sb = draw.textbbox((0, 0), sub, font=font_sub)
    tw, th = tb[2] - tb[0], tb[3] - tb[1]
    sw, sh = sb[2] - sb[0], sb[3] - sb[1]
    # Place lower-center with soft dark scrim for legibility
    cx = W // 2
    ty = int(H * 0.78)
    pad = 80
    scrim_top = ty - 40
    scrim = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(scrim)
    sdraw.rectangle(
        [0, scrim_top, W, H],
        fill=(20, 24, 28, 90),
    )
    overlay = Image.alpha_composite(scrim, overlay)
    draw = ImageDraw.Draw(overlay)
    draw.text((cx - tw / 2, ty), title, font=font_title, fill=(255, 252, 248, 245))
    draw.text(
        (cx - sw / 2, ty + th + 36),
        sub,
        font=font_sub,
        fill=(245, 240, 232, 220),
    )
    text_png = WORK / "stills" / "end_text.png"
    overlay.save(text_png)

    # Build ken burns base without grade twice — grade already on still
    frames = int(seconds * FPS)
    tmp = WORK / "stills" / "notebook_cover.jpg"
    cover = Image.open(graded).convert("RGB")
    zoom_end = 1.08
    target_w, target_h = int(W * zoom_end), int(H * zoom_end)
    r = max(target_w / cover.width, target_h / cover.height)
    nw, nh = int(cover.width * r), int(cover.height * r)
    cover = cover.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - target_w) // 2
    top = (nh - target_h) // 2
    cover = cover.crop((left, top, left + target_w, top + target_h))
    cover.save(tmp, quality=95)

    z_expr = f"min(1+(0.08)*on/{frames},1.08)"
    vf = (
        f"zoompan=z='{z_expr}':x='(iw-iw/zoom)/2':y='(ih-ih/zoom)/2':d={frames}:s={W}x{H}:fps={FPS},"
        f"fade=t=in:st=0:d=0.6,fade=t=out:st={seconds - 1.2}:d=1.2"
    )
    base_mp4 = WORK / "clips" / "07_notebook_base.mp4"
    run([
        FF, "-y", "-loop", "1", "-i", str(tmp),
        "-vf", vf, "-frames:v", str(frames), "-r", str(FPS),
        "-c:v", "libx264", "-preset", "medium", "-crf", "16", "-pix_fmt", "yuv420p",
        str(base_mp4),
    ])

    # Overlay text with fade-in starting at 1.2s
    run([
        FF, "-y",
        "-i", str(base_mp4),
        "-i", str(text_png),
        "-filter_complex",
        f"[1:v]format=rgba,fade=t=in:st=1.2:d=1.0:alpha=1[txt];"
        f"[0:v][txt]overlay=0:0:format=auto",
        "-c:v", "libx264", "-preset", "medium", "-crf", "16", "-pix_fmt", "yuv420p",
        "-t", str(seconds),
        str(dst),
    ])


def mix_audio(total_dur: float, dst: Path) -> None:
    src = AUDIO / "src"
    waves = src / "waves2.mp3"
    seagulls = src / "seagulls.mp3"
    piano = src / "soft_piano.mp3"
    if (src / "music_148.mp3").exists():
        # Prefer quieter longer bed; we'll use soft_piano for intimacy
        pass
    breeze = src / "breeze.mp3"
    loc = AUDIO / "raw" / "0371.wav"

    # Build layered mix with delays / volumes
    # Piano enters at 10s
    filter_complex = (
        f"[0:a]aloop=loop=-1:size=2e+09,atrim=0:{total_dur},asetpts=N/SR/TB,"
        f"volume=0.55,afade=t=in:st=0:d=1.5,afade=t=out:st={total_dur-2}:d=2[waves];"
        f"[1:a]aloop=loop=-1:size=2e+09,atrim=0:{total_dur},asetpts=N/SR/TB,"
        f"volume=0.18,afade=t=in:st=3:d=2,afade=t=out:st={total_dur-2.5}:d=2.5[gulls];"
        f"[2:a]aloop=loop=-1:size=2e+09,atrim=0:{total_dur},asetpts=N/SR/TB,"
        f"volume=0.22,afade=t=in:st=0:d=2,highpass=f=200,lowpass=f=4000[wind];"
        f"[3:a]atrim=0:{total_dur},asetpts=N/SR/TB,volume=0.12,"
        f"afade=t=in:st=0:d=1,afade=t=out:st={total_dur-2}:d=2[loc];"
        f"[4:a]adelay=10000|10000,atrim=0:{total_dur},asetpts=N/SR/TB,"
        f"volume=0.38,afade=t=in:st=0:d=2.5,afade=t=out:st={total_dur-2.2}:d=2.2,"
        f"lowpass=f=8000[piano];"
        f"[waves][gulls][wind][loc][piano]amix=inputs=5:normalize=0:dropout_transition=2,"
        f"alimiter=limit=0.95,loudnorm=I=-16:TP=-1.5:LRA=11[aout]"
    )
    run([
        FF, "-y",
        "-i", str(waves),
        "-i", str(seagulls),
        "-i", str(breeze if breeze.exists() else src / "wind.mp3"),
        "-i", str(loc if loc.exists() else waves),
        "-i", str(piano),
        "-filter_complex", filter_complex,
        "-map", "[aout]",
        "-t", str(total_dur),
        "-c:a", "aac", "-b:a", "320k",
        str(dst),
    ])


def concat_clips(clips: list[Path], dst: Path) -> None:
    """Concat demuxer — clips already same format."""
    lst = WORK / "concat.txt"
    with lst.open("w") as f:
        for c in clips:
            f.write(f"file '{c}'\n")
    run([
        FF, "-y", "-f", "concat", "-safe", "0", "-i", str(lst),
        "-c:v", "libx264", "-preset", "medium", "-crf", "16", "-pix_fmt", "yuv420p",
        "-r", str(FPS),
        str(dst),
    ])


def mux(video: Path, audio: Path, dst: Path) -> None:
    run([
        FF, "-y",
        "-i", str(video),
        "-i", str(audio),
        "-c:v", "libx264", "-preset", "slow", "-crf", "15",
        "-profile:v", "high", "-level", "5.1",
        "-pix_fmt", "yuv420p",
        "-movflags", "+faststart",
        "-c:a", "aac", "-b:a", "320k",
        "-shortest",
        str(dst),
    ])


def main() -> int:
    WORK.mkdir(parents=True, exist_ok=True)
    (WORK / "clips").mkdir(exist_ok=True)
    (WORK / "stills").mkdir(exist_ok=True)
    EXPORT.mkdir(parents=True, exist_ok=True)

    clips_dir = WORK / "clips"

    # --- 1. Opening ocean (0371) fade in, slight slow ---
    render_video_clip(
        FOOTAGE / "IMG_0371.MOV",
        clips_dir / "01_ocean.mp4",
        start=0.4,
        duration=3.6,
        speed=0.88,
        hlg=True,
        fade_in=0.9,
        fade_out=0.0,
    )

    # --- 2. Peace Boat harbor (0373) ---
    render_video_clip(
        FOOTAGE / "IMG_0373.MOV",
        clips_dir / "02_harbor.mp4",
        start=0.5,
        duration=5.5,
        speed=0.92,
        hlg=True,
    )

    # --- 3. Boat wake (5168) ProRes Rec.709-ish, no HLG ---
    render_video_clip(
        FOOTAGE / "IMG_5168.MOV",
        clips_dir / "03_wake.mp4",
        start=0.15,
        duration=3.9,
        speed=0.85,
        hlg=False,
    )

    # --- 4. Portrait Ken Burns ---
    portrait = WORK / "stills" / "portrait_graded.jpg"
    grade_still(FOOTAGE / "IMG_0422.JPG", portrait)
    ken_burns(
        portrait,
        clips_dir / "04_portrait.mp4",
        seconds=5.0,
        zoom_end=1.14,
        fade_in=0.3,
    )

    # --- 5. Return to water (0375 spare / or 0371 end) ---
    render_video_clip(
        FOOTAGE / "IMG_0375.MOV",
        clips_dir / "05_return.mp4",
        start=0.3,
        duration=4.2,
        speed=0.90,
        hlg=True,
    )

    # --- 6. The Still (Peace Boat photo) ---
    still = WORK / "stills" / "peace_graded.jpg"
    grade_still(FOOTAGE / "IMG_0370.JPG", still)
    ken_burns(
        still,
        clips_dir / "06_thestill.mp4",
        seconds=4.0,
        zoom_end=1.08,
    )

    # --- 7. Brand notebook end ---
    make_end_card_overlay(
        FOOTAGE / "IMG_0411.JPG",
        clips_dir / "07_end.mp4",
        seconds=6.0,
    )

    ordered = [
        clips_dir / "01_ocean.mp4",
        clips_dir / "02_harbor.mp4",
        clips_dir / "03_wake.mp4",
        clips_dir / "04_portrait.mp4",
        clips_dir / "05_return.mp4",
        clips_dir / "06_thestill.mp4",
        clips_dir / "07_end.mp4",
    ]
    for c in ordered:
        if not c.exists():
            print("MISSING", c)
            return 1
        print(f"  {c.name}: {probe_duration(c):.2f}s")

    silent = WORK / "picture_silent.mp4"
    concat_clips(ordered, silent)
    total = probe_duration(silent)
    print(f"Total picture: {total:.2f}s")

    audio_out = WORK / "mix.m4a"
    mix_audio(total, audio_out)

    final = EXPORT / "StillScout_ThePerfectStill_4K_9x16.mp4"
    mux(silent, audio_out, final)

    # Also export social-ready 1080x1920
    social = EXPORT / "StillScout_ThePerfectStill_1080x1920.mp4"
    run([
        FF, "-y", "-i", str(final),
        "-vf", "scale=1080:1920:flags=lanczos",
        "-c:v", "libx264", "-preset", "slow", "-crf", "17",
        "-pix_fmt", "yuv420p", "-movflags", "+faststart",
        "-c:a", "copy",
        str(social),
    ])

    meta = {
        "title": "StillScout — The Perfect Still",
        "duration_sec": probe_duration(final),
        "outputs": [str(final), str(social)],
        "resolution_master": f"{W}x{H}",
    }
    (EXPORT / "manifest.json").write_text(json.dumps(meta, indent=2))
    print(json.dumps(meta, indent=2))
    print("DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
