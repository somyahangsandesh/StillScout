#!/usr/bin/env python3
"""StillScout v10 — Director's final edit.

One world. One product punch. HIS frames as Top Picks.
No App Store screenshot carousel. Text never on the eyes.
Player-safe export.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

ROOT = Path("/Users/sandeshsomyahang/stillscout/film")
FOOTAGE = Path("/Users/sandeshsomyahang/Downloads/New Folder With Items")
FF = str(ROOT / "bin" / "ffmpeg")
FP = str(ROOT / "bin" / "ffprobe")
WORK = ROOT / "work_v10"
STILLS = WORK / "stills"
EXPORT = ROOT / "export"
AUDIO = ROOT / "audio" / "src_v5"
MARK = ROOT / "assets" / "stillscout_mark_light.png"
W, H, FPS = 2160, 3840, 30

FACE = (
    "format=yuv420p,hqdn3d=2.0:1.3:2.8:2,bilateral=sigmaS=2.2:sigmaR=0.07,"
    "eq=contrast=1.00:brightness=0.03:saturation=0.92:gamma=1.03,"
    "curves=red='0/0.04 0.3/0.34 0.55/0.61 1/0.995':"
    "green='0/0.04 0.3/0.32 0.55/0.57 1/0.98':"
    "blue='0/0.05 0.3/0.30 0.55/0.53 1/0.955',"
    "colorbalance=rs=0.04:gs=0.012:bs=-0.022:rm=0.05:gm=0.015:bm=-0.028,"
    "split[base][glow];[glow]gblur=sigma=6[g];"
    "[base][g]blend=all_mode=screen:all_opacity=0.07,"
    "unsharp=5:5:0.55:5:5:0.18,vignette=PI/5.2,noise=alls=2:allf=t"
)
DETAIL = (
    "format=yuv420p,hqdn3d=1.6:1.1:2.2:1.6,"
    "eq=contrast=1.03:brightness=0.03:saturation=0.96,"
    "curves=all='0/0.03 0.5/0.54 1/0.99',"
    "colorbalance=rs=0.028:gs=0.01:bs=-0.016,"
    "unsharp=5:5:0.48:5:5:0.12,vignette=PI/5.5,noise=alls=2:allf=t"
)
WIDE = (
    "format=yuv420p,hqdn3d=1.4:1:2:1.4,"
    "eq=contrast=1.05:brightness=0.02:saturation=1.0,"
    "curves=all='0/0.02 0.5/0.52 1/0.985',"
    "unsharp=5:5:0.42:5:5:0.1,noise=alls=2:allf=t"
)


def run(cmd: list[str]) -> None:
    print("+", " ".join(str(c) for c in cmd[:9]), "...")
    subprocess.run(cmd, check=True)


def probe(path: Path) -> float:
    return float(subprocess.check_output(
        [FP, "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        text=True,
    ).strip())


def motion(kind: str, dur: float, crop_y: str) -> str:
    comma = r"\,"
    if kind == "push":
        y = crop_y.replace("(ih-oh)/2", f"(ih-oh)/2-(t/{dur:.3f})*min(ih*0.04{comma}90)")
        return (
            f"scale={int(W*1.14)}:{int(H*1.14)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2':y='{y}'"
        )
    if kind == "push_hard":
        y = crop_y.replace("(ih-oh)/2", f"(ih-oh)/2-(t/{dur:.3f})*min(ih*0.055{comma}120)")
        return (
            f"scale={int(W*1.18)}:{int(H*1.18)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2+(t/{dur:.3f})*min(iw*0.015{comma}30)':y='{y}'"
        )
    if kind == "pull":
        y = crop_y.replace("(ih-oh)/2", f"(ih-oh)/2+(t/{dur:.3f})*min(ih*0.028{comma}65)")
        return (
            f"scale={int(W*1.15)}:{int(H*1.15)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2':y='{y}'"
        )
    if kind == "rise":
        y = crop_y.replace("(ih-oh)/2", f"(ih-oh)/2-(t/{dur:.3f})*min(ih*0.032{comma}75)")
        return (
            f"scale={int(W*1.12)}:{int(H*1.12)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2':y='{y}'"
        )
    return (
        f"scale={W}:{H}:force_original_aspect_ratio=increase:flags=lanczos,"
        f"crop={W}:{H}:(iw-ow)/2:{crop_y}"
    )


def finder() -> str:
    m, L, t = 150, 110, 7
    g = "0xD4B88C"
    return (
        f"drawbox=x={m}:y={m}:w={L}:h={t}:color={g}@0.9:t=fill,"
        f"drawbox=x={m}:y={m}:w={t}:h={L}:color={g}@0.9:t=fill,"
        f"drawbox=x=iw-{m}-{L}:y={m}:w={L}:h={t}:color={g}@0.9:t=fill,"
        f"drawbox=x=iw-{m}-{t}:y={m}:w={t}:h={L}:color={g}@0.9:t=fill,"
        f"drawbox=x={m}:y=ih-{m}-{t}:w={L}:h={t}:color={g}@0.9:t=fill,"
        f"drawbox=x={m}:y=ih-{m}-{L}:w={t}:h={L}:color={g}@0.9:t=fill,"
        f"drawbox=x=iw-{m}-{L}:y=ih-{m}-{t}:w={L}:h={t}:color={g}@0.9:t=fill,"
        f"drawbox=x=iw-{m}-{t}:y=ih-{m}-{L}:w={t}:h={L}:color={g}@0.9:t=fill"
    )


def render(
    src: str, dst: Path, *, start: float, duration: float, speed: float = 1.0,
    grade: str = "detail", fade_in: float = 0.0, crop_y: str = "(ih-oh)/2",
    kind: str = "push", with_finder: bool = False,
) -> float:
    out_dur = duration / speed
    g = {"face": FACE, "detail": DETAIL, "wide": WIDE}[grade]
    vf = f"deshake=rx=16:ry=16,setpts=PTS/{speed},{motion(kind, out_dur, crop_y)},{g}"
    if with_finder:
        vf += "," + finder()
    if fade_in:
        vf += f",fade=t=in:st=0:d={fade_in}"
    run([
        FF, "-y", "-ss", f"{start:.2f}", "-t", f"{duration:.2f}",
        "-i", str(FOOTAGE / src), "-vf", vf, "-an", "-r", str(FPS),
        "-c:v", "h264_videotoolbox", "-b:v", "48M", "-pix_fmt", "yuv420p",
        "-t", f"{out_dur:.3f}", str(dst),
    ])
    return probe(dst)


def render_found_still(src_clip: Path, dst: Path, *, at: float, hold: float = 1.6) -> float:
    """Hero freeze + score — text stays TOP, never on eyes."""
    frame = WORK / "found.png"
    run([FF, "-y", "-ss", f"{at:.2f}", "-i", str(src_clip), "-frames:v", "1", "-update", "1", str(frame)])
    vf = (
        f"scale={W}:{H},"
        f"zoompan=z='min(1.07,1+0.035*on/{max(1,int(hold*FPS))})':"
        f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s={W}x{H}:fps={FPS},"
        "format=yuv420p,eq=contrast=1.06:brightness=0.03:saturation=0.96,"
        "vignette=PI/4.8,"
        + finder() + ","
        # score badge TOP-RIGHT only
        "drawbox=x=w*0.68:y=h*0.08:w=380:h=130:color=black@0.50:t=fill,"
        "drawtext=fontfile=/System/Library/Fonts/Supplemental/Helvetica.ttc:"
        "text='AI  9.4':fontsize=78:fontcolor=0xF5D59A:"
        "x=w*0.68+48:y=h*0.08+30,"
        # product line BOTTOM safe zone
        "drawtext=fontfile=/System/Library/Fonts/Supplemental/Didot.ttc:"
        "text='StillScout finds it.':fontsize=68:fontcolor=white:"
        "x=(w-text_w)/2:y=h*0.86:borderw=3:bordercolor=black@0.45,"
        "fade=t=in:st=0:d=0.08:color=white"
    )
    run([
        FF, "-y", "-loop", "1", "-i", str(frame),
        "-vf", vf, "-t", f"{hold:.3f}",
        "-c:v", "h264_videotoolbox", "-b:v", "48M", "-pix_fmt", "yuv420p",
        str(dst),
    ])
    return probe(dst)


def _font(size: int, serif: bool = False):
    paths = (
        ["/System/Library/Fonts/Supplemental/Didot.ttc"] if serif
        else [
            "/System/Library/Fonts/Supplemental/Helvetica.ttc",
            "/System/Library/Fonts/Helvetica.ttc",
            "/Library/Fonts/Arial.ttf",
        ]
    )
    for p in paths:
        try:
            return ImageFont.truetype(p, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def build_top_picks_png(dst: Path) -> None:
    """Top Picks UI using HIS real stills — the product proof."""
    canvas = Image.new("RGB", (W, H), (12, 12, 14))
    draw = ImageDraw.Draw(canvas)

    # soft vignette bg
    vign = Image.new("L", (W, H), 0)
    vd = ImageDraw.Draw(vign)
    vd.ellipse([-W * 0.2, -H * 0.1, W * 1.2, H * 0.9], fill=40)
    vign = vign.filter(ImageFilter.GaussianBlur(120))
    dark = Image.new("RGB", (W, H), (20, 18, 16))
    canvas = Image.composite(dark, canvas, vign)
    draw = ImageDraw.Draw(canvas)

    title = _font(96, serif=True)
    sub = _font(44, serif=False)
    badge = _font(40, serif=False)
    score_f = _font(36, serif=False)
    brand = _font(36, serif=False)

    gold = (212, 184, 140)
    draw.text((W // 2, int(H * 0.07)), "STILLSCOUT", font=brand, fill=gold, anchor="mm")
    draw.text((W // 2, int(H * 0.12)), "Top Picks", font=title, fill=(250, 248, 242), anchor="mm")
    draw.text((W // 2, int(H * 0.155)), "6 frames · ranked by AI from your clip", font=sub, fill=(180, 175, 165), anchor="mm")

    picks = [
        (STILLS / "pick1.jpg", "#1", "9.4"),
        (STILLS / "pick2.jpg", "#2", "8.9"),
        (STILLS / "pick3.jpg", "#3", "8.6"),
        (STILLS / "pick4.jpg", "#4", "8.1"),
        (STILLS / "pick5.jpg", "#5", "7.8"),
        (STILLS / "pick6.jpg", "#6", "7.5"),
    ]

    # 2-col grid of vertical thumbs
    gap = 36
    cols = 2
    cell_w = (W - 160 - gap) // cols
    cell_h = int(cell_w * 1.45)
    top0 = int(H * 0.20)

    for i, (path, rank, score) in enumerate(picks):
        col = i % cols
        row = i // cols
        x0 = 80 + col * (cell_w + gap)
        y0 = top0 + row * (cell_h + gap)
        img = Image.open(path).convert("RGB")
        # source may be landscape rotated metadata — force cover into cell
        thumb = ImageOps.fit(img, (cell_w, cell_h), method=Image.Resampling.LANCZOS)
        # slight grade
        thumb = ImageOps.autocontrast(thumb, cutoff=1)
        canvas.paste(thumb, (x0, y0))

        # gold border for #1
        if i == 0:
            draw.rectangle([x0 - 4, y0 - 4, x0 + cell_w + 4, y0 + cell_h + 4], outline=gold, width=6)
        else:
            draw.rectangle([x0, y0, x0 + cell_w, y0 + cell_h], outline=(60, 58, 55), width=2)

        # rank badge
        bx, by, bw, bh = x0 + 18, y0 + 18, 90, 54
        draw.rounded_rectangle([bx, by, bx + bw, by + bh], radius=27, fill=gold)
        draw.text((bx + bw // 2, by + bh // 2), rank, font=badge, fill=(20, 16, 12), anchor="mm")

        # score chip
        sx, sy = x0 + cell_w - 120, y0 + cell_h - 70
        draw.rounded_rectangle([sx, sy, sx + 100, sy + 48], radius=12, fill=(0, 0, 0, 180) if False else (0, 0, 0))
        draw.rounded_rectangle([sx, sy, sx + 100, sy + 48], radius=12, fill=(10, 10, 12))
        draw.text((sx + 50, sy + 24), score, font=score_f, fill=gold, anchor="mm")

    # footer product line
    draw.text(
        (W // 2, int(H * 0.94)),
        "Drop any video. AI finds your best photo.",
        font=sub, fill=(200, 195, 185), anchor="mm",
    )
    canvas.save(dst, quality=95)
    print("Top Picks PNG:", dst)


def render_top_picks_video(png: Path, dst: Path, *, dur: float = 3.8) -> float:
    """Ken Burns into the #1 cell — product proof with motion."""
    # gentle zoom toward top-left (#1)
    zexpr = f"min(1.12,1+0.03*on/{max(1,int(dur*FPS))})"
    vf = (
        f"scale={W}:{H},"
        f"zoompan=z='{zexpr}':"
        f"x='iw/2-(iw/zoom/2)-min(120\\,40*on/{max(1,int(dur*FPS))})':"
        f"y='ih/2-(ih/zoom/2)-min(180\\,60*on/{max(1,int(dur*FPS))})':"
        f"d=1:s={W}x{H}:fps={FPS},"
        "format=yuv420p,"
        f"fade=t=in:st=0:d=0.25,fade=t=out:st={dur-0.3:.2f}:d=0.3"
    )
    run([
        FF, "-y", "-loop", "1", "-i", str(png),
        "-vf", vf, "-t", f"{dur:.3f}",
        "-c:v", "h264_videotoolbox", "-b:v", "40M", "-pix_fmt", "yuv420p",
        str(dst),
    ])
    return probe(dst)


