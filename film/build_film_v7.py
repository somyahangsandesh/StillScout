#!/usr/bin/env python3
"""StillScout v7 — upgraded review cut of the liked ~41s film.

Fixes from v6 review:
- Less bloom wash / clearer handsome face (eyes sharp, skin soft)
- Richer opening notebook (no muddy start)
- Shorter xfades to kill ghosting
- Louder picture-locked Foley + social loudness
- Clean animated end brand on soft fade (no ugly mid bar)
- Whisper brand on sky breath
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
WORK = ROOT / "work_v7"
EXPORT = ROOT / "export"
AUDIO = ROOT / "audio" / "src_v5"
AUDIO_V3 = ROOT / "audio" / "src_v3"
MARK = ROOT / "assets" / "stillscout_mark_light.png"
W, H, FPS = 2160, 3840, 30

# Handsome but clear — soft skin, sharp eyes, warm, NOT washed
FACE = (
    "format=yuv420p,"
    "hqdn3d=2.8:1.8:3.5:2.2,"
    "bilateral=sigmaS=2.8:sigmaR=0.09,"
    "eq=contrast=0.92:brightness=0.035:saturation=0.86:gamma=1.04,"
    "curves="
    "red='0/0.05 0.3/0.34 0.55/0.60 1/0.99':"
    "green='0/0.05 0.3/0.33 0.55/0.57 1/0.975':"
    "blue='0/0.06 0.3/0.32 0.55/0.54 1/0.96',"
    "colorbalance=rs=0.04:gs=0.012:bs=-0.02:rm=0.05:gm=0.015:bm=-0.025:rh=0.02:gh=0.008:bh=-0.012,"
    "split[base][glow];[glow]gblur=sigma=8[g];"
    "[base][g]blend=all_mode=screen:all_opacity=0.09,"
    "unsharp=5:5:0.55:5:5:0.15,"
    "vignette=PI/5.2,"
    "noise=alls=2:allf=t"
)

DETAIL = (
    "format=yuv420p,"
    "hqdn3d=2.2:1.4:3:2,"
    "eq=contrast=0.94:brightness=0.04:saturation=0.90:gamma=1.03,"
    "curves=all='0/0.04 0.5/0.54 1/0.985',"
    "colorbalance=rs=0.03:gs=0.01:bs=-0.015:rm=0.035:gm=0.012:bm=-0.018,"
    "split[base][glow];[glow]gblur=sigma=6[g];"
    "[base][g]blend=all_mode=screen:all_opacity=0.07,"
    "unsharp=5:5:0.45:5:5:0.1,"
    "vignette=PI/5.5"
)

WIDE = (
    "format=yuv420p,"
    "hqdn3d=1.8:1.2:2.5:1.8,"
    "eq=contrast=0.96:brightness=0.025:saturation=0.92:gamma=1.02,"
    "curves=all='0/0.03 0.5/0.53 1/0.98',"
    "colorbalance=rs=0.02:gs=0.008:bs=-0.012:rm=0.025:gm=0.01:bm=-0.015,"
    "unsharp=5:5:0.4:5:5:0.1"
)


def run(cmd: list[str]) -> None:
    print("+", " ".join(str(c) for c in cmd[:11]), "...")
    subprocess.run(cmd, check=True)


def probe(path: Path) -> float:
    return float(subprocess.check_output(
        [FP, "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        text=True,
    ).strip())


def motion_crop(kind: str, out_dur: float, crop_y_bias: str) -> str:
    comma = r"\,"
    if kind == "push_in":
        y = crop_y_bias.replace(
            "(ih-oh)/2",
            f"(ih-oh)/2 - (t/{out_dur:.3f})*min(ih*0.035{comma}90)",
        )
        return (
            f"scale={int(W*1.12)}:{int(H*1.12)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2':y='{y}'"
        )
    if kind == "pull_out":
        y = crop_y_bias.replace(
            "(ih-oh)/2",
            f"(ih-oh)/2 + (t/{out_dur:.3f})*min(ih*0.03{comma}70)",
        )
        return (
            f"scale={int(W*1.14)}:{int(H*1.14)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2':y='{y}'"
        )
    if kind == "drift_r":
        return (
            f"scale={int(W*1.12)}:{int(H*1.12)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:"
            f"x='(iw-ow)/2 + (t/{out_dur:.3f})*min(iw*0.025{comma}55)':"
            f"y='{crop_y_bias}'"
        )
    if kind == "rise":
        y = crop_y_bias.replace(
            "(ih-oh)/2",
            f"(ih-oh)/2 - (t/{out_dur:.3f})*min(ih*0.03{comma}80)",
        )
        return (
            f"scale={int(W*1.12)}:{int(H*1.12)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2':y='{y}'"
        )
    return (
        f"scale={W}:{H}:force_original_aspect_ratio=increase:flags=lanczos,"
        f"crop={W}:{H}:(iw-ow)/2:{crop_y_bias}"
    )


def render(
    src: str,
    dst: Path,
    *,
    start: float,
    duration: float,
    speed: float = 1.0,
    grade: str = "detail",
    fade_in: float = 0.0,
    fade_out: float = 0.0,
    crop_y: str = "(ih-oh)/2",
    motion: str = "push_in",
) -> float:
    out_dur = duration / speed
    g = {"face": FACE, "detail": DETAIL, "wide": WIDE}[grade]
    crop = motion_crop(motion, out_dur, crop_y)
    vf = f"deshake=rx=16:ry=16,setpts=PTS/{speed},{crop},{g}"
    if fade_in:
        vf += f",fade=t=in:st=0:d={fade_in}"
    if fade_out:
        vf += f",fade=t=out:st={max(0.01, out_dur - fade_out)}:d={fade_out}"
    run([
        FF, "-y", "-ss", f"{start:.2f}", "-t", f"{duration:.2f}",
        "-i", str(FOOTAGE / src), "-vf", vf, "-an", "-r", str(FPS),
        "-c:v", "h264_videotoolbox", "-b:v", "50M", "-pix_fmt", "yuv420p",
        "-t", f"{out_dur:.3f}", str(dst),
    ])
    return probe(dst)


def render_still_freeze(src_clip: Path, dst: Path, *, at: float, hold: float = 0.55) -> float:
    frame = WORK / "still_frame.png"
    run([FF, "-y", "-ss", f"{at:.2f}", "-i", str(src_clip), "-frames:v", "1", str(frame)])
    # Soft white flash into still + micro zoom — "capture" feel
    run([
        FF, "-y", "-loop", "1", "-i", str(frame),
        "-vf",
        f"scale={W}:{H},"
        f"zoompan=z='min(1.05,1+0.025*on/{max(1, int(hold*FPS))})':"
        f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s={W}x{H}:fps={FPS},"
        "format=yuv420p,vignette=PI/4.5,"
        "eq=contrast=1.02:brightness=0.02:saturation=0.9,"
        f"fade=t=in:st=0:d=0.12:color=white",
        "-t", f"{hold:.3f}",
        "-c:v", "h264_videotoolbox", "-b:v", "50M", "-pix_fmt", "yuv420p",
        str(dst),
    ])
    return probe(dst)


def assemble_with_xfades(clips: list[Path], durs: list[float], dst: Path, xfade: float = 0.38) -> float:
    inputs: list[str] = []
    for c in clips:
        inputs += ["-i", str(c)]
    parts = []
    offset = durs[0] - xfade
    parts.append(
        f"[0:v][1:v]xfade=transition=fade:duration={xfade}:offset={offset:.3f}[v01]"
    )
    prev = "v01"
    acc = durs[0] + durs[1] - xfade
    for i in range(2, len(clips)):
        offset = acc - xfade
        out = "vout" if i == len(clips) - 1 else f"v{i:02d}"
        parts.append(
            f"[{prev}][{i}:v]xfade=transition=fade:duration={xfade}:offset={offset:.3f}[{out}]"
        )
        prev = out
        acc = acc + durs[i] - xfade
    total = sum(durs) - xfade * (len(clips) - 1)
    run([
        FF, "-y", *inputs,
        "-filter_complex", ";".join(parts),
        "-map", "[vout]",
        "-c:v", "h264_videotoolbox", "-b:v", "50M",
        "-pix_fmt", "yuv420p", "-t", f"{total:.3f}",
        str(dst),
    ])
    return probe(dst)


def burn_mid_whisper(video: Path, dst: Path, sky_t: float) -> float:
    """Elegant StillScout whisper over empty sky."""
    start = sky_t + 0.55
    end = start + 2.4
    vf = (
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Didot.ttc:"
        f"text='StillScout':fontsize=88:fontcolor=white@0.0:"
        f"x=(w-text_w)/2:y=h*0.18:"
        f"alpha='if(lt(t,{start:.2f}),0,if(lt(t,{start+0.7:.2f}),(t-{start:.2f})/0.7,"
        f"if(lt(t,{end-0.6:.2f}),0.62,if(lt(t,{end:.2f}),({end:.2f}-t)/0.6*0.62,0))))'"
    )
    run([
        FF, "-y", "-i", str(video), "-vf", vf,
        "-c:v", "h264_videotoolbox", "-b:v", "50M", "-pix_fmt", "yuv420p",
        "-an", str(dst),
    ])
    return probe(dst)


def render_end_brand(base: Path, dst: Path) -> float:
    """Clean brand stage: picture fades under soft dark, logo animates, VO room."""
    dur = probe(base)
    logo = MARK if MARK.exists() else ROOT / "assets" / "stillscout_mark.png"
    # Soft vignette veil + centered logo float + wordmark + tagline
    # Avoid hard mid bar — use full soft darken instead
    fc = (
        f"[0:v]format=yuv420p,"
        f"drawbox=x=0:y=0:w=iw:h=ih:color=black@0.22:t=fill:enable='gte(t,0.6)',"
        f"drawbox=x=0:y=0:w=iw:h=ih:color=black@0.48:t=fill:enable='gte(t,1.2)'[bg];"
        f"[1:v]format=rgba,scale=820:820,"
        f"fade=t=in:st=0:d=0.9:alpha=1,"
        f"fade=t=out:st={dur-1.5:.2f}:d=1.3:alpha=1[lg];"
        f"[bg][lg]overlay="
        f"x='(W-w)/2':"
        f"y='H*0.30-h/2 + 40*(1-min(1\\,max(0\\,(t-0.7)/1.1)))':"
        f"format=auto:eof_action=pass[v1];"
        f"[v1]"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Didot.ttc:"
        f"text='StillScout':fontsize=142:fontcolor=0xFFFAF5@0.0:"
        f"x=(w-text_w)/2:y=h*0.58:"
        f"alpha='if(lt(t,1.7),0,if(lt(t,2.7),(t-1.7)/1.0,if(gt(t,{dur-1.4:.2f}),"
        f"({dur:.2f}-t)/1.4,0.97)))',"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Georgia.ttf:"
        f"text='Scout the perfect still.':fontsize=58:fontcolor=0xFFF8F0@0.0:"
        f"x=(w-text_w)/2:y=h*0.58+155:"
        f"alpha='if(lt(t,2.5),0,if(lt(t,3.4),(t-2.5)/0.9,if(gt(t,{dur-1.3:.2f}),"
        f"({dur:.2f}-t)/1.3,0.92)))',"
        f"drawbox=x=(iw-360)/2:y=ih*0.545:w=360:h=2:color=0xD4B88C@0.9:t=fill:"
        f"enable='between(t,1.5,{dur-1.3:.2f})',"
        f"fade=t=out:st={dur-1.4:.2f}:d=1.4[vout]"
    )
    run([
        FF, "-y", "-i", str(base), "-loop", "1", "-i", str(logo),
        "-filter_complex", fc, "-map", "[vout]",
        "-t", f"{dur:.3f}",
        "-c:v", "h264_videotoolbox", "-b:v", "50M", "-pix_fmt", "yuv420p",
        str(dst),
    ])
    return probe(dst)


def mix_audio(total: float, marks: dict[str, float], dst: Path) -> None:
    def ms(sec: float) -> int:
        return max(0, int(sec * 1000))

    piano = AUDIO_V3 / "km_peaceful.mp3"
    if not piano.exists():
        piano = AUDIO / "piano.mp3"

    t_hands = marks["hands"]
    t_profile = marks["profile"]
    t_face = marks["face"]
    t_harbor = marks["harbor"]
    t_phone = marks["phone"]
    t_still = marks["still"]
    t_end = marks["end"]
    vo_duck = max(0.5, total - 7.0)
    scribble_len = max(2.5, t_harbor - t_hands - 0.3)

    fc = (
        f"[0:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=65,lowpass=f=10000,volume=0.52,"
        f"afade=t=in:st=0:d=1.6,afade=t=out:st={total-2.5}:d=2.5[ocean];"
        f"[1:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=180,lowpass=f=3600,volume=0.13,afade=t=in:st=0:d=1.8[wind];"
        f"[2:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"volume=0.12,highpass=f=850,lowpass=f=5800,"
        f"afade=t=in:st={t_harbor:.2f}:d=2,afade=t=out:st={vo_duck:.2f}:d=2.2[gulls];"
        f"[3:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=120,lowpass=f=4800,volume=0.12,afade=t=in:st=0:d=1.2[loc];"
        f"[4:a]adelay={ms(1.2)}|{ms(1.2)},atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=85,lowpass=f=5600,"
        f"acompressor=threshold=-22dB:ratio=2.4:attack=50:release=300,"
        f"volume=0.38,afade=t=in:st=0:d=3.0,afade=t=out:st={vo_duck:.2f}:d=2.4[piano];"
        # LOUDER scribble locked to writing
        f"[5:a]aloop=loop=-1:size=2e+09,atrim=0:{scribble_len:.2f},asetpts=N/SR/TB,"
        f"adelay={ms(t_hands)}|{ms(t_hands)},"
        f"highpass=f=700,lowpass=f=10000,volume=0.95,"
        f"afade=t=in:st=0:d=0.2,afade=t=out:st={scribble_len-0.55:.2f}:d=0.55,"
        f"atrim=0:{total},asetpts=N/SR/TB[scribble];"
        f"[6:a]adelay={ms(t_hands + 0.7)}|{ms(t_hands + 0.7)},volume=0.95,highpass=f=1000,atrim=0:{total},asetpts=N/SR/TB[pen1];"
        f"[7:a]adelay={ms(t_profile + 0.4)}|{ms(t_profile + 0.4)},volume=0.78,highpass=f=1100,atrim=0:{total},asetpts=N/SR/TB[pen2];"
        f"[8:a]adelay={ms(t_profile + 2.0)}|{ms(t_profile + 2.0)},volume=0.72,highpass=f=1000,atrim=0:{total},asetpts=N/SR/TB[pen3];"
        f"[6:a]adelay={ms(t_face + 0.5)}|{ms(t_face + 0.5)},volume=0.55,highpass=f=1000,atrim=0:{total},asetpts=N/SR/TB[pen4];"
        f"[9:a]adelay={ms(0.2)}|{ms(0.2)},volume=0.90,atrim=0:{total},asetpts=N/SR/TB[book];"
        f"[10:a]adelay={ms(0.75)}|{ms(0.75)},volume=0.75,atrim=0:{total},asetpts=N/SR/TB[page1];"
        f"[11:a]adelay={ms(t_end + 0.25)}|{ms(t_end + 0.25)},volume=0.70,atrim=0:{total},asetpts=N/SR/TB[page2];"
        f"[10:a]adelay={ms(t_end + 1.4)}|{ms(t_end + 1.4)},volume=0.50,atrim=0:{total},asetpts=N/SR/TB[page3];"
        f"[12:a]adelay={ms(t_profile)}|{ms(t_profile)},volume=0.40,atrim=0:{total},asetpts=N/SR/TB[fab1];"
        f"[13:a]adelay={ms(t_phone + 0.15)}|{ms(t_phone + 0.15)},volume=0.48,atrim=0:{total},asetpts=N/SR/TB[fab2];"
        f"[14:a]adelay={ms(t_harbor)}|{ms(t_harbor)},volume=0.38,lowpass=f=4200,atrim=0:{total},asetpts=N/SR/TB[whoosh1];"
        f"[14:a]adelay={ms(t_still)}|{ms(t_still)},volume=0.28,lowpass=f=3500,atrim=0:{total},asetpts=N/SR/TB[whoosh2];"
        f"[14:a]adelay={ms(t_end + 0.85)}|{ms(t_end + 0.85)},volume=0.30,lowpass=f=2800,atrim=0:{total},asetpts=N/SR/TB[whoosh3];"
        f"[ocean][wind][gulls][loc][piano][scribble][pen1][pen2][pen3][pen4]"
        f"[book][page1][page2][page3][fab1][fab2][whoosh1][whoosh2][whoosh3]"
        f"amix=inputs=19:normalize=0:dropout_transition=2,"
        f"equalizer=f=200:t=q:w=1:g=-1.5,"
        f"equalizer=f=3500:t=q:w=1:g=2.2,"
        f"equalizer=f=7000:t=q:w=1:g=1.4,"
        # Soft VO pocket — keep presence, don't kill the bed
        f"volume='if(lt(t,{vo_duck:.2f}),1.0,0.35)',"
        f"alimiter=limit=0.92,loudnorm=I=-14:TP=-1.2:LRA=9[aout]"
    )
    inputs = [
        AUDIO / "ocean.mp3", AUDIO / "wind.mp3", AUDIO / "seagulls.mp3",
        AUDIO / "loc.wav" if (AUDIO / "loc.wav").exists() else AUDIO / "ocean.mp3",
        piano, AUDIO / "writing_1.mp3", AUDIO / "pen_on_paper.mp3",
        AUDIO / "pencil_scribble.mp3", AUDIO / "pen_write.mp3",
        AUDIO / "book_open.mp3", AUDIO / "page_turn_soft.mp3",
        AUDIO / "page_flip_2.mp3", AUDIO / "fabric_2.mp3",
        AUDIO / "clothes_rustle.mp3", AUDIO / "soft_whoosh.mp3",
    ]
    cmd = [FF, "-y"]
    for p in inputs:
        cmd += ["-i", str(p)]
    cmd += ["-filter_complex", fc, "-map", "[aout]", "-t", str(total),
            "-c:a", "aac", "-b:a", "320k", str(dst)]
    run(cmd)


def main() -> int:
    clips = WORK / "clips"
    clips.mkdir(parents=True, exist_ok=True)
    EXPORT.mkdir(parents=True, exist_ok=True)

    # Preserve v6 social as reference
    v6 = EXPORT / "StillScout_Best_1080x1920.mp4"
    if v6.exists():
        run(["cp", str(v6), str(EXPORT / "StillScout_v6_review_ref_1080x1920.mp4")])

    plan: list[tuple[Path, float, str]] = []

    # 1 notebook — brighter detail grade
    d = render("MVI_0387.MP4", clips / "01_pages.mp4",
               start=0.9, duration=3.0, speed=0.90, grade="detail", fade_in=0.85,
               crop_y="(ih-oh)/2-40", motion="push_in")
    plan.append((clips / "01_pages.mp4", d, "notebook"))

    # 2 hands — scribble hero
    d = render("MVI_0356.MP4", clips / "02_hands.mp4",
               start=5.2, duration=3.7, speed=0.80, grade="detail",
               crop_y="(ih-oh)/2", motion="drift_r")
    plan.append((clips / "02_hands.mp4", d, "hands"))

    # 3 best profile — linger, clear handsome
    d = render("MVI_0358.MP4", clips / "03_profile.mp4",
               start=2.5, duration=5.0, speed=0.85, grade="face",
               crop_y="(ih-oh)/2+40", motion="rise")
    plan.append((clips / "03_profile.mp4", d, "profile"))

    # 4 face — tighter crop, less wash
    d = render("MVI_0353.MP4", clips / "04_face.mp4",
               start=17.0, duration=3.8, speed=0.84, grade="face",
               crop_y="(ih-oh)/2+320", motion="rise")
    plan.append((clips / "04_face.mp4", d, "face"))

    # 5 harbor
    d = render("MVI_0343.MP4", clips / "05_harbor.mp4",
               start=1.0, duration=3.9, speed=0.92, grade="wide",
               crop_y="(ih-oh)/2+60", motion="pull_out")
    plan.append((clips / "05_harbor.mp4", d, "harbor"))

    # 6 sky
    d = render("MVI_0365.MP4", clips / "06_sky.mp4",
               start=8.5, duration=3.6, speed=0.88, grade="wide",
               crop_y="(ih-oh)/2", motion="push_in")
    plan.append((clips / "06_sky.mp4", d, "sky"))

    # 7 phone raise
    d = render("MVI_0363.MP4", clips / "07_raise.mp4",
               start=9.2, duration=3.6, speed=0.90, grade="wide",
               crop_y="(ih-oh)/2+70", motion="rise")
    plan.append((clips / "07_raise.mp4", d, "phone"))

    # 8 screen + capture freeze
    screen = clips / "08_screen_live.mp4"
    d_live = render("MVI_0378.MP4", screen,
                    start=3.6, duration=2.8, speed=0.92, grade="detail",
                    crop_y="(ih-oh)/2", motion="push_in")
    freeze = clips / "08b_still.mp4"
    render_still_freeze(screen, freeze, at=min(2.0, d_live - 0.25), hold=0.55)
    screen_full = clips / "08_screen.mp4"
    lst = WORK / "screen_concat.txt"
    lst.write_text(f"file '{screen}'\nfile '{freeze}'\n")
    run([FF, "-y", "-f", "concat", "-safe", "0", "-i", str(lst), "-c", "copy", str(screen_full)])
    plan.append((screen_full, probe(screen_full), "screen"))

    # 9 rest — handsome settle
    d = render("MVI_0359.MP4", clips / "09_rest.mp4",
               start=5.2, duration=2.9, speed=0.90, grade="face",
               crop_y="(ih-oh)/2+80", motion="rise")
    plan.append((clips / "09_rest.mp4", d, "rest"))

    # 10 end brand
    end_base = clips / "10_end_base.mp4"
    render("MVI_0387.MP4", end_base,
           start=2.5, duration=6.2, speed=0.92, grade="detail", fade_in=0.3,
           crop_y="(ih-oh)/2-30", motion="push_in")
    end = clips / "10_end.mp4"
    d = render_end_brand(end_base, end)
    plan.append((end, d, "end"))

    marks_raw: dict[str, float] = {}
    cum = 0.0
    for path, dur, name in plan:
        marks_raw[name] = cum
        print(f"  {path.name}: {dur:.2f}s @{cum:.2f}")
        cum += dur

    paths = [p for p, _, _ in plan]
    durs = [d for _, d, _ in plan]
    xfade = 0.38
    picture_raw = WORK / "picture_raw.mp4"
    total = assemble_with_xfades(paths, durs, picture_raw, xfade=xfade)
    print("Picture raw:", total)

    marks = {name: max(0.0, marks_raw[name] - xfade * i) for i, (_, _, name) in enumerate(plan)}
    marks["still"] = marks["screen"] + durs[7] - 0.55
    print("Marks:", {k: round(v, 2) for k, v in marks.items()})

    picture = WORK / "picture.mp4"
    burn_mid_whisper(picture_raw, picture, marks["sky"])
    total = probe(picture)

    audio = WORK / "mix.m4a"
    mix_audio(total, marks, audio)

    master = EXPORT / "StillScout_BeforeTheCapture_4K_9x16.mp4"
    social = EXPORT / "StillScout_BeforeTheCapture_1080x1920.mp4"
    best4k = EXPORT / "StillScout_Best_4K_9x16.mp4"
    best1080 = EXPORT / "StillScout_Best_1080x1920.mp4"

    run([
        FF, "-y", "-i", str(picture), "-i", str(audio),
        "-map", "0:v", "-map", "1:a",
        "-c:v", "copy", "-c:a", "aac", "-b:a", "320k",
        "-movflags", "+faststart", "-shortest", str(master),
    ])
    run([
        FF, "-y", "-i", str(master),
        "-vf", "scale=1080:1920:flags=lanczos",
        "-c:v", "h264_videotoolbox", "-b:v", "16M",
        "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-c:a", "copy",
        str(social),
    ])
    run(["cp", str(master), str(best4k)])
    run(["cp", str(social), str(best1080)])

    err = subprocess.run(
        [FF, "-v", "error", "-i", str(master), "-f", "null", "-"],
        capture_output=True, text=True,
    )
    print("DECODE:", "CLEAN" if not err.stderr.strip() else err.stderr[:400])

    meta = {
        "title": "StillScout — Before the Capture (v7 upgrade)",
        "based_on": "v6 review fixes on liked ~41s cut",
        "duration_sec": probe(master),
        "review_scores_v6": {
            "story": 8.5,
            "face_beauty": 6.0,
            "grade_consistency": 5.5,
            "sound_design": 7.0,
            "brand_end": 6.5,
            "overall": 7.0,
        },
        "upgrades": [
            "clearer handsome face grade (less bloom wash)",
            "brighter opening notebook",
            "shorter xfades (less ghosting)",
            "louder picture-locked scribble Foley",
            "social loudness ~-14 LUFS",
            "clean animated end brand + sky whisper",
            "capture flash freeze on phone still",
        ],
        "voiceover_window_sec": [round(total - 7.0, 2), round(total - 0.8, 2)],
        "master": str(master),
        "social": str(social),
    }
    (EXPORT / "manifest_v7.json").write_text(json.dumps(meta, indent=2))
    (EXPORT / "REVIEW_v6.md").write_text(
        "# StillScout v6 Review\n\n"
        "## Score: **7.0 / 10**\n\n"
        "| Area | Score | Note |\n|------|------:|------|\n"
        "| Story / cut | 8.5 | Strong notebook→world→scout arc |\n"
        "| Face / handsome | 6.0 | Over-bloomed, washed, soft eyes |\n"
        "| Grade consistency | 5.5 | Dark muddy open vs bright mids |\n"
        "| Sound | 7.0 | Good idea, too quiet overall |\n"
        "| Brand end | 6.5 | Logo ok, ugly dark bar over pages |\n"
        "| Transitions | 5.5 | Long xfade = ghosting |\n\n"
        "## Fixes shipped in v7\n"
        "- Clearer face grade, tighter face crop\n"
        "- Shorter crossfades\n"
        "- Louder synced scribble + -14 LUFS mix\n"
        "- Clean end brand stage + sky whisper\n"
        "- Capture flash on the perfect still\n"
    )
    (EXPORT / "NARRATION_CUE_v7.txt").write_text(
        f"Speak around {total - 6.5:.1f}s:\n"
        "  StillScout… scout the perfect still.\n"
    )
    print(json.dumps(meta, indent=2))
    print("DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
