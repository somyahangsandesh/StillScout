#!/usr/bin/env python3
"""StillScout v9 — Director's Product Reel

Makes a stranger understand StillScout in under 10s of reading:
lifestyle emotion → problem → AI scouting UI → ranked stills → brand.

Animations: Ken Burns zooms, pulsing viewfinder, score pop, UI fly-ins,
kinetic on-screen copy. No music (VO-ready). Player-safe x264.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path("/Users/sandeshsomyahang/stillscout/film")
FOOTAGE = Path("/Users/sandeshsomyahang/Downloads/New Folder With Items")
SHOTS = Path("/Users/sandeshsomyahang/stillscout/docs/asc_assets/screenshots_67")
FF = str(ROOT / "bin" / "ffmpeg")
FP = str(ROOT / "bin" / "ffprobe")
WORK = ROOT / "work_v9"
EXPORT = ROOT / "export"
AUDIO = ROOT / "audio" / "src_v5"
MARK = ROOT / "assets" / "stillscout_mark_light.png"
W, H, FPS = 2160, 3840, 30

FACE = (
    "format=yuv420p,hqdn3d=2.2:1.4:3:2,bilateral=sigmaS=2.4:sigmaR=0.08,"
    "eq=contrast=0.98:brightness=0.03:saturation=0.90:gamma=1.03,"
    "curves=red='0/0.04 0.28/0.33 0.55/0.61 1/0.995':"
    "green='0/0.04 0.28/0.32 0.55/0.57 1/0.98':"
    "blue='0/0.05 0.28/0.30 0.55/0.53 1/0.955',"
    "colorbalance=rs=0.045:gs=0.012:bs=-0.025:rm=0.055:gm=0.015:bm=-0.03,"
    "split[base][glow];[glow]gblur=sigma=7[g];"
    "[base][g]blend=all_mode=screen:all_opacity=0.08,"
    "unsharp=5:5:0.6:5:5:0.2,vignette=PI/5,noise=alls=2:allf=t"
)
DETAIL = (
    "format=yuv420p,hqdn3d=1.8:1.2:2.5:1.8,"
    "eq=contrast=1.02:brightness=0.03:saturation=0.95:gamma=1.02,"
    "curves=all='0/0.03 0.5/0.54 1/0.99',"
    "colorbalance=rs=0.03:gs=0.01:bs=-0.018:rm=0.04:gm=0.012:bm=-0.02,"
    "unsharp=5:5:0.5:5:5:0.15,vignette=PI/5.5,noise=alls=2:allf=t"
)
WIDE = (
    "format=yuv420p,hqdn3d=1.5:1:2:1.5,"
    "eq=contrast=1.04:brightness=0.02:saturation=0.98:gamma=1.01,"
    "curves=all='0/0.02 0.5/0.52 1/0.985',"
    "colorbalance=rs=0.02:gs=0.008:bs=-0.015:rm=0.03:gm=0.01:bm=-0.018,"
    "unsharp=5:5:0.45:5:5:0.12,noise=alls=2:allf=t"
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
        y = crop_y.replace("(ih-oh)/2", f"(ih-oh)/2-(t/{dur:.3f})*min(ih*0.04{comma}95)")
        return (
            f"scale={int(W*1.14)}:{int(H*1.14)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2':y='{y}'"
        )
    if kind == "push_hard":
        y = crop_y.replace("(ih-oh)/2", f"(ih-oh)/2-(t/{dur:.3f})*min(ih*0.06{comma}140)")
        return (
            f"scale={int(W*1.20)}:{int(H*1.20)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2+(t/{dur:.3f})*min(iw*0.02{comma}40)':y='{y}'"
        )
    if kind == "pull":
        y = crop_y.replace("(ih-oh)/2", f"(ih-oh)/2+(t/{dur:.3f})*min(ih*0.03{comma}70)")
        return (
            f"scale={int(W*1.16)}:{int(H*1.16)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2':y='{y}'"
        )
    if kind == "rise":
        y = crop_y.replace("(ih-oh)/2", f"(ih-oh)/2-(t/{dur:.3f})*min(ih*0.035{comma}85)")
        return (
            f"scale={int(W*1.12)}:{int(H*1.12)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2':y='{y}'"
        )
    return (
        f"scale={W}:{H}:force_original_aspect_ratio=increase:flags=lanczos,"
        f"crop={W}:{H}:(iw-ow)/2:{crop_y}"
    )


def viewfinder_overlay(out_dur: float) -> str:
    """Animated camera brackets + soft pulse — product DNA on lifestyle shots."""
    # Corner L brackets via drawbox; pulse opacity with enable windows
    m, L, t = 140, 120, 8  # margin, arm length, thickness (in 2160x3840)
    gold = "0xD4B88C"
    return (
        # TL
        f"drawbox=x={m}:y={m}:w={L}:h={t}:color={gold}@0.85:t=fill,"
        f"drawbox=x={m}:y={m}:w={t}:h={L}:color={gold}@0.85:t=fill,"
        # TR
        f"drawbox=x=iw-{m}-{L}:y={m}:w={L}:h={t}:color={gold}@0.85:t=fill,"
        f"drawbox=x=iw-{m}-{t}:y={m}:w={t}:h={L}:color={gold}@0.85:t=fill,"
        # BL
        f"drawbox=x={m}:y=ih-{m}-{t}:w={L}:h={t}:color={gold}@0.85:t=fill,"
        f"drawbox=x={m}:y=ih-{m}-{L}:w={t}:h={L}:color={gold}@0.85:t=fill,"
        # BR
        f"drawbox=x=iw-{m}-{L}:y=ih-{m}-{t}:w={L}:h={t}:color={gold}@0.85:t=fill,"
        f"drawbox=x=iw-{m}-{t}:y=ih-{m}-{L}:w={t}:h={L}:color={gold}@0.85:t=fill,"
        # center reticle
        f"drawbox=x=(iw-2)/2:y=(ih-70)/2:w=2:h=70:color={gold}@0.45:t=fill,"
        f"drawbox=x=(iw-70)/2:y=(ih-2)/2:w=70:h=2:color={gold}@0.45:t=fill"
    )


def render(
    src: str, dst: Path, *, start: float, duration: float, speed: float = 1.0,
    grade: str = "detail", fade_in: float = 0.0, crop_y: str = "(ih-oh)/2",
    motion_kind: str = "push", finder: bool = False,
) -> float:
    out_dur = duration / speed
    g = {"face": FACE, "detail": DETAIL, "wide": WIDE}[grade]
    vf = f"deshake=rx=16:ry=16,setpts=PTS/{speed},{motion(motion_kind, out_dur, crop_y)},{g}"
    if finder:
        vf += "," + viewfinder_overlay(out_dur)
    if fade_in:
        vf += f",fade=t=in:st=0:d={fade_in}"
    run([
        FF, "-y", "-ss", f"{start:.2f}", "-t", f"{duration:.2f}",
        "-i", str(FOOTAGE / src), "-vf", vf, "-an", "-r", str(FPS),
        "-c:v", "h264_videotoolbox", "-b:v", "48M", "-pix_fmt", "yuv420p",
        "-t", f"{out_dur:.3f}", str(dst),
    ])
    return probe(dst)


def render_capture_still(src_clip: Path, dst: Path, *, at: float, hold: float = 1.1) -> float:
    """Freeze + white flash + score badge — 'AI found this'."""
    frame = WORK / "still.png"
    run([FF, "-y", "-ss", f"{at:.2f}", "-i", str(src_clip), "-frames:v", "1", "-update", "1", str(frame)])
    vf = (
        f"scale={W}:{H},"
        f"zoompan=z='min(1.08,1+0.04*on/{max(1,int(hold*FPS))})':"
        f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s={W}x{H}:fps={FPS},"
        "format=yuv420p,eq=contrast=1.06:brightness=0.025:saturation=0.95,"
        "vignette=PI/4.6,"
        + viewfinder_overlay(hold) + ","
        # score badge
        "drawbox=x=w*0.62:y=h*0.12:w=340:h=120:color=black@0.45:t=fill,"
        "drawtext=fontfile=/System/Library/Fonts/Supplemental/Helvetica.ttc:"
        "text='AI  9.4':fontsize=72:fontcolor=0xF5D59A:"
        "x=w*0.62+40:y=h*0.12+28,"
        "fade=t=in:st=0:d=0.1:color=white"
    )
    run([
        FF, "-y", "-loop", "1", "-i", str(frame),
        "-vf", vf, "-t", f"{hold:.3f}",
        "-c:v", "h264_videotoolbox", "-b:v", "48M", "-pix_fmt", "yuv420p",
        str(dst),
    ])
    return probe(dst)


def render_screenshot(png: Path, dst: Path, *, dur: float = 3.6, zoom: str = "in") -> float:
    """ASC screenshot as cinematic insert — gentle zoom, keep headlines readable."""
    if zoom == "in":
        zexpr = f"min(1.06,1+0.018*on/{max(1,int(dur*FPS))})"
    else:
        zexpr = f"max(1.0,1.06-0.018*on/{max(1,int(dur*FPS))})"
    vf = (
        # Fit full screenshot in frame (no aggressive crop of marketing copy)
        f"scale={W}:{H}:force_original_aspect_ratio=decrease:flags=lanczos,"
        f"pad={W}:{H}:(ow-iw)/2:(oh-ih)/2:color=0x0A0A0A,"
        f"zoompan=z='{zexpr}':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':"
        f"d=1:s={W}x{H}:fps={FPS},"
        "format=yuv420p,eq=contrast=1.03:brightness=0.015,"
        f"fade=t=in:st=0:d=0.3,fade=t=out:st={dur-0.3:.2f}:d=0.3"
    )
    run([
        FF, "-y", "-loop", "1", "-i", str(png),
        "-vf", vf, "-t", f"{dur:.3f}",
        "-c:v", "h264_videotoolbox", "-b:v", "40M", "-pix_fmt", "yuv420p",
        str(dst),
    ])
    return probe(dst)


def assemble(clips: list[Path], durs: list[float], dst: Path, xfade: float = 0.28) -> float:
    inputs: list[str] = []
    for c in clips:
        inputs += ["-i", str(c)]
    parts = [f"[0:v][1:v]xfade=transition=fade:duration={xfade}:offset={durs[0]-xfade:.3f}[v01]"]
    prev, acc = "v01", durs[0] + durs[1] - xfade
    for i in range(2, len(clips)):
        offset = acc - xfade
        out = "vout" if i == len(clips) - 1 else f"v{i:02d}"
        # sharper cut into UI (product clarity)
        tr = "fade"
        if i in (6, 7, 8):  # into UI shots
            tr = "fadeblack"
        parts.append(
            f"[{prev}][{i}:v]xfade=transition={tr}:duration={xfade}:offset={offset:.3f}[{out}]"
        )
        prev = out
        acc += durs[i] - xfade
    total = sum(durs) - xfade * (len(clips) - 1)
    run([
        FF, "-y", *inputs, "-filter_complex", ";".join(parts),
        "-map", "[vout]", "-c:v", "h264_videotoolbox", "-b:v", "48M",
        "-pix_fmt", "yuv420p", "-t", f"{total:.3f}", str(dst),
    ])
    return probe(dst)


def burn_story_copy(video: Path, dst: Path, marks: dict[str, float], total: float) -> float:
    """Kinetic product copy — stranger understands StillScout."""
    # Timed windows (absolute timeline)
    lines = [
        # (start, end, text, size, y_frac, font)
        (marks["hook"] + 0.4, marks["hook"] + 2.6, "You filmed the moment.", 64, 0.78, "georgia"),
        (marks["hands"] + 0.3, marks["profile"] + 0.2, "Finding the still is the hard part.", 58, 0.80, "georgia"),
        (marks["phone"] + 0.2, marks["still"] + 0.1, "Lost in the scrub.", 62, 0.78, "georgia"),
        (marks["still"] + 0.15, marks["ui1"] - 0.1, "StillScout finds it.", 70, 0.76, "didot"),
        # Keep kinetic lines off the UI screenshots (they already carry product copy)
        (marks["proof"] + 0.25, marks["proof"] + 2.6, "Same clip. Better still.", 66, 0.78, "georgia"),
    ]

    def font(name: str) -> str:
        if name == "didot":
            return "/System/Library/Fonts/Supplemental/Didot.ttc"
        return "/System/Library/Fonts/Supplemental/Georgia.ttf"

    parts = []
    for i, (st, en, text, size, yf, fn) in enumerate(lines):
        # escape for drawtext
        safe = text.replace(":", "\\:").replace("'", "\u2019")
        fade_in = 0.35
        fade_out = 0.35
        alpha = (
            f"if(lt(t,{st:.2f}),0,"
            f"if(lt(t,{st+fade_in:.2f}),(t-{st:.2f})/{fade_in},"
            f"if(lt(t,{en-fade_out:.2f}),0.92,"
            f"if(lt(t,{en:.2f}),({en:.2f}-t)/{fade_out}*0.92,0))))"
        )
        parts.append(
            f"drawtext=fontfile={font(fn)}:text='{safe}':fontsize={size}:"
            f"fontcolor=white@0.0:x=(w-text_w)/2:y=h*{yf}:"
            f"borderw=2:bordercolor=black@0.35:alpha='{alpha}'"
        )

    # End brand handled in end plate; add tiny product line before end
    st = marks["end"] - 0.05
    # actually end plate has its own text

    vf = ",".join(parts) if parts else "null"
    run([
        FF, "-y", "-i", str(video), "-vf", vf,
        "-c:v", "h264_videotoolbox", "-b:v", "48M", "-pix_fmt", "yuv420p", "-an",
        str(dst),
    ])
    return probe(dst)


def end_brand(dst: Path, dur: float = 6.4) -> float:
    logo = MARK if MARK.exists() else ROOT / "assets" / "stillscout_mark.png"
    comma = r"\,"
    fc = (
        f"color=c=0x0C0B0A:s={W}x{H}:d={dur}:r={FPS},format=yuv420p,vignette=PI/3.5[bg];"
        f"[0:v]format=rgba,scale=720:720,"
        f"fade=t=in:st=0:d=0.8:alpha=1,"
        f"fade=t=out:st={dur-1.4:.2f}:d=1.2:alpha=1[lg];"
        f"[bg][lg]overlay=x='(W-w)/2':"
        f"y='H*0.26-h/2+30*(1-min(1{comma}max(0{comma}(t-0.5)/1.0)))':"
        f"format=auto[v1];"
        f"[v1]"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Didot.ttc:"
        f"text='StillScout':fontsize=140:fontcolor=0xFFFAF5@0.0:"
        f"x=(w-text_w)/2:y=h*0.52:"
        f"alpha='if(lt(t,1.3),0,if(lt(t,2.2),(t-1.3)/0.9,if(gt(t,{dur-1.3:.2f}),"
        f"({dur:.2f}-t)/1.3,0.98)))',"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Georgia.ttf:"
        f"text='Scout the perfect still.':fontsize=56:fontcolor=0xF2E8DA@0.0:"
        f"x=(w-text_w)/2:y=h*0.52+150:"
        f"alpha='if(lt(t,2.1),0,if(lt(t,2.9),(t-2.1)/0.8,if(gt(t,{dur-1.2:.2f}),"
        f"({dur:.2f}-t)/1.2,0.92)))',"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Helvetica.ttc:"
        f"text='Drop any video. AI finds your best photo.':fontsize=42:fontcolor=0xC8C0B4@0.0:"
        f"x=(w-text_w)/2:y=h*0.52+250:"
        f"alpha='if(lt(t,2.7),0,if(lt(t,3.5),(t-2.7)/0.8,if(gt(t,{dur-1.2:.2f}),"
        f"({dur:.2f}-t)/1.2,0.85)))',"
        f"drawbox=x=(iw-320)/2:y=ih*0.485:w=320:h=2:color=0xD4B88C@0.9:t=fill:"
        f"enable='between(t,1.2,{dur-1.2:.2f})',"
        f"fade=t=in:st=0:d=0.4,fade=t=out:st={dur-1.3:.2f}:d=1.3[vout]"
    )
    run([
        FF, "-y", "-loop", "1", "-i", str(logo),
        "-filter_complex", fc, "-map", "[vout]", "-t", f"{dur:.3f}",
        "-c:v", "h264_videotoolbox", "-b:v", "40M", "-pix_fmt", "yuv420p",
        str(dst),
    ])
    return probe(dst)


def mix_audio(total: float, marks: dict[str, float], dst: Path) -> None:
    def ms(s: float) -> int:
        return max(0, int(s * 1000))

    t_hands = marks["hands"]
    t_profile = marks["profile"]
    t_phone = marks["phone"]
    t_still = marks["still"]
    t_ui1 = marks["ui1"]
    t_end = marks["end"]
    scribble_len = max(2.0, marks["phone"] - t_hands - 0.5)

    fc = (
        f"[0:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=70,lowpass=f=9000,volume=0.34,"
        f"afade=t=in:st=0:d=1.2,afade=t=out:st={total-2}:d=2[ocean];"
        f"[1:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=200,lowpass=f=3400,volume=0.07,afade=t=in:st=0:d=1.5[wind];"
        f"[2:a]aloop=loop=-1:size=2e+09,atrim=0:{scribble_len:.2f},asetpts=N/SR/TB,"
        f"adelay={ms(t_hands)}|{ms(t_hands)},highpass=f=800,volume=0.80,"
        f"afade=t=in:st=0:d=0.15,afade=t=out:st={scribble_len-0.45:.2f}:d=0.45,"
        f"atrim=0:{total},asetpts=N/SR/TB[scribble];"
        f"[3:a]adelay={ms(t_hands+0.6)}|{ms(t_hands+0.6)},volume=0.8,highpass=f=1000,atrim=0:{total},asetpts=N/SR/TB[pen1];"
        f"[4:a]adelay={ms(t_profile+0.4)}|{ms(t_profile+0.4)},volume=0.65,highpass=f=1100,atrim=0:{total},asetpts=N/SR/TB[pen2];"
        f"[5:a]adelay={ms(0.2)}|{ms(0.2)},volume=0.7,atrim=0:{total},asetpts=N/SR/TB[book];"
        f"[6:a]adelay={ms(t_phone)}|{ms(t_phone)},volume=0.35,atrim=0:{total},asetpts=N/SR/TB[fab];"
        f"[7:a]adelay={ms(t_still)}|{ms(t_still)},volume=0.32,lowpass=f=3500,atrim=0:{total},asetpts=N/SR/TB[shutter];"
        f"[7:a]adelay={ms(t_ui1)}|{ms(t_ui1)},volume=0.22,lowpass=f=3000,atrim=0:{total},asetpts=N/SR/TB[uiwhoosh];"
        f"[7:a]adelay={ms(t_end+0.3)}|{ms(t_end+0.3)},volume=0.20,lowpass=f=2600,atrim=0:{total},asetpts=N/SR/TB[endwhoosh];"
        f"[ocean][wind][scribble][pen1][pen2][book][fab][shutter][uiwhoosh][endwhoosh]"
        f"amix=inputs=10:normalize=0:dropout_transition=2,"
        f"volume='if(lt(t,{t_end:.2f}),1.0,0.30)',"
        f"alimiter=limit=0.9,loudnorm=I=-18:TP=-2:LRA=9[aout]"
    )
    inputs = [
        AUDIO / "ocean.mp3", AUDIO / "wind.mp3", AUDIO / "writing_1.mp3",
        AUDIO / "pen_on_paper.mp3", AUDIO / "pencil_scribble.mp3",
        AUDIO / "book_open.mp3", AUDIO / "clothes_rustle.mp3", AUDIO / "soft_whoosh.mp3",
    ]
    cmd = [FF, "-y"]
    for p in inputs:
        cmd += ["-i", str(p)]
    cmd += ["-filter_complex", fc, "-map", "[aout]", "-t", str(total),
            "-c:a", "aac", "-b:a", "320k", str(dst)]
    run(cmd)


def export_safe(src: Path, dst: Path) -> None:
    run([
        FF, "-y", "-i", str(src),
        "-vf", "scale=1080:1920:flags=lanczos,format=yuv420p",
        "-c:v", "libx264", "-preset", "fast", "-crf", "17",
        "-profile:v", "high", "-level", "4.1", "-pix_fmt", "yuv420p",
        "-colorspace", "bt709", "-color_primaries", "bt709",
        "-color_trc", "bt709", "-color_range", "tv",
        "-movflags", "+faststart", "-c:a", "aac", "-b:a", "256k",
        str(dst),
    ])


def main() -> int:
    clips = WORK / "clips"
    clips.mkdir(parents=True, exist_ok=True)
    EXPORT.mkdir(parents=True, exist_ok=True)

    plan: list[tuple[Path, float, str]] = []

    # 1 Hook face — emotional open + zoom
    d = render("MVI_0353.MP4", clips / "01_hook.mp4",
               start=16.8, duration=2.6, speed=0.88, grade="face", fade_in=0.6,
               crop_y="(ih-oh)/2+320", motion_kind="push_hard")
    plan.append((clips / "01_hook.mp4", d, "hook"))

    # 2 Hands writing
    d = render("MVI_0356.MP4", clips / "02_hands.mp4",
               start=5.0, duration=2.8, speed=0.82, grade="detail",
               crop_y="(ih-oh)/2", motion_kind="push")
    plan.append((clips / "02_hands.mp4", d, "hands"))

    # 3 Handsome profile
    d = render("MVI_0358.MP4", clips / "03_profile.mp4",
               start=2.5, duration=3.8, speed=0.88, grade="face",
               crop_y="(ih-oh)/2+40", motion_kind="rise")
    plan.append((clips / "03_profile.mp4", d, "profile"))

    # 4 Harbor world
    d = render("MVI_0343.MP4", clips / "04_harbor.mp4",
               start=1.0, duration=3.0, speed=0.92, grade="wide",
               crop_y="(ih-oh)/2+50", motion_kind="pull")
    plan.append((clips / "04_harbor.mp4", d, "harbor"))

    # 5 Phone raise WITH viewfinder hunting
    d = render("MVI_0363.MP4", clips / "05_phone.mp4",
               start=9.2, duration=3.0, speed=0.92, grade="wide",
               crop_y="(ih-oh)/2+60", motion_kind="rise", finder=True)
    plan.append((clips / "05_phone.mp4", d, "phone"))

    # 6 Capture still + AI score (bright handsome face)
    still = clips / "06_still.mp4"
    face_src = clips / "06_face_src.mp4"
    render("MVI_0353.MP4", face_src,
           start=17.0, duration=2.2, speed=1.0, grade="face",
           crop_y="(ih-oh)/2+300", motion_kind="push")
    d = render_capture_still(face_src, still, at=0.9, hold=1.4)
    plan.append((still, d, "still"))

    # 7 UI — AI scouting screenshot (readable headlines)
    ui1 = clips / "07_ui_scout.mp4"
    d = render_screenshot(SHOTS / "02_ai_scouting.png", ui1, dur=4.2, zoom="in")
    plan.append((ui1, d, "ui1"))

    # 8 UI — Top picks / results
    ui2 = clips / "08_ui_picks.mp4"
    d = render_screenshot(SHOTS / "01_hero.png", ui2, dur=4.0, zoom="in")
    plan.append((ui2, d, "ui2"))

    # 9 Export proof UI beat
    ui3 = clips / "09_ui_export.mp4"
    d = render_screenshot(SHOTS / "05_export.png", ui3, dur=3.0, zoom="in")
    plan.append((ui3, d, "ui3"))

    # 10 Proof — beauty face (emotional close)
    d = render("MVI_0353.MP4", clips / "10_proof.mp4",
               start=17.5, duration=3.0, speed=0.86, grade="face",
               crop_y="(ih-oh)/2+340", motion_kind="push_hard")
    plan.append((clips / "10_proof.mp4", d, "proof"))

    # 11 Brand plate with product one-liner
    end = clips / "11_brand.mp4"
    d = end_brand(end, dur=6.4)
    plan.append((end, d, "end"))

    marks_raw: dict[str, float] = {}
    cum = 0.0
    for path, dur, name in plan:
        marks_raw[name] = cum
        print(f"  {path.name}: {dur:.2f}s @{cum:.2f}")
        cum += dur

    paths = [p for p, _, _ in plan]
    durs = [d for _, d, _ in plan]
    xfade = 0.28
    raw = WORK / "picture_raw.mp4"
    total = assemble(paths, durs, raw, xfade=xfade)
    marks = {n: max(0.0, marks_raw[n] - xfade * i) for i, (_, _, n) in enumerate(plan)}
    print("Picture:", total)
    print("Marks:", {k: round(v, 2) for k, v in marks.items()})

    pictured = WORK / "picture.mp4"
    burn_story_copy(raw, pictured, marks, total)
    total = probe(pictured)

    audio = WORK / "mix.m4a"
    mix_audio(total, marks, audio)

    master4k = WORK / "master4k.mp4"
    run([
        FF, "-y", "-i", str(pictured), "-i", str(audio),
        "-map", "0:v", "-map", "1:a",
        "-c:v", "copy", "-c:a", "aac", "-b:a", "320k",
        "-movflags", "+faststart", "-shortest", str(master4k),
    ])

    play = EXPORT / "StillScout_PLAY_ME_1080x1920.mp4"
    best = EXPORT / "StillScout_Best_1080x1920.mp4"
    social = EXPORT / "StillScout_BeforeTheCapture_1080x1920.mp4"
    vo = EXPORT / "StillScout_VO_BED_1080x1920.mp4"
    master = EXPORT / "StillScout_BeforeTheCapture_4K_9x16.mp4"
    run(["cp", str(master4k), str(master)])
    export_safe(master4k, play)
    for p in (best, social, vo):
        run(["cp", str(play), str(p)])

    meta = {
        "title": "StillScout — Director Product Reel (v9)",
        "duration_sec": probe(play),
        "product_message": "Drop any video. AI finds your best photo. Scout the perfect still.",
        "story": [
            "You filmed the moment.",
            "Finding the still is the hard part.",
            "Lost in the scrub.",
            "StillScout finds it.",
            "AI ranks every frame.",
            "Top picks. Post-ready.",
            "Same clip. Better still.",
            "StillScout — Scout the perfect still.",
        ],
        "animations": [
            "hard Ken Burns pushes",
            "viewfinder hunting overlay",
            "AI score badge on capture freeze",
            "ASC UI inserts with zoom",
            "kinetic product copy",
            "clean brand end with product one-liner",
        ],
        "play": str(play),
        "vo_window_sec": [round(marks["end"] + 1.3, 1), round(total - 0.8, 1)],
    }
    (EXPORT / "manifest_v9.json").write_text(json.dumps(meta, indent=2))
    (EXPORT / "NARRATION_SCRIPT.md").write_text(
        "# StillScout VO — v9 Product Reel\n\n"
        f"**Length:** ~{probe(play):.0f}s · File: `StillScout_PLAY_ME_1080x1920.mp4`\n\n"
        "On-screen text already explains the product. Your VO can echo it softly:\n\n"
        "```\n"
        "You filmed the moment.\n"
        "Finding the still is the hard part.\n"
        "StillScout finds it.\n"
        "AI ranks every frame.\n"
        "Same clip. Better still.\n\n"
        "StillScout.\n"
        "Scout the perfect still.\n"
        "```\n\n"
        f"**Brand line (~{marks['end']+1.5:.0f}s):** StillScout… scout the perfect still.\n"
    )
    print(json.dumps(meta, indent=2))
    print("DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