def assemble(clips: list[Path], durs: list[float], dst: Path, xfade: float = 0.30) -> float:
    inputs: list[str] = []
    for c in clips:
        inputs += ["-i", str(c)]
    parts = [f"[0:v][1:v]xfade=transition=fade:duration={xfade}:offset={durs[0]-xfade:.3f}[v01]"]
    prev, acc = "v01", durs[0] + durs[1] - xfade
    for i in range(2, len(clips)):
        offset = acc - xfade
        out = "vout" if i == len(clips) - 1 else f"v{i:02d}"
        # hard punch into found-still / top picks
        tr = "fadewhite" if i in (4, 5) else "fade"
        # fadewhite may fail on some builds — fallback handled below
        parts.append(
            f"[{prev}][{i}:v]xfade=transition={tr}:duration={xfade}:offset={offset:.3f}[{out}]"
        )
        prev = out
        acc += durs[i] - xfade
    total = sum(durs) - xfade * (len(clips) - 1)
    try:
        run([
            FF, "-y", *inputs, "-filter_complex", ";".join(parts),
            "-map", "[vout]", "-c:v", "h264_videotoolbox", "-b:v", "48M",
            "-pix_fmt", "yuv420p", "-t", f"{total:.3f}", str(dst),
        ])
    except subprocess.CalledProcessError:
        # fallback all fades
        parts = [f"[0:v][1:v]xfade=transition=fade:duration={xfade}:offset={durs[0]-xfade:.3f}[v01]"]
        prev, acc = "v01", durs[0] + durs[1] - xfade
        for i in range(2, len(clips)):
            offset = acc - xfade
            out = "vout" if i == len(clips) - 1 else f"v{i:02d}"
            parts.append(
                f"[{prev}][{i}:v]xfade=transition=fade:duration={xfade}:offset={offset:.3f}[{out}]"
            )
            prev = out
            acc += durs[i] - xfade
        run([
            FF, "-y", *inputs, "-filter_complex", ";".join(parts),
            "-map", "[vout]", "-c:v", "h264_videotoolbox", "-b:v", "48M",
            "-pix_fmt", "yuv420p", "-t", f"{total:.3f}", str(dst),
        ])
    return probe(dst)


