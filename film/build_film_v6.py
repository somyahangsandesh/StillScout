#!/usr/bin/env python3
"""StillScout v6 — elevate the liked ~41s cut.

Based on v4 'Before the Capture':
- Ken Burns micro-motion on every shot
- Beauty grade pushed for face/profile
- Scribble / page Foley locked to picture
- Creative 'perfect still' freeze on the phone screen
- Animated StillScout mark + wordmark end brand
- Music ducks at the end for VO: "StillScout, scout the perfect still"
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
WORK = ROOT / "work_v6"
EXPORT = ROOT / "export"
AUDIO = ROOT / "audio" / "src_v5"
AUDIO_V3 = ROOT / "audio" / "src_v3"
MARK = ROOT / "assets" / "stillscout_mark_light.png"
W, H, FPS = 2160, 3840, 30

# Extra-handsome face grade: softer skin, warmer cheeks, creamy bloom
BEAUTY = (
    "format=yuv420p,"
    "hqdn3d=4.5:3:5.5:3.5,"
    "bilateral=sigmaS=5.0:sigmaR=0.16,"
    "eq=contrast=0.80:brightness=0.065:saturation=0.72:gamma=1.10,"
    "curves="
    "red='0/0.09 0.26/0.38 0.52/0.64 1/0.998':"
    "green='0/0.08 0.26/0.35 0.52/0.59 1/0.985':"
    "blue='0/0.10 0.26/0.33 0.52/0.54 1/0.95',"
    "colorbalance=rs=0.055:gs=0.02:bs=-0.03:rm=0.065:gm=0.022:bm=-0.035:rh=0.035:gh=0.014:bh=-0.018,"
    "split[base][glow];[glow]gblur=sigma=16[g];"
    "[base][g]blend=all_mode=screen:all_opacity=0.20,"
    "unsharp=5:5:0.22:5:5:0.0,"
    "vignette=PI/4.8"
)

WIDE = (
    "format=yuv420p,"
    "hqdn3d=2.8:1.6:3.8:2.2,"
    "eq=contrast=0.85:brightness=0.04:saturation=0.76:gamma=1.06,"
    "curves=all='0/0.06 0.5/0.55 1/0.98',"
    "colorbalance=rs=0.03:gs=0.012:bs=-0.018:rm=0.035:gm=0.014:bm=-0.02,"
    "split[base][glow];[glow]gblur=sigma=11[g];"
    "[base][g]blend=all_mode=screen:all_opacity=0.13,"
    "unsharp=5:5:0.24:5:5:0.0"
)


def run(cmd: list[str]) -> None:
    print("+", " ".join(str(c) for c in cmd[:12]), "...")
    subprocess.run(cmd, check=True)


def probe(path: Path) -> float:
    return float(subprocess.check_output(
        [FP, "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        text=True,
    ).strip())


def motion_crop(kind: str, out_dur: float, crop_y_bias: str) -> str:
    """Animated crop after overscale — Ken Burns feel."""
    # bias is expression fragment for vertical preference, e.g. (ih-oh)/2+60
    comma = r"\,"
    if kind == "push_in":
        y_anim = (
            f"(ih-oh)/2 - (t/{out_dur:.3f})*min(ih*0.05{comma}120)"
        )
        y = crop_y_bias.replace("(ih-oh)/2", y_anim)
        return (
            f"scale={int(W*1.16)}:{int(H*1.16)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2':y='{y}'"
        )
    if kind == "pull_out":
        y_anim = (
            f"(ih-oh)/2 + (t/{out_dur:.3f})*min(ih*0.035{comma}90)"
        )
        y = crop_y_bias.replace("(ih-oh)/2", y_anim)
        return (
            f"scale={int(W*1.18)}:{int(H*1.18)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2':y='{y}'"
        )
    if kind == "drift_r":
        return (
            f"scale={int(W*1.14)}:{int(H*1.14)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:"
            f"x='(iw-ow)/2 + (t/{out_dur:.3f})*min(iw*0.03{comma}70)':"
            f"y='{crop_y_bias}'"
        )
    if kind == "rise":
        y_anim = (
            f"(ih-oh)/2 - (t/{out_dur:.3f})*min(ih*0.04{comma}100)"
        )
        y = crop_y_bias.replace("(ih-oh)/2", y_anim)
        return (
            f"scale={int(W*1.15)}:{int(H*1.15)}:force_original_aspect_ratio=increase:flags=lanczos,"
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
    beauty: bool = False,
    fade_in: float = 0.0,
    fade_out: float = 0.0,
    crop_y: str = "(ih-oh)/2",
    motion: str = "push_in",
) -> float:
    out_dur = duration / speed
    grade = BEAUTY if beauty else WIDE
    crop = motion_crop(motion, out_dur, crop_y)
    vf = f"deshake=rx=16:ry=16,setpts=PTS/{speed},{crop},{grade}"
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


def render_still_freeze(src_clip: Path, dst: Path, *, at: float = 2.0, hold: float = 0.45) -> float:
    """Creative beat: freeze the perfect still on his phone, soft pulse."""
    frame = WORK / "still_frame.png"
    run([FF, "-y", "-ss", f"{at:.2f}", "-i", str(src_clip), "-frames:v", "1", str(frame)])
    # hold with micro zoom + vignette
    run([
        FF, "-y", "-loop", "1", "-i", str(frame),
        "-vf",
        f"scale={W}:{H},"
        f"zoompan=z='min(1.06,1+0.03*on/{max(1, int(hold*FPS))})':"
        f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s={W}x{H}:fps={FPS},"
        "format=yuv420p,vignette=PI/4.2,"
        "eq=contrast=0.9:brightness=0.03:saturation=0.8",
        "-t", f"{hold:.3f}",
        "-c:v", "h264_videotoolbox", "-b:v", "48M", "-pix_fmt", "yuv420p",
        str(dst),
    ])
    return probe(dst)


def assemble_with_xfades(clips: list[Path], durs: list[float], dst: Path, xfade: float = 0.6) -> float:
    inputs: list[str] = []
    for c in clips:
        inputs += ["-i", str(c)]

    if len(clips) == 1:
        run(["cp", str(clips[0]), str(dst)])
        return durs[0]

    # Soft cinematic transitions — mostly fade, one smoothleft into harbor (world opens)
    transitions = ["fade"] * (len(clips) - 1)
    # index before harbor (shot 5 is index 4) → transition into it from face
    if len(transitions) >= 4:
        transitions[3] = "fade"  # soft open into the world
    if len(transitions) >= 6:
        transitions[5] = "fade"  # into phone

    parts = []
    offset = durs[0] - xfade
    parts.append(
        f"[0:v][1:v]xfade=transition={transitions[0]}:duration={xfade}:offset={offset:.3f}[v01]"
    )
    prev = "v01"
    acc = durs[0] + durs[1] - xfade
    for i in range(2, len(clips)):
        offset = acc - xfade
        out = "vout" if i == len(clips) - 1 else f"v{i:02d}"
        parts.append(
            f"[{prev}][{i}:v]xfade=transition={transitions[i-1]}:duration={xfade}:offset={offset:.3f}[{out}]"
        )
        prev = out
        acc = acc + durs[i] - xfade

    fc = ";".join(parts)
    total = sum(durs) - xfade * (len(clips) - 1)
    run([
        FF, "-y", *inputs,
        "-filter_complex", fc,
        "-map", "[vout]",
        "-c:v", "h264_videotoolbox", "-b:v", "48M",
        "-pix_fmt", "yuv420p",
        "-t", f"{total:.3f}",
        str(dst),
    ])
    return probe(dst)


def render_end_brand(base: Path, dst: Path) -> float:
    """Animated StillScout mark + wordmark for brand exposure + VO room."""
    dur = probe(base)
    logo = MARK if MARK.exists() else ROOT / "assets" / "stillscout_mark.png"
    # Logo floats up + fades; wordmark; tagline; soft gold line via drawbox timed
    fc = (
        f"[0:v]format=yuv420p,"
        f"drawbox=x=0:y=0:w=iw:h=ih:color=black@0.0:t=fill,"
        # progressive dark veil for brand stage
        f"drawbox=x=0:y=ih*0.55:w=iw:h=ih*0.45:color=black@0.42:t=fill:enable='gte(t,0.4)',"
        f"drawbox=x=0:y=0:w=iw:h=ih:color=black@0.18:t=fill:enable='gte(t,0.8)'[bg];"
        # logo: fade in + float upward
        f"[1:v]format=rgba,scale=780:780,"
        f"fade=t=in:st=0:d=1.1:alpha=1,"
        f"fade=t=out:st={dur-1.4:.2f}:d=1.2:alpha=1[lg];"
        f"[bg][lg]overlay="
        f"x='(W-w)/2':"
        f"y='H*0.22-h/2 + 50*(1-min(1\\,max(0\\,(t-0.5)/1.3)))':"
        f"format=auto:eof_action=pass[v1];"
        # wordmark
        f"[v1]"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Didot.ttc:"
        f"text='StillScout':fontsize=138:fontcolor=0xFFFAF5@0.0:"
        f"x=(w-text_w)/2:y=h*0.52:"
        f"alpha='if(lt(t,1.8),0,if(lt(t,3.0),(t-1.8)/1.2,if(gt(t,{dur-1.3:.2f}),"
        f"({dur:.2f}-t)/1.3,0.96)))',"
        # tagline — VO cue line
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Georgia.ttf:"
        f"text='Scout the perfect still.':fontsize=56:fontcolor=0xFFF8F0@0.0:"
        f"x=(w-text_w)/2:y=h*0.52+150:"
        f"alpha='if(lt(t,2.6),0,if(lt(t,3.6),(t-2.6)/1.0,if(gt(t,{dur-1.2:.2f}),"
        f"({dur:.2f}-t)/1.2,0.90)))',"
        # thin gold accent line under mark
        f"drawbox=x=(iw-420)/2:y=ih*0.48:w=420:h=3:color=0xD4B88C@0.85:t=fill:"
        f"enable='between(t,1.5,{dur-1.2:.2f})',"
        f"fade=t=out:st={dur-1.35:.2f}:d=1.35[vout]"
    )
    run([
        FF, "-y",
        "-i", str(base),
        "-loop", "1", "-i", str(logo),
        "-filter_complex", fc,
        "-map", "[vout]",
        "-t", f"{dur:.3f}",
        "-c:v", "h264_videotoolbox", "-b:v", "48M", "-pix_fmt", "yuv420p",
        str(dst),
    ])
    return probe(dst)


def mix_audio(total: float, marks: dict[str, float], dst: Path) -> None:
    """Picture-locked Foley + peaceful piano; duck hard for VO at brand end."""
    def ms(sec: float) -> int:
        return max(0, int(sec * 1000))

    piano = AUDIO_V3 / "km_peaceful.mp3"
    if not piano.exists() or piano.stat().st_size < 5000:
        piano = AUDIO / "piano.mp3"

    ocean = AUDIO / "ocean.mp3"
    wind = AUDIO / "wind.mp3"
    gulls = AUDIO / "seagulls.mp3"
    loc = AUDIO / "loc.wav"
    writing = AUDIO / "writing_1.mp3"
    pen = AUDIO / "pen_on_paper.mp3"
    pen2 = AUDIO / "pencil_scribble.mp3"
    pen3 = AUDIO / "pen_write.mp3"
    book = AUDIO / "book_open.mp3"
    page = AUDIO / "page_turn_soft.mp3"
    page2 = AUDIO / "page_flip_2.mp3"
    fabric = AUDIO / "fabric_2.mp3"
    clothes = AUDIO / "clothes_rustle.mp3"
    whoosh = AUDIO / "soft_whoosh.mp3"

    t_hands = marks["hands"]
    t_profile = marks["profile"]
    t_face = marks["face"]
    t_harbor = marks["harbor"]
    t_sky = marks["sky"]
    t_phone = marks["phone"]
    t_still = marks.get("still", t_phone + 3.0)
    t_end = marks["end"]
    vo_duck = max(0.5, total - 7.2)  # leave room for narration

    # Scribble spans hands → mid face
    scribble_len = max(2.0, t_harbor - t_hands - 0.4)

    fc = (
        # beds
        f"[0:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=70,lowpass=f=9000,volume=0.40,"
        f"afade=t=in:st=0:d=2,afade=t=out:st={total-2.8}:d=2.8[ocean];"
        f"[1:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=200,lowpass=f=3400,volume=0.10,afade=t=in:st=0:d=2[wind];"
        f"[2:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"volume=0.09,highpass=f=900,lowpass=f=5500,"
        f"afade=t=in:st={t_harbor:.2f}:d=2.2,afade=t=out:st={vo_duck:.2f}:d=2.5[gulls];"
        f"[3:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=140,lowpass=f=4500,volume=0.09,afade=t=in:st=0:d=1.5[loc];"
        # piano — peaceful, ducks early for VO pocket
        f"[4:a]adelay={ms(1.5)}|{ms(1.5)},atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=90,lowpass=f=5400,"
        f"acompressor=threshold=-24dB:ratio=2.6:attack=70:release=380,"
        f"volume=0.30,afade=t=in:st=0:d=3.5,"
        f"afade=t=out:st={vo_duck:.2f}:d=2.5[piano];"
        # scribble bed — only while writing
        f"[5:a]aloop=loop=-1:size=2e+09,atrim=0:{scribble_len:.2f},asetpts=N/SR/TB,"
        f"adelay={ms(t_hands + 0.15)}|{ms(t_hands + 0.15)},"
        f"highpass=f=900,lowpass=f=9500,volume=0.72,"
        f"afade=t=in:st=0:d=0.25,afade=t=out:st={scribble_len-0.7:.2f}:d=0.7,"
        f"atrim=0:{total},asetpts=N/SR/TB[scribble];"
        # pen accents locked to writing beats
        f"[6:a]adelay={ms(t_hands + 0.9)}|{ms(t_hands + 0.9)},volume=0.75,highpass=f=1100,atrim=0:{total},asetpts=N/SR/TB[pen1];"
        f"[7:a]adelay={ms(t_profile + 0.5)}|{ms(t_profile + 0.5)},volume=0.58,highpass=f=1200,atrim=0:{total},asetpts=N/SR/TB[pen2];"
        f"[8:a]adelay={ms(t_profile + 2.2)}|{ms(t_profile + 2.2)},volume=0.55,highpass=f=1000,atrim=0:{total},asetpts=N/SR/TB[pen3];"
        f"[6:a]adelay={ms(t_face + 0.7)}|{ms(t_face + 0.7)},volume=0.40,highpass=f=1100,atrim=0:{total},asetpts=N/SR/TB[pen4];"
        # pages
        f"[9:a]adelay={ms(0.25)}|{ms(0.25)},volume=0.78,atrim=0:{total},asetpts=N/SR/TB[book];"
        f"[10:a]adelay={ms(0.9)}|{ms(0.9)},volume=0.60,atrim=0:{total},asetpts=N/SR/TB[page1];"
        f"[11:a]adelay={ms(t_end + 0.35)}|{ms(t_end + 0.35)},volume=0.55,atrim=0:{total},asetpts=N/SR/TB[page2];"
        f"[10:a]adelay={ms(t_end + 1.6)}|{ms(t_end + 1.6)},volume=0.40,atrim=0:{total},asetpts=N/SR/TB[page3];"
        # fabric / whoosh / still click
        f"[12:a]adelay={ms(t_profile + 0.15)}|{ms(t_profile + 0.15)},volume=0.34,atrim=0:{total},asetpts=N/SR/TB[fab1];"
        f"[13:a]adelay={ms(t_phone + 0.2)}|{ms(t_phone + 0.2)},volume=0.40,atrim=0:{total},asetpts=N/SR/TB[fab2];"
        f"[14:a]adelay={ms(t_harbor - 0.05)}|{ms(t_harbor - 0.05)},volume=0.32,lowpass=f=4200,atrim=0:{total},asetpts=N/SR/TB[whoosh1];"
        f"[14:a]adelay={ms(t_still)}|{ms(t_still)},volume=0.18,lowpass=f=3000,atrim=0:{total},asetpts=N/SR/TB[whoosh2];"
        # soft brand whoosh when logo lands
        f"[14:a]adelay={ms(t_end + 0.9)}|{ms(t_end + 0.9)},volume=0.22,lowpass=f=2800,atrim=0:{total},asetpts=N/SR/TB[whoosh3];"
        # mix + VO pocket (dip beds under brand)
        f"[ocean][wind][gulls][loc][piano][scribble][pen1][pen2][pen3][pen4]"
        f"[book][page1][page2][page3][fab1][fab2][whoosh1][whoosh2][whoosh3]"
        f"amix=inputs=19:normalize=0:dropout_transition=2,"
        f"equalizer=f=220:t=q:w=1:g=-2,"
        f"equalizer=f=3800:t=q:w=1:g=1.8,"
        f"equalizer=f=6500:t=q:w=1:g=1.0,"
        # final duck for narration — keep soft ocean only
        f"volume=0.22:enable='gte(t,{vo_duck:.2f})',"
        f"alimiter=limit=0.88,loudnorm=I=-16:TP=-1.5:LRA=10[aout]"
    )

    inputs = [
        ocean, wind, gulls, loc if loc.exists() else ocean, piano,
        writing, pen, pen2, pen3, book, page, page2, fabric, clothes, whoosh,
    ]
    cmd = [FF, "-y"]
    for p in inputs:
        cmd += ["-i", str(p)]
    cmd += [
        "-filter_complex", fc,
        "-map", "[aout]", "-t", str(total),
        "-c:a", "aac", "-b:a", "320k",
        str(dst),
    ]
    run(cmd)


def main() -> int:
    clips = WORK / "clips"
    clips.mkdir(parents=True, exist_ok=True)
    EXPORT.mkdir(parents=True, exist_ok=True)

    plan: list[tuple[Path, float, str]] = []

    # 1 notebook — mystery open
    d = render("MVI_0387.MP4", clips / "01_pages.mp4",
               start=0.7, duration=3.1, speed=0.88, beauty=True, fade_in=1.0,
               crop_y="(ih-oh)/2-60", motion="push_in")
    plan.append((clips / "01_pages.mp4", d, "notebook"))

    # 2 hands writing — scribble hero
    d = render("MVI_0356.MP4", clips / "02_hands.mp4",
               start=5.5, duration=3.9, speed=0.78, beauty=True,
               crop_y="(ih-oh)/2", motion="drift_r")
    plan.append((clips / "02_hands.mp4", d, "hands"))

    # 3 most handsome profile — linger
    d = render("MVI_0358.MP4", clips / "03_profile.mp4",
               start=2.8, duration=4.9, speed=0.84, beauty=True,
               crop_y="(ih-oh)/2+50", motion="rise")
    plan.append((clips / "03_profile.mp4", d, "profile"))

    # 4 soft face + ocean bokeh
    d = render("MVI_0353.MP4", clips / "04_face.mp4",
               start=16.5, duration=4.1, speed=0.82, beauty=True,
               crop_y="(ih-oh)/2+230", motion="rise")
    plan.append((clips / "04_face.mp4", d, "face"))

    # 5 world opens
    d = render("MVI_0343.MP4", clips / "05_harbor.mp4",
               start=1.0, duration=4.0, speed=0.90,
               crop_y="(ih-oh)/2+70", motion="pull_out")
    plan.append((clips / "05_harbor.mp4", d, "harbor"))

    # 6 sky breath
    d = render("MVI_0365.MP4", clips / "06_sky.mp4",
               start=9.0, duration=3.7, speed=0.86,
               crop_y="(ih-oh)/2", motion="push_in")
    plan.append((clips / "06_sky.mp4", d, "sky"))

    # 7 phone raise
    d = render("MVI_0363.MP4", clips / "07_raise.mp4",
               start=9.5, duration=3.7, speed=0.88,
               crop_y="(ih-oh)/2+80", motion="rise")
    plan.append((clips / "07_raise.mp4", d, "phone"))

    # 8 OTS screen + creative perfect-still freeze
    screen = clips / "08_screen_live.mp4"
    d_live = render("MVI_0378.MP4", screen,
                    start=3.8, duration=3.0, speed=0.90, beauty=True,
                    crop_y="(ih-oh)/2", motion="push_in")
    freeze = clips / "08b_still.mp4"
    d_fr = render_still_freeze(screen, freeze, at=min(2.2, d_live - 0.3), hold=0.48)
    # concat live+freeze into one shot
    screen_full = clips / "08_screen.mp4"
    lst = WORK / "screen_concat.txt"
    lst.write_text(f"file '{screen}'\nfile '{freeze}'\n")
    run([FF, "-y", "-f", "concat", "-safe", "0", "-i", str(lst), "-c", "copy", str(screen_full)])
    plan.append((screen_full, probe(screen_full), "screen"))

    # 9 rest
    d = render("MVI_0359.MP4", clips / "09_rest.mp4",
               start=5.5, duration=3.0, speed=0.88, beauty=True,
               crop_y="(ih-oh)/2+90", motion="rise")
    plan.append((clips / "09_rest.mp4", d, "rest"))

    # 10 end notebook base → animated brand
    end_base = clips / "10_end_base.mp4"
    render("MVI_0387.MP4", end_base,
           start=2.8, duration=6.4, speed=0.90, beauty=True, fade_in=0.35,
           crop_y="(ih-oh)/2-40", motion="push_in")
    end = clips / "10_end.mp4"
    d = render_end_brand(end_base, end)
    plan.append((end, d, "end"))

    # marks (pre-xfade cumulative — Foley sync approx; refine after xfade)
    marks_raw: dict[str, float] = {}
    cum = 0.0
    for path, dur, name in plan:
        marks_raw[name] = cum
        print(f"  {path.name}: {dur:.2f}s  @{cum:.2f}")
        cum += dur

    paths = [p for p, _, _ in plan]
    durs = [d for _, d, _ in plan]
    xfade = 0.58
    picture = WORK / "picture.mp4"
    total = assemble_with_xfades(paths, durs, picture, xfade=xfade)
    print("Picture:", total)

    # Adjust marks for xfade chain: each subsequent start shifts earlier by xfade * index
    marks: dict[str, float] = {}
    for i, (_, _, name) in enumerate(plan):
        marks[name] = max(0.0, marks_raw[name] - xfade * i)
    marks["still"] = marks["screen"] + durs[7] - 0.48  # freeze near end of screen block
    print("Marks:", {k: round(v, 2) for k, v in marks.items()})

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
        "-movflags", "+faststart", "-shortest",
        str(master),
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
        "title": "StillScout — Before the Capture (v6)",
        "based_on": "v4 liked ~41s cut",
        "duration_sec": probe(master),
        "creative": [
            "Ken Burns micro-motion",
            "soft light-leak into harbor",
            "perfect-still freeze on phone screen",
            "animated StillScout mark + wordmark end",
            "VO pocket for: StillScout, scout the perfect still",
        ],
        "voiceover_window_sec": [round(total - 7.2, 2), round(total - 0.8, 2)],
        "master": str(master),
        "social": str(social),
    }
    (EXPORT / "manifest_v6.json").write_text(json.dumps(meta, indent=2))
    (EXPORT / "AUDIO_CREDITS_v6.txt").write_text(
        "Music: Peaceful Desolation — Kevin MacLeod (incompetech.com) CC BY 4.0\n"
        "Foley: Mixkit pen/pencil writing, page turns, fabric, whoosh\n"
        "Ambience: Mixkit ocean / wind / seagulls + location air\n"
        "VO: record in the final ~7s duck window — "
        "'StillScout, scout the perfect still.'\n"
    )
    (EXPORT / "NARRATION_CUE_v6.txt").write_text(
        f"Speak starting around {total - 6.5:.1f}s (logo + wordmark visible):\n"
        "  StillScout… scout the perfect still.\n"
        f"Hold soft until fade at {total:.1f}s.\n"
    )
    print(json.dumps(meta, indent=2))
    print("DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
