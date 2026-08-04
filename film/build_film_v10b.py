#!/usr/bin/env python3
"""StillScout v10b — Director cut, tightened for Instagram.

Based on v10: one world, one product punch, HIS frames as Top Picks.
Improvements: stronger natural face grade, shorter non-ghosty transitions,
tighter book-logo → real mark end, Foley-first + whisper piano, instastillscoutad exports.
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
WORK = ROOT / "work_v10b"
STILLS = WORK / "stills"
EXPORT = ROOT / "export"
AUDIO = ROOT / "audio" / "src_v5"
MARK = ROOT / "assets" / "stillscout_mark_light.png"
W, H, FPS = 2160, 3840, 30

# Handsome/even face — premium natural: even skin, healthy gold, soft bloom (no wash/plastic)
FACE = (
    "format=yuv420p,"
    # Strong chroma denoise evenings blotchy red without plastic luma blur
    "hqdn3d=1.5:2.8:2.2:3.8,"
    "bilateral=sigmaS=2.0:sigmaR=0.05,"
    "eq=contrast=1.14:brightness=-0.012:saturation=1.06:gamma=0.99,"
    # Mild red→skin blend for residual blotch; preserve texture
    "colorchannelmixer=rr=0.91:rg=0.09:rb=0:gr=0.02:gg=0.98:gb=0:br=0:bg=0.01:bb=0.99,"
    # Slightly tamer red mids than old FACE (less blotch amplify); keep warmth
    "curves=red='0/0.015 0.22/0.24 0.48/0.545 0.72/0.775 1/1':"
    "green='0/0.02 0.22/0.224 0.48/0.512 0.72/0.752 1/0.99':"
    "blue='0/0.03 0.22/0.205 0.48/0.47 0.72/0.718 1/0.966',"
    # Healthy warm gold after chroma even; no magenta/purple
    "colorbalance=rs=0.062:gs=0.018:bs=-0.032:rm=0.058:gm=0.016:bm=-0.036:"
    "rh=0.032:gh=0.010:bh=-0.018,"
    # Soft film highlight bloom — very low opacity (avoid wash)
    "split[fb][bb];[bb]gblur=sigma=7[bloom];"
    "[fb][bloom]blend=all_mode=screen:all_opacity=0.028,"
    "unsharp=5:5:0.78:5:5:0.28,"
    "vignette=PI/5.5,"
    "noise=alls=1.35:allf=t"
)
DETAIL = (
    "format=yuv420p,hqdn3d=1.4:1.0:2.0:1.4,"
    "eq=contrast=1.08:brightness=0.01:saturation=1.02,"
    "curves=all='0/0.02 0.5/0.545 1/0.995',"
    "colorbalance=rs=0.032:gs=0.012:bs=-0.018,"
    "unsharp=5:5:0.55:5:5:0.14,vignette=PI/5.5,noise=alls=1.6:allf=t"
)
WIDE = (
    "format=yuv420p,hqdn3d=1.2:0.9:1.8:1.2,"
    "eq=contrast=1.10:brightness=0.005:saturation=1.06,"
    "curves=all='0/0.015 0.5/0.53 1/0.99',"
    "unsharp=5:5:0.48:5:5:0.12,noise=alls=1.5:allf=t"
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
        "format=yuv420p,eq=contrast=1.11:brightness=-0.002:saturation=1.04,"
        "colorbalance=rs=0.028:gs=0.012:bs=-0.016:rm=0.024:gm=0.014:bm=-0.018,"
        "vignette=PI/5.2,"
        + finder() + ","
        # score badge TOP-RIGHT only
        "drawbox=x=w*0.68:y=h*0.08:w=380:h=130:color=black@0.55:t=fill,"
        "drawtext=fontfile=/System/Library/Fonts/Supplemental/Helvetica.ttc:"
        "text='AI  9.4':fontsize=78:fontcolor=0xF5D59A:"
        "x=w*0.68+48:y=h*0.08+30,"
        # product line BOTTOM safe zone
        "drawtext=fontfile=/System/Library/Fonts/Supplemental/Didot.ttc:"
        "text='StillScout finds it.':fontsize=70:fontcolor=white:"
        "x=(w-text_w)/2:y=h*0.86:borderw=4:bordercolor=black@0.55,"
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


def assemble(clips: list[Path], durs: list[float], dst: Path, xfade: float = 0.18) -> float:
    """Short dissolves; fadeblack into/out of product beats to kill ghost doubles."""
    inputs: list[str] = []
    for c in clips:
        inputs += ["-i", str(c)]

    def transition_for(i: int) -> str:
        # i = incoming clip index. found=4, picks=5, harbor=6 after picks
        if i in (4, 5, 6):
            return "fadeblack"
        return "fade"

    parts = [
        f"[0:v][1:v]xfade=transition={transition_for(1)}:duration={xfade}:offset={durs[0]-xfade:.3f}[v01]"
    ]
    prev, acc = "v01", durs[0] + durs[1] - xfade
    for i in range(2, len(clips)):
        offset = acc - xfade
        out = "vout" if i == len(clips) - 1 else f"v{i:02d}"
        tr = transition_for(i)
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
            f"if(lt(t,{st:.2f}),0,if(lt(t,{st+0.25:.2f}),(t-{st:.2f})/0.25,"
            f"if(lt(t,{en-0.25:.2f}),0.98,if(lt(t,{en:.2f}),({en:.2f}-t)/0.25*0.98,0))))"
        )
        parts.append(
            f"drawtext=fontfile={fonts[fn]}:text='{safe}':fontsize={size}:"
            f"fontcolor=white:x=(w-text_w)/2:y=h*{yf}:"
            f"borderw=4:bordercolor=black@0.65:alpha='{alpha}'"
        )
    run([
        FF, "-y", "-i", str(video), "-vf", ",".join(parts),
        "-c:v", "h264_videotoolbox", "-b:v", "48M", "-pix_fmt", "yuv420p", "-an",
        str(dst),
    ])
    return probe(dst)


def render_book_logo(dst: Path, *, start: float = 0.45, duration: float = 2.55, speed: float = 0.95) -> float:
    """Hand-drawn StillScout mark (MVI_0390) — hold the circular logo, avoid page drift."""
    out_dur = duration / speed
    comma = r"\,"
    # Right-page logo mark; gentle push stays on the circle (not the vertical scribble)
    vf = (
        f"deshake=rx=16:ry=16,setpts=PTS/{speed},"
        f"scale={int(W*1.28)}:{int(H*1.28)}:force_original_aspect_ratio=increase:flags=lanczos,"
        f"crop={W}:{H}:"
        f"x='(iw-ow)*0.74 + (t/{out_dur:.3f})*min(iw*0.008{comma}18)':"
        f"y='(ih-oh)*0.42 - (t/{out_dur:.3f})*min(ih*0.012{comma}28)',"
        f"{DETAIL},"
        f"fade=t=in:st=0:d=0.28"
    )
    run([
        FF, "-y", "-ss", f"{start:.2f}", "-t", f"{duration:.2f}",
        "-i", str(FOOTAGE / "MVI_0390.MP4"), "-vf", vf, "-an", "-r", str(FPS),
        "-c:v", "h264_videotoolbox", "-b:v", "48M", "-pix_fmt", "yuv420p",
        "-t", f"{out_dur:.3f}", str(dst),
    ])
    return probe(dst)


def end_logo_plate(dst: Path, *, dur: float = 5.0) -> float:
    """Clean animated StillScout mark + wordmark (real logo)."""
    logo = MARK if MARK.exists() else ROOT / "assets" / "stillscout_mark.png"
    comma = r"\,"
    fc = (
        f"color=c=0x0C0B0A:s={W}x{H}:d={dur}:r={FPS},format=yuv420p,"
        f"vignette=PI/3.6[bg];"
        f"[0:v]format=rgba,scale=720:720,"
        f"fade=t=in:st=0:d=0.55:alpha=1,"
        f"fade=t=out:st={dur-1.05:.2f}:d=0.95:alpha=1[lg];"
        f"[bg][lg]overlay=x='(W-w)/2':"
        f"y='H*0.28-h/2+24*(1-min(1{comma}max(0{comma}(t-0.25)/0.8)))':"
        f"format=auto[v1];"
        f"[v1]"
        # Note: fontcolor=@0.0 kills text even with alpha= — use opaque colors + alpha expr
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Didot.ttc:"
        f"text='StillScout':fontsize=136:fontcolor=0xFFFAF5:"
        f"x=(w-text_w)/2:y=h*0.60:"
        f"alpha='if(lt(t,0.7),0,if(lt(t,1.35),(t-0.7)/0.65,if(gt(t,{dur-1.0:.2f}),"
        f"({dur:.2f}-t)/1.0,0.98)))',"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Georgia.ttf:"
        f"text='Scout the perfect still.':fontsize=56:fontcolor=0xF2E8DA:"
        f"x=(w-text_w)/2:y=h*0.60+145:"
        f"alpha='if(lt(t,1.25),0,if(lt(t,1.9),(t-1.25)/0.65,if(gt(t,{dur-0.95:.2f}),"
        f"({dur:.2f}-t)/0.95,0.94)))',"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Helvetica.ttc:"
        f"text='Drop any video. AI finds your best photo.':fontsize=40:fontcolor=0xE8E0D4:"
        f"x=(w-text_w)/2:y=h*0.60+240:"
        f"alpha='if(lt(t,1.85),0,if(lt(t,2.45),(t-1.85)/0.6,if(gt(t,{dur-0.95:.2f}),"
        f"({dur:.2f}-t)/0.95,0.90)))',"
        f"drawbox=x=(iw-340)/2:y=ih*0.565:w=340:h=2:color=0xD4B88C@0.9:t=fill:"
        f"enable='between(t,0.7,{dur-1.0:.2f})',"
        f"fade=t=in:st=0:d=0.2,fade=t=out:st={dur-1.0:.2f}:d=1.0[vout]"
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
    """Book logo → clean dissolve into real StillScout logo animation."""
    book = WORK / "clips" / "09a_book_logo.mp4"
    plate = WORK / "clips" / "09b_logo_plate.mp4"
    d_book = render_book_logo(book, start=0.45, duration=2.55, speed=0.95)
    d_plate = end_logo_plate(plate, dur=5.0)
    xfade = 0.55
    offset = max(0.2, d_book - xfade)
    total = d_book + d_plate - xfade
    run([
        FF, "-y", "-i", str(book), "-i", str(plate),
        "-filter_complex",
        f"[0:v][1:v]xfade=transition=fadeblack:duration={xfade}:offset={offset:.3f}[vout]",
        "-map", "[vout]",
        "-c:v", "h264_videotoolbox", "-b:v", "48M", "-pix_fmt", "yuv420p",
        "-t", f"{total:.3f}", str(dst),
    ])
    return probe(dst)


def mix_audio(total: float, marks: dict[str, float], dst: Path) -> None:
    """Foley-first VO bed + whisper piano under lifestyle only (ducks at product/brand)."""
    def ms(s: float) -> int:
        return max(0, int(s * 1000))

    t_hands = marks.get("hands", 2.5)
    t_scrub = marks["scrub"]
    t_found = marks["found"]
    t_picks = marks["picks"]
    t_harbor = marks.get("harbor", t_picks + 3.5)
    t_end = marks["end"]
    scribble_len = max(1.8, t_scrub - t_hands + 0.5)
    # piano under lifestyle; duck hard into product punch, soft again for harbor/proof, mute at brand
    piano_env = (
        f"volume='if(lt(t,{t_found-0.35:.2f}),0.055,"
        f"if(lt(t,{t_harbor:.2f}),0.012,"
        f"if(lt(t,{t_end:.2f}),0.045,0.008)))'"
    )

    fc = (
        f"[0:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=70,volume=0.38,afade=t=in:st=0:d=1.0,afade=t=out:st={total-2}:d=2[ocean];"
        f"[1:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"volume=0.09,afade=t=in:st=0:d=1.2[wind];"
        f"[2:a]aloop=loop=-1:size=2e+09,atrim=0:{scribble_len:.2f},asetpts=N/SR/TB,"
        f"adelay={ms(t_hands)}|{ms(t_hands)},volume=0.80,highpass=f=800,"
        f"afade=t=in:st=0:d=0.12,afade=t=out:st={scribble_len-0.35:.2f}:d=0.35,"
        f"atrim=0:{total},asetpts=N/SR/TB[scribble];"
        f"[3:a]adelay={ms(t_hands+0.45)}|{ms(t_hands+0.45)},volume=0.74,atrim=0:{total},asetpts=N/SR/TB[pen];"
        f"[4:a]adelay={ms(0.12)}|{ms(0.12)},volume=0.68,atrim=0:{total},asetpts=N/SR/TB[book];"
        f"[5:a]adelay={ms(t_scrub+0.08)}|{ms(t_scrub+0.08)},volume=0.36,atrim=0:{total},asetpts=N/SR/TB[fab];"
        f"[6:a]adelay={ms(t_found)}|{ms(t_found)},volume=0.36,lowpass=f=3500,atrim=0:{total},asetpts=N/SR/TB[shutter];"
        f"[6:a]adelay={ms(t_picks)}|{ms(t_picks)},volume=0.24,lowpass=f=3000,atrim=0:{total},asetpts=N/SR/TB[ui];"
        f"[6:a]adelay={ms(t_end+0.3)}|{ms(t_end+0.3)},volume=0.22,lowpass=f=2600,atrim=0:{total},asetpts=N/SR/TB[endw];"
        f"[7:a]adelay={ms(t_end+0.12)}|{ms(t_end+0.12)},volume=0.58,atrim=0:{total},asetpts=N/SR/TB[page];"
        f"[6:a]adelay={ms(t_end+2.7)}|{ms(t_end+2.7)},volume=0.26,lowpass=f=2800,atrim=0:{total},asetpts=N/SR/TB[logo];"
        # whisper piano — lifestyle only
        f"[8:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"lowpass=f=4200,afade=t=in:st=0:d=1.6,afade=t=out:st={total-2.2:.2f}:d=2.2,"
        f"{piano_env}[piano];"
        f"[ocean][wind][scribble][pen][book][fab][shutter][ui][endw][page][logo][piano]"
        f"amix=inputs=12:normalize=0:dropout_transition=2,"
        f"volume='if(lt(t,{t_end:.2f}),1.0,0.32)',"
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
        page, AUDIO / "piano.mp3",
    ]:
        cmd += ["-i", str(p)]
    cmd += ["-filter_complex", fc, "-map", "[aout]", "-t", str(total),
            "-c:a", "aac", "-b:a", "320k", str(dst)]
    run(cmd)


def export_safe(src: Path, mp4: Path, mov: Path) -> None:
    """Player-safe 1080x1920 libx264 + companion .mov."""
    run([
        FF, "-y", "-i", str(src),
        "-vf", "scale=1080:1920:flags=lanczos,format=yuv420p,eq=brightness=0.008:contrast=1.04:saturation=1.03",
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

    # Reuse v10 stills if present; else extract
    v10_stills = ROOT / "work_v10" / "stills"
    for i, (src, ss) in enumerate([
        ("MVI_0358.MP4", 3.2), ("MVI_0353.MP4", 17.5), ("MVI_0343.MP4", 1.5),
        ("MVI_0356.MP4", 6.0), ("MVI_0363.MP4", 10.0), ("MVI_0359.MP4", 5.5),
    ], 1):
        out = STILLS / f"pick{i}.jpg"
        if out.exists():
            continue
        src_v10 = v10_stills / f"pick{i}.jpg"
        if src_v10.exists():
            run(["cp", str(src_v10), str(out)])
        else:
            run([FF, "-y", "-ss", str(ss), "-i", str(FOOTAGE / src),
                 "-frames:v", "1", "-update", "1", "-q:v", "2", str(out)])

    picks_png = WORK / "top_picks.png"
    build_top_picks_png(picks_png)

    plan: list[tuple[Path, float, str]] = []

    # 1 Hook face — tighter open
    d = render("MVI_0353.MP4", clips / "01_hook.mp4",
               start=16.9, duration=2.95, speed=0.90, grade="face", fade_in=0.40,
               crop_y="(ih-oh)/2+320", kind="push_hard")
    plan.append((clips / "01_hook.mp4", d, "hook"))

    # 2 Hands writing
    d = render("MVI_0356.MP4", clips / "02_hands.mp4",
               start=5.0, duration=2.35, speed=0.84, grade="detail",
               crop_y="(ih-oh)/2", kind="push")
    plan.append((clips / "02_hands.mp4", d, "hands"))

    # 3 Scrub / hunt with viewfinder
    d = render("MVI_0363.MP4", clips / "03_scrub.mp4",
               start=9.1, duration=2.85, speed=0.98, grade="wide",
               crop_y="(ih-oh)/2+70", kind="rise", with_finder=True)
    plan.append((clips / "03_scrub.mp4", d, "scrub"))

    # 4 Profile beauty (bridge)
    d = render("MVI_0358.MP4", clips / "04_profile.mp4",
               start=2.7, duration=2.45, speed=0.90, grade="face",
               crop_y="(ih-oh)/2+40", kind="rise")
    plan.append((clips / "04_profile.mp4", d, "profile"))

    # 5 FOUND still — product punch
    face_src = clips / "05_face_src.mp4"
    render("MVI_0353.MP4", face_src,
           start=17.0, duration=1.8, speed=1.0, grade="face",
           crop_y="(ih-oh)/2+300", kind="push")
    found = clips / "05_found.mp4"
    d = render_found_still(face_src, found, at=0.80, hold=1.55)
    plan.append((found, d, "found"))

    # 6 ONE Top Picks — HIS frames (slightly shorter)
    picks = clips / "06_picks.mp4"
    d = render_top_picks_video(picks_png, picks, dur=3.45)
    plan.append((picks, d, "picks"))

    # 7 Harbor proof
    d = render("MVI_0343.MP4", clips / "07_harbor.mp4",
               start=1.0, duration=3.05, speed=0.94, grade="wide",
               crop_y="(ih-oh)/2+50", kind="pull")
    plan.append((clips / "07_harbor.mp4", d, "harbor"))

    # 8 Beauty proof
    d = render("MVI_0358.MP4", clips / "08_proof.mp4",
               start=3.05, duration=2.85, speed=0.88, grade="face",
               crop_y="(ih-oh)/2+35", kind="push_hard")
    plan.append((clips / "08_proof.mp4", d, "proof"))

    # 9 Book logo → real StillScout logo
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
    xfade = 0.18
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

    # Primary recognizable deliverable
    play = EXPORT / "instastillscoutad.mp4"
    mov = EXPORT / "instastillscoutad.mov"
    export_safe(master, play, mov)

    # Keep familiar aliases pointing at the same cut
    aliases = [
        EXPORT / "StillScout_PLAY_ME_1080x1920.mp4",
        EXPORT / "StillScout_PLAY_ME_1080x1920.mov",
        EXPORT / "StillScout_Best_1080x1920.mp4",
        EXPORT / "StillScout_VO_BED_1080x1920.mp4",
    ]
    run(["cp", str(play), str(aliases[0])])
    run(["cp", str(mov), str(aliases[1])])
    run(["cp", str(play), str(aliases[2])])
    run(["cp", str(play), str(aliases[3])])

    dur = probe(play)
    meta = {
        "title": "StillScout — Director Cut v10b (instastillscoutad)",
        "duration_sec": dur,
        "version": "v10b",
        "edit_rules": [
            "one world — no App Store carousel",
            "even handsome face grade (chroma even + soft bloom, no wash)",
            "short xfades + fadeblack around product beats",
            "product punch with HIS frames as Top Picks",
            "text never on eyes",
            "end: book logo (MVI_0390 circle mark) → real mark animation",
            "Foley-first + whisper piano under lifestyle",
            "player-safe libx264 + mov",
        ],
        "book_logo_src": "MVI_0390.MP4",
        "marks": {k: round(v, 2) for k, v in marks.items()},
        "play_mp4": str(play),
        "play_mov": str(mov),
        "aliases": [str(a) for a in aliases],
        "vo_sec": [round(marks["end"] + 1.0, 1), round(total - 0.7, 1)],
    }
    (EXPORT / "manifest_v10b.json").write_text(json.dumps(meta, indent=2))
    (EXPORT / "manifest_v10.json").write_text(json.dumps(meta, indent=2))
    (EXPORT / "manifest.json").write_text(json.dumps(meta, indent=2))
    (EXPORT / "NARRATION_SCRIPT.md").write_text(
        "# StillScout VO — Director Cut v10b (instastillscoutad)\n\n"
        f"**Length:** ~{dur:.1f}s\n"
        "**File:** `film/export/instastillscoutad.mov`\n\n"
        "Product-forward director cut. Record over the Foley bed.\n\n"
        "```\n"
        "You filmed it.\n"
        "Finding the still is hard.\n"
        "StillScout finds it.\n"
        "Same clip. Better still.\n\n"
        "StillScout.\n"
        "Scout the perfect still.\n"
        "```\n"
        f"\nBrand line ~{marks['end']+1.2:.0f}s – {total-0.5:.0f}s.\n"
    )
    (EXPORT / "DIRECTOR_REVIEW.md").write_text(
        "# StillScout Reel — Director’s Review\n"
        f"**Cut:** `instastillscoutad.mov` · **{dur:.1f}s** · v10b\n\n"
        "## What changed from v10 / vs abandoned v11\n\n"
        "- Abandoned ~41s emotion-only brand film (v11).\n"
        "- Restored product-forward ~32s director structure.\n"
        "- Even handsome face grade (chroma even + soft bloom, no wash).\n"
        "- Shorter dissolves; fadeblack around product beats (less ghosting).\n"
        "- Book logo held on circular mark → real StillScout logo.\n"
        "- Foley-first bed + whisper piano under lifestyle only.\n"
        "- Primary export renamed `instastillscoutad.mov` / `.mp4`.\n"
    )
    print(json.dumps(meta, indent=2))
    print("DONE →", mov)
    return 0


if __name__ == "__main__":
    sys.exit(main())