def burn_copy(video: Path, dst: Path, marks: dict[str, float]) -> float:
    """Kinetic copy in SAFE zones only — never over eyes."""
    # note: found still already has its own bottom line
    lines = [
        (marks["hook"] + 0.35, marks["hook"] + 2.4, "You filmed it.", 70, 0.82, "georgia"),
        (marks["scrub"] + 0.25, marks["scrub"] + 2.8, "Finding the still is hard.", 58, 0.82, "georgia"),
        (marks["proof"] + 0.3, marks["proof"] + 3.2, "Same clip. Better still.", 64, 0.82, "georgia"),
    ]
    fonts = {
        "georgia": "/System/Library/Fonts/Supplemental/Georgia.ttf",
        "didot": "/System/Library/Fonts/Supplemental/Didot.ttc",
    }
    parts = []
    for st, en, text, size, yf, fn in lines:
        safe = text.replace(":", "\\:")
        alpha = (
            f"if(lt(t,{st:.2f}),0,if(lt(t,{st+0.3:.2f}),(t-{st:.2f})/0.3,"
            f"if(lt(t,{en-0.3:.2f}),0.93,if(lt(t,{en:.2f}),({en:.2f}-t)/0.3*0.93,0))))"
        )
        parts.append(
            f"drawtext=fontfile={fonts[fn]}:text='{safe}':fontsize={size}:"
            f"fontcolor=white@0.0:x=(w-text_w)/2:y=h*{yf}:"
            f"borderw=3:bordercolor=black@0.5:alpha='{alpha}'"
        )
    run([
        FF, "-y", "-i", str(video), "-vf", ",".join(parts),
        "-c:v", "h264_videotoolbox", "-b:v", "48M", "-pix_fmt", "yuv420p", "-an",
        str(dst),
    ])
    return probe(dst)


def render_book_logo(dst: Path, *, start: float = 0.6, duration: float = 3.4, speed: float = 0.88) -> float:
    """Hand-drawn StillScout mark in the notebook (MVI_0390) — crop to logo page."""
    out_dur = duration / speed
    comma = r"\,"
    # Landscape 3840x2160 → vertical crop biased to the right page (ink logo)
    vf = (
        f"deshake=rx=16:ry=16,setpts=PTS/{speed},"
        f"scale={int(W*1.22)}:{int(H*1.22)}:force_original_aspect_ratio=increase:flags=lanczos,"
        f"crop={W}:{H}:"
        f"x='(iw-ow)*0.68 + (t/{out_dur:.3f})*min(iw*0.02{comma}40)':"
        f"y='(ih-oh)/2 - (t/{out_dur:.3f})*min(ih*0.03{comma}70)',"
        f"{DETAIL},"
        f"fade=t=in:st=0:d=0.35"
    )
    run([
        FF, "-y", "-ss", f"{start:.2f}", "-t", f"{duration:.2f}",
        "-i", str(FOOTAGE / "MVI_0390.MP4"), "-vf", vf, "-an", "-r", str(FPS),
        "-c:v", "h264_videotoolbox", "-b:v", "48M", "-pix_fmt", "yuv420p",
        "-t", f"{out_dur:.3f}", str(dst),
    ])
    return probe(dst)


def end_logo_plate(dst: Path, *, dur: float = 5.4) -> float:
    """Clean animated StillScout mark + wordmark (real logo)."""
    logo = MARK if MARK.exists() else ROOT / "assets" / "stillscout_mark.png"
    comma = r"\,"
    fc = (
        f"color=c=0x0C0B0A:s={W}x{H}:d={dur}:r={FPS},format=yuv420p,"
        f"vignette=PI/3.6[bg];"
        f"[0:v]format=rgba,scale=700:700,"
        f"fade=t=in:st=0:d=0.7:alpha=1,"
        f"fade=t=out:st={dur-1.2:.2f}:d=1.05:alpha=1[lg];"
        f"[bg][lg]overlay=x='(W-w)/2':"
        f"y='H*0.28-h/2+30*(1-min(1{comma}max(0{comma}(t-0.35)/0.95)))':"
        f"format=auto[v1];"
        f"[v1]"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Didot.ttc:"
        f"text='StillScout':fontsize=132:fontcolor=0xFFFAF5@0.0:"
        f"x=(w-text_w)/2:y=h*0.60:"
        f"alpha='if(lt(t,0.9),0,if(lt(t,1.7),(t-0.9)/0.8,if(gt(t,{dur-1.15:.2f}),"
        f"({dur:.2f}-t)/1.15,0.98)))',"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Georgia.ttf:"
        f"text='Scout the perfect still.':fontsize=54:fontcolor=0xF2E8DA@0.0:"
        f"x=(w-text_w)/2:y=h*0.60+145:"
        f"alpha='if(lt(t,1.55),0,if(lt(t,2.3),(t-1.55)/0.75,if(gt(t,{dur-1.1:.2f}),"
        f"({dur:.2f}-t)/1.1,0.93)))',"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Helvetica.ttc:"
        f"text='Drop any video. AI finds your best photo.':fontsize=40:fontcolor=0xE8E0D4@0.0:"
        f"x=(w-text_w)/2:y=h*0.60+240:"
        f"alpha='if(lt(t,2.15),0,if(lt(t,2.85),(t-2.15)/0.7,if(gt(t,{dur-1.1:.2f}),"
        f"({dur:.2f}-t)/1.1,0.88)))',"
        f"drawbox=x=(iw-340)/2:y=ih*0.565:w=340:h=2:color=0xD4B88C@0.9:t=fill:"
        f"enable='between(t,0.85,{dur-1.15:.2f})',"
        f"fade=t=in:st=0:d=0.25,fade=t=out:st={dur-1.15:.2f}:d=1.15[vout]"
    )
    run([
        FF, "-y", "-loop", "1", "-i", str(logo),
        "-filter_complex", fc, "-map", "[vout]",
        "-t", f"{dur:.3f}",
        "-c:v", "h264_videotoolbox", "-b:v", "40M", "-pix_fmt", "yuv420p",
        str(dst),
    ])
    return probe(dst)


def end_brand_book_to_logo(dst: Path) -> float:
    """Book logo video → dissolve into real StillScout logo animation."""
    book = WORK / "clips" / "09a_book_logo.mp4"
    plate = WORK / "clips" / "09b_logo_plate.mp4"
    d_book = render_book_logo(book, start=0.55, duration=3.35, speed=0.88)
    d_plate = end_logo_plate(plate, dur=5.2)
    xfade = 0.85
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

    t_hands = marks.get("hands", 2.5)
    t_scrub = marks["scrub"]
    t_found = marks["found"]
    t_picks = marks["picks"]
    t_end = marks["end"]
    scribble_len = max(1.8, t_scrub - t_hands + 0.5)

    fc = (
        f"[0:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=70,volume=0.36,afade=t=in:st=0:d=1.2,afade=t=out:st={total-2}:d=2[ocean];"
        f"[1:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"volume=0.08,afade=t=in:st=0:d=1.4[wind];"
        f"[2:a]aloop=loop=-1:size=2e+09,atrim=0:{scribble_len:.2f},asetpts=N/SR/TB,"
        f"adelay={ms(t_hands)}|{ms(t_hands)},volume=0.78,highpass=f=800,"
        f"afade=t=in:st=0:d=0.15,afade=t=out:st={scribble_len-0.4:.2f}:d=0.4,"
        f"atrim=0:{total},asetpts=N/SR/TB[scribble];"
        f"[3:a]adelay={ms(t_hands+0.5)}|{ms(t_hands+0.5)},volume=0.72,atrim=0:{total},asetpts=N/SR/TB[pen];"
        f"[4:a]adelay={ms(0.15)}|{ms(0.15)},volume=0.65,atrim=0:{total},asetpts=N/SR/TB[book];"
        f"[5:a]adelay={ms(t_scrub+0.1)}|{ms(t_scrub+0.1)},volume=0.35,atrim=0:{total},asetpts=N/SR/TB[fab];"
        f"[6:a]adelay={ms(t_found)}|{ms(t_found)},volume=0.34,lowpass=f=3500,atrim=0:{total},asetpts=N/SR/TB[shutter];"
        f"[6:a]adelay={ms(t_picks)}|{ms(t_picks)},volume=0.22,lowpass=f=3000,atrim=0:{total},asetpts=N/SR/TB[ui];"
        f"[6:a]adelay={ms(t_end+0.35)}|{ms(t_end+0.35)},volume=0.2,lowpass=f=2600,atrim=0:{total},asetpts=N/SR/TB[endw];"
        # page turn on book logo + soft whoosh when real mark lands (~0.9s into brand)
        f"[7:a]adelay={ms(t_end+0.15)}|{ms(t_end+0.15)},volume=0.55,atrim=0:{total},asetpts=N/SR/TB[page];"
        f"[6:a]adelay={ms(t_end+3.5)}|{ms(t_end+3.5)},volume=0.24,lowpass=f=2800,atrim=0:{total},asetpts=N/SR/TB[logo];"
        f"[ocean][wind][scribble][pen][book][fab][shutter][ui][endw][page][logo]"
        f"amix=inputs=11:normalize=0:dropout_transition=2,"
        f"volume='if(lt(t,{t_end:.2f}),1.0,0.34)',"
        f"loudnorm=I=-18:TP=-2:LRA=9[aout]"
    )
    page = AUDIO / "page_turn_soft.mp3"
    if not page.exists():
        page = AUDIO / "book_open.mp3"
    cmd = [FF, "-y"]
    for p in [
        AUDIO / "ocean.mp3", AUDIO / "wind.mp3", AUDIO / "writing_1.mp3",
        AUDIO / "pen_on_paper.mp3", AUDIO / "book_open.mp3",
        AUDIO / "clothes_rustle.mp3", AUDIO / "soft_whoosh.mp3",
        page,
    ]:
        cmd += ["-i", str(p)]
    cmd += ["-filter_complex", fc, "-map", "[aout]", "-t", str(total),
            "-c:a", "aac", "-b:a", "320k", str(dst)]
    run(cmd)


def export_safe(src: Path, mp4: Path, mov: Path) -> None:
    run([
        FF, "-y", "-i", str(src),
        "-vf", "scale=1080:1920:flags=lanczos,format=yuv420p,eq=brightness=0.015:contrast=1.02",
        "-c:v", "libx264", "-preset", "fast", "-crf", "17",
        "-profile:v", "main", "-level", "4.0", "-pix_fmt", "yuv420p", "-tag:v", "avc1",
        "-colorspace", "bt709", "-color_primaries", "bt709",
        "-color_trc", "bt709", "-color_range", "tv",
        "-movflags", "+faststart",
        "-c:a", "aac", "-b:a", "256k", "-ar", "44100", "-ac", "2",
        str(mp4),
    ])
    run([FF, "-y", "-i", str(mp4), "-c", "copy", str(mov)])


def main() -> int:
    clips = WORK / "clips"
    clips.mkdir(parents=True, exist_ok=True)
    STILLS.mkdir(parents=True, exist_ok=True)
    EXPORT.mkdir(parents=True, exist_ok=True)

    # Ensure stills exist
    for i, (src, ss) in enumerate([
        ("MVI_0358.MP4", 3.2), ("MVI_0353.MP4", 17.5), ("MVI_0343.MP4", 1.5),
        ("MVI_0356.MP4", 6.0), ("MVI_0363.MP4", 10.0), ("MVI_0359.MP4", 5.5),
    ], 1):
        out = STILLS / f"pick{i}.jpg"
        if not out.exists():
            run([FF, "-y", "-ss", str(ss), "-i", str(FOOTAGE / src),
                 "-frames:v", "1", "-update", "1", "-q:v", "2", str(out)])

    picks_png = WORK / "top_picks.png"
    build_top_picks_png(picks_png)

    plan: list[tuple[Path, float, str]] = []

    # 1 Hook face — 0–5s feel
    d = render("MVI_0353.MP4", clips / "01_hook.mp4",
               start=16.8, duration=3.2, speed=0.88, grade="face", fade_in=0.55,
               crop_y="(ih-oh)/2+320", kind="push_hard")
    plan.append((clips / "01_hook.mp4", d, "hook"))

    # 2 Hands writing
    d = render("MVI_0356.MP4", clips / "02_hands.mp4",
               start=5.0, duration=2.6, speed=0.82, grade="detail",
               crop_y="(ih-oh)/2", kind="push")
    plan.append((clips / "02_hands.mp4", d, "hands"))

    # 3 Scrub / hunt with viewfinder
    d = render("MVI_0363.MP4", clips / "03_scrub.mp4",
               start=9.0, duration=3.2, speed=0.95, grade="wide",
               crop_y="(ih-oh)/2+70", kind="rise", with_finder=True)
    plan.append((clips / "03_scrub.mp4", d, "scrub"))

    # 4 Profile beauty (bridge)
    d = render("MVI_0358.MP4", clips / "04_profile.mp4",
               start=2.6, duration=2.8, speed=0.88, grade="face",
               crop_y="(ih-oh)/2+40", kind="rise")
    plan.append((clips / "04_profile.mp4", d, "profile"))

    # 5 FOUND still — product punch
    face_src = clips / "05_face_src.mp4"
    render("MVI_0353.MP4", face_src,
           start=17.0, duration=2.0, speed=1.0, grade="face",
           crop_y="(ih-oh)/2+300", kind="push")
    found = clips / "05_found.mp4"
    d = render_found_still(face_src, found, at=0.85, hold=1.7)
    plan.append((found, d, "found"))

    # 6 ONE Top Picks — HIS frames
    picks = clips / "06_picks.mp4"
    d = render_top_picks_video(picks_png, picks, dur=3.9)
    plan.append((picks, d, "picks"))

    # 7 Harbor proof
    d = render("MVI_0343.MP4", clips / "07_harbor.mp4",
               start=1.0, duration=3.4, speed=0.92, grade="wide",
               crop_y="(ih-oh)/2+50", kind="pull")
    plan.append((clips / "07_harbor.mp4", d, "harbor"))

    # 8 Beauty proof
    d = render("MVI_0358.MP4", clips / "08_proof.mp4",
               start=3.0, duration=3.2, speed=0.86, grade="face",
               crop_y="(ih-oh)/2+35", kind="push_hard")
    plan.append((clips / "08_proof.mp4", d, "proof"))

    # 9 Book logo (MVI_0390 hand-drawn mark) → real StillScout logo animation
    end = clips / "09_brand.mp4"
    d = end_brand_book_to_logo(end)
    plan.append((end, d, "end"))

    marks_raw = {}
    cum = 0.0
    for path, dur, name in plan:
        marks_raw[name] = cum
        print(f"  {path.name}: {dur:.2f}s @{cum:.2f}")
        cum += dur

    paths = [p for p, _, _ in plan]
    durs = [d for _, d, _ in plan]
    xfade = 0.30
    raw = WORK / "picture_raw.mp4"
    total = assemble(paths, durs, raw, xfade=xfade)
    marks = {n: max(0.0, marks_raw[n] - xfade * i) for i, (_, _, n) in enumerate(plan)}
    print("Picture:", total)
    print("Marks:", {k: round(v, 2) for k, v in marks.items()})

    pictured = WORK / "picture.mp4"
    burn_copy(raw, pictured, marks)
    total = probe(pictured)

    audio = WORK / "mix.m4a"
    mix_audio(total, marks, audio)

    master = WORK / "master.mp4"
    run([
        FF, "-y", "-i", str(pictured), "-i", str(audio),
        "-map", "0:v", "-map", "1:a",
        "-c:v", "copy", "-c:a", "aac", "-b:a", "320k",
        "-shortest", "-movflags", "+faststart", str(master),
    ])

    play = EXPORT / "StillScout_PLAY_ME_1080x1920.mp4"
    mov = EXPORT / "StillScout_PLAY_ME_1080x1920.mov"
    best = EXPORT / "StillScout_Best_1080x1920.mp4"
    vo = EXPORT / "StillScout_VO_BED_1080x1920.mp4"
    export_safe(master, play, mov)
    run(["cp", str(play), str(best)])
    run(["cp", str(play), str(vo)])

    meta = {
        "title": "StillScout — Director Cut v10",
        "duration_sec": probe(play),
        "edit_rules": [
            "one world — no App Store carousel",
            "product punch with HIS frames as Top Picks",
            "text never on eyes",
            "understand by ~found beat",
            "end: book logo (MVI_0390) → real mark animation",
            "player-safe x264 + mov",
        ],
        "book_logo_src": "MVI_0390.MP4",
        "marks": {k: round(v, 2) for k, v in marks.items()},
        "play_mp4": str(play),
        "play_mov": str(mov),
        "vo_sec": [round(marks["end"] + 1.2, 1), round(total - 0.8, 1)],
    }
    (EXPORT / "manifest_v10.json").write_text(json.dumps(meta, indent=2))
    (EXPORT / "NARRATION_SCRIPT.md").write_text(
        "# StillScout VO — Director Cut v10\n\n"
        f"**Length:** ~{probe(play):.0f}s\n"
        "**File:** `StillScout_PLAY_ME_1080x1920.mov`\n\n"
        "```\n"
        "You filmed it.\n"
        "Finding the still is hard.\n"
        "StillScout finds it.\n"
        "Same clip. Better still.\n\n"
        "StillScout.\n"
        "Scout the perfect still.\n"
        "```\n"
        f"\nBrand line ~{marks['end']+1.4:.0f}s.\n"
    )
    print(json.dumps(meta, indent=2))
    print("DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
