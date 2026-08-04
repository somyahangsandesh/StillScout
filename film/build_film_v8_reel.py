#!/usr/bin/env python3
"""StillScout v8 — movie-like Reel cut.

Review fixes:
- Punchier pacing / shorter dissolves
- Cinematic warm grade (clear face, not washed)
- Drop weak long OTS hair shot → better screen still
- Clean end brand on soft dark (no scribble notebook under logo)
- No music / no location voice — Foley + ocean only (VO-ready)
- Player-safe libx264 export
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
WORK = ROOT / "work_v8"
EXPORT = ROOT / "export"
AUDIO = ROOT / "audio" / "src_v5"
MARK = ROOT / "assets" / "stillscout_mark_light.png"
W, H, FPS = 2160, 3840, 30

# Cinematic reel grade — contrast + warmth + micro grain, soft skin, sharp eyes
FACE = (
    "format=yuv420p,"
    "hqdn3d=2.2:1.4:3:2,"
    "bilateral=sigmaS=2.4:sigmaR=0.08,"
    "eq=contrast=0.98:brightness=0.028:saturation=0.90:gamma=1.03,"
    "curves="
    "red='0/0.04 0.28/0.33 0.55/0.61 1/0.995':"
    "green='0/0.04 0.28/0.32 0.55/0.57 1/0.98':"
    "blue='0/0.05 0.28/0.30 0.55/0.53 1/0.955',"
    "colorbalance=rs=0.045:gs=0.012:bs=-0.025:rm=0.055:gm=0.015:bm=-0.03:rh=0.025:gh=0.01:bh=-0.015,"
    "split[base][glow];[glow]gblur=sigma=7[g];"
    "[base][g]blend=all_mode=screen:all_opacity=0.08,"
    "unsharp=5:5:0.6:5:5:0.2,"
    "vignette=PI/5,"
    "noise=alls=3:allf=t"
)

DETAIL = (
    "format=yuv420p,"
    "hqdn3d=1.8:1.2:2.5:1.8,"
    "eq=contrast=1.02:brightness=0.03:saturation=0.95:gamma=1.02,"
    "curves=all='0/0.03 0.5/0.54 1/0.99',"
    "colorbalance=rs=0.03:gs=0.01:bs=-0.018:rm=0.04:gm=0.012:bm=-0.02,"
    "unsharp=5:5:0.5:5:5:0.15,"
    "vignette=PI/5.5,"
    "noise=alls=2:allf=t"
)

WIDE = (
    "format=yuv420p,"
    "hqdn3d=1.5:1:2:1.5,"
    "eq=contrast=1.04:brightness=0.02:saturation=0.98:gamma=1.01,"
    "curves=all='0/0.02 0.5/0.52 1/0.985',"
    "colorbalance=rs=0.02:gs=0.008:bs=-0.015:rm=0.03:gm=0.01:bm=-0.018,"
    "unsharp=5:5:0.45:5:5:0.12,"
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


def motion_crop(kind: str, out_dur: float, crop_y: str) -> str:
    comma = r"\,"
    if kind == "push":
        y = crop_y.replace("(ih-oh)/2", f"(ih-oh)/2-(t/{out_dur:.3f})*min(ih*0.03{comma}70)")
        return (
            f"scale={int(W*1.10)}:{int(H*1.10)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2':y='{y}'"
        )
    if kind == "pull":
        y = crop_y.replace("(ih-oh)/2", f"(ih-oh)/2+(t/{out_dur:.3f})*min(ih*0.025{comma}55)")
        return (
            f"scale={int(W*1.12)}:{int(H*1.12)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2':y='{y}'"
        )
    if kind == "rise":
        y = crop_y.replace("(ih-oh)/2", f"(ih-oh)/2-(t/{out_dur:.3f})*min(ih*0.028{comma}65)")
        return (
            f"scale={int(W*1.10)}:{int(H*1.10)}:force_original_aspect_ratio=increase:flags=lanczos,"
            f"crop={W}:{H}:x='(iw-ow)/2':y='{y}'"
        )
    return (
        f"scale={W}:{H}:force_original_aspect_ratio=increase:flags=lanczos,"
        f"crop={W}:{H}:(iw-ow)/2:{crop_y}"
    )


def render(
    src: str, dst: Path, *, start: float, duration: float, speed: float = 1.0,
    grade: str = "detail", fade_in: float = 0.0, fade_out: float = 0.0,
    crop_y: str = "(ih-oh)/2", motion: str = "push",
) -> float:
    out_dur = duration / speed
    g = {"face": FACE, "detail": DETAIL, "wide": WIDE}[grade]
    vf = f"deshake=rx=16:ry=16,setpts=PTS/{speed},{motion_crop(motion, out_dur, crop_y)},{g}"
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


def still_capture(src_clip: Path, dst: Path, *, at: float, hold: float = 0.6) -> float:
    frame = WORK / "capture.png"
    run([FF, "-y", "-ss", f"{at:.2f}", "-i", str(src_clip), "-frames:v", "1", "-update", "1", str(frame)])
    run([
        FF, "-y", "-loop", "1", "-i", str(frame),
        "-vf",
        f"scale={W}:{H},"
        f"zoompan=z='min(1.04,1+0.02*on/{max(1,int(hold*FPS))})':"
        f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s={W}x{H}:fps={FPS},"
        "format=yuv420p,eq=contrast=1.05:brightness=0.02:saturation=0.95,"
        "vignette=PI/4.8,fade=t=in:st=0:d=0.08:color=white",
        "-t", f"{hold:.3f}",
        "-c:v", "h264_videotoolbox", "-b:v", "50M", "-pix_fmt", "yuv420p",
        str(dst),
    ])
    return probe(dst)


def assemble(clips: list[Path], durs: list[float], dst: Path, xfade: float = 0.32) -> float:
    inputs: list[str] = []
    for c in clips:
        inputs += ["-i", str(c)]
    parts = []
    offset = durs[0] - xfade
    parts.append(f"[0:v][1:v]xfade=transition=fade:duration={xfade}:offset={offset:.3f}[v01]")
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
        "-map", "[vout]", "-c:v", "h264_videotoolbox", "-b:v", "50M",
        "-pix_fmt", "yuv420p", "-t", f"{total:.3f}", str(dst),
    ])
    return probe(dst)


def sky_whisper(video: Path, dst: Path, sky_t: float) -> float:
    s, e = sky_t + 0.4, sky_t + 2.6
    vf = (
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Didot.ttc:"
        f"text='StillScout':fontsize=86:fontcolor=white@0.0:"
        f"x=(w-text_w)/2:y=h*0.16:"
        f"alpha='if(lt(t,{s:.2f}),0,if(lt(t,{s+0.6:.2f}),(t-{s:.2f})/0.6,"
        f"if(lt(t,{e-0.5:.2f}),0.55,if(lt(t,{e:.2f}),({e:.2f}-t)/0.5*0.55,0))))'"
    )
    run([
        FF, "-y", "-i", str(video), "-vf", vf,
        "-c:v", "h264_videotoolbox", "-b:v", "50M", "-pix_fmt", "yuv420p", "-an", str(dst),
    ])
    return probe(dst)


def end_brand_plate(dst: Path, dur: float = 6.8) -> float:
    """Movie end card: soft charcoal plate + animated mark + wordmark. No notebook scribbles."""
    logo = MARK if MARK.exists() else ROOT / "assets" / "stillscout_mark.png"
    comma = r"\,"
    fc = (
        f"color=c=0x0C0B0A:s={W}x{H}:d={dur}:r={FPS},format=yuv420p,"
        f"vignette=PI/3.5[bg];"
        f"[0:v]format=rgba,scale=780:780,"
        f"fade=t=in:st=0:d=0.9:alpha=1,"
        f"fade=t=out:st={dur-1.5:.2f}:d=1.3:alpha=1[lg];"
        f"[bg][lg]overlay="
        f"x='(W-w)/2':"
        f"y='H*0.30-h/2+36*(1-min(1{comma}max(0{comma}(t-0.55)/1.1)))':"
        f"format=auto[v1];"
        f"[v1]"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Didot.ttc:"
        f"text='StillScout':fontsize=146:fontcolor=0xFFFAF5@0.0:"
        f"x=(w-text_w)/2:y=h*0.58:"
        f"alpha='if(lt(t,1.5),0,if(lt(t,2.5),(t-1.5)/1.0,if(gt(t,{dur-1.4:.2f}),"
        f"({dur:.2f}-t)/1.4,0.98)))',"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Georgia.ttf:"
        f"text='Scout the perfect still.':fontsize=58:fontcolor=0xF2E8DA@0.0:"
        f"x=(w-text_w)/2:y=h*0.58+160:"
        f"alpha='if(lt(t,2.3),0,if(lt(t,3.2),(t-2.3)/0.9,if(gt(t,{dur-1.3:.2f}),"
        f"({dur:.2f}-t)/1.3,0.92)))',"
        f"drawbox=x=(iw-340)/2:y=ih*0.545:w=340:h=2:color=0xD4B88C@0.92:t=fill:"
        f"enable='between(t,1.4,{dur-1.3:.2f})',"
        f"fade=t=in:st=0:d=0.5,fade=t=out:st={dur-1.35:.2f}:d=1.35[vout]"
    )
    run([
        FF, "-y", "-loop", "1", "-i", str(logo),
        "-filter_complex", fc, "-map", "[vout]",
        "-t", f"{dur:.3f}",
        "-c:v", "h264_videotoolbox", "-b:v", "40M", "-pix_fmt", "yuv420p",
        str(dst),
    ])
    return probe(dst)


def mix_audio(total: float, marks: dict[str, float], dst: Path) -> None:
    def ms(s: float) -> int:
        return max(0, int(s * 1000))

    t_hands, t_profile = marks["hands"], marks["profile"]
    t_face, t_harbor = marks["face"], marks["harbor"]
    t_phone, t_still = marks["phone"], marks["still"]
    t_end = marks["end"]
    scribble_len = max(2.2, t_harbor - t_hands - 0.25)

    fc = (
        f"[0:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=70,lowpass=f=9000,volume=0.36,"
        f"afade=t=in:st=0:d=1.4,afade=t=out:st={total-2.2}:d=2.2[ocean];"
        f"[1:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=200,lowpass=f=3400,volume=0.08,afade=t=in:st=0:d=1.6[wind];"
        f"[2:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"volume=0.07,highpass=f=900,lowpass=f=5500,"
        f"afade=t=in:st={t_harbor:.2f}:d=1.8,afade=t=out:st={t_end:.2f}:d=2[gulls];"
        f"[3:a]aloop=loop=-1:size=2e+09,atrim=0:{scribble_len:.2f},asetpts=N/SR/TB,"
        f"adelay={ms(t_hands)}|{ms(t_hands)},highpass=f=750,lowpass=f=10000,volume=0.88,"
        f"afade=t=in:st=0:d=0.18,afade=t=out:st={scribble_len-0.5:.2f}:d=0.5,"
        f"atrim=0:{total},asetpts=N/SR/TB[scribble];"
        f"[4:a]adelay={ms(t_hands+0.65)}|{ms(t_hands+0.65)},volume=0.88,highpass=f=1000,atrim=0:{total},asetpts=N/SR/TB[pen1];"
        f"[5:a]adelay={ms(t_profile+0.35)}|{ms(t_profile+0.35)},volume=0.72,highpass=f=1100,atrim=0:{total},asetpts=N/SR/TB[pen2];"
        f"[6:a]adelay={ms(t_profile+1.9)}|{ms(t_profile+1.9)},volume=0.65,highpass=f=1000,atrim=0:{total},asetpts=N/SR/TB[pen3];"
        f"[4:a]adelay={ms(t_face+0.45)}|{ms(t_face+0.45)},volume=0.42,highpass=f=1000,atrim=0:{total},asetpts=N/SR/TB[pen4];"
        f"[7:a]adelay={ms(0.18)}|{ms(0.18)},volume=0.82,atrim=0:{total},asetpts=N/SR/TB[book];"
        f"[8:a]adelay={ms(0.7)}|{ms(0.7)},volume=0.70,atrim=0:{total},asetpts=N/SR/TB[page1];"
        f"[10:a]adelay={ms(t_profile)}|{ms(t_profile)},volume=0.30,atrim=0:{total},asetpts=N/SR/TB[fab1];"
        f"[11:a]adelay={ms(t_phone+0.1)}|{ms(t_phone+0.1)},volume=0.38,atrim=0:{total},asetpts=N/SR/TB[fab2];"
        f"[12:a]adelay={ms(t_harbor)}|{ms(t_harbor)},volume=0.30,lowpass=f=4000,atrim=0:{total},asetpts=N/SR/TB[whoosh1];"
        f"[12:a]adelay={ms(t_still)}|{ms(t_still)},volume=0.26,lowpass=f=3200,atrim=0:{total},asetpts=N/SR/TB[shutter];"
        f"[12:a]adelay={ms(t_end+0.4)}|{ms(t_end+0.4)},volume=0.22,lowpass=f=2600,atrim=0:{total},asetpts=N/SR/TB[whoosh3];"
        # Soft beds under brand for VO
        f"[ocean][wind][gulls][scribble][pen1][pen2][pen3][pen4]"
        f"[book][page1][fab1][fab2][whoosh1][shutter][whoosh3]"
        f"amix=inputs=15:normalize=0:dropout_transition=2,"
        f"equalizer=f=3500:t=q:w=1:g=1.4,"
        f"volume='if(lt(t,{t_end:.2f}),1.0,0.32)',"
        f"alimiter=limit=0.90,loudnorm=I=-18:TP=-2.0:LRA=9[aout]"
    )
    inputs = [
        AUDIO / "ocean.mp3", AUDIO / "wind.mp3", AUDIO / "seagulls.mp3",
        AUDIO / "writing_1.mp3", AUDIO / "pen_on_paper.mp3",
        AUDIO / "pencil_scribble.mp3", AUDIO / "pen_write.mp3",
        AUDIO / "book_open.mp3", AUDIO / "page_turn_soft.mp3",
        AUDIO / "page_flip_2.mp3",  # unused index kept for numbering? wait - remove unused
    ]
    # fix inputs to match filters - page_flip unused, fabric etc.
    inputs = [
        AUDIO / "ocean.mp3", AUDIO / "wind.mp3", AUDIO / "seagulls.mp3",
        AUDIO / "writing_1.mp3", AUDIO / "pen_on_paper.mp3",
        AUDIO / "pencil_scribble.mp3", AUDIO / "pen_write.mp3",
        AUDIO / "book_open.mp3", AUDIO / "page_turn_soft.mp3",
        AUDIO / "page_flip_2.mp3",  # index 9 unused in fc - remove from fc references
        AUDIO / "fabric_2.mp3", AUDIO / "clothes_rustle.mp3", AUDIO / "soft_whoosh.mp3",
    ]
    # Remap: 9 was page_flip unused - fab is 10, clothes 11, whoosh 12. Good as written.
    cmd = [FF, "-y"]
    for p in inputs:
        cmd += ["-i", str(p)]
    cmd += ["-filter_complex", fc, "-map", "[aout]", "-t", str(total),
            "-c:a", "aac", "-b:a", "320k", str(dst)]
    run(cmd)


def export_player_safe(src: Path, dst: Path) -> None:
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
        str(dst),
    ])


def main() -> int:
    clips = WORK / "clips"
    clips.mkdir(parents=True, exist_ok=True)
    EXPORT.mkdir(parents=True, exist_ok=True)

    plan: list[tuple[Path, float, str]] = []

    # 1 Hook — silhouette gaze (movie cold open)
    d = render("MVI_0350.MP4", clips / "01_hook.mp4",
               start=8.5, duration=2.4, speed=0.90, grade="wide", fade_in=0.7,
               crop_y="(ih-oh)/2+100", motion="rise")
    plan.append((clips / "01_hook.mp4", d, "hook"))

    # 2 Notebook
    d = render("MVI_0387.MP4", clips / "02_pages.mp4",
               start=0.9, duration=2.6, speed=0.92, grade="detail",
               crop_y="(ih-oh)/2-40", motion="push")
    plan.append((clips / "02_pages.mp4", d, "notebook"))

    # 3 Hands scribble
    d = render("MVI_0356.MP4", clips / "03_hands.mp4",
               start=5.2, duration=3.2, speed=0.80, grade="detail",
               crop_y="(ih-oh)/2", motion="push")
    plan.append((clips / "03_hands.mp4", d, "hands"))

    # 4 Hero profile
    d = render("MVI_0358.MP4", clips / "04_profile.mp4",
               start=2.4, duration=4.8, speed=0.86, grade="face",
               crop_y="(ih-oh)/2+30", motion="rise")
    plan.append((clips / "04_profile.mp4", d, "profile"))

    # 5 Hero face — tight
    d = render("MVI_0353.MP4", clips / "05_face.mp4",
               start=17.2, duration=3.4, speed=0.85, grade="face",
               crop_y="(ih-oh)/2+340", motion="rise")
    plan.append((clips / "05_face.mp4", d, "face"))

    # 6 World opens
    d = render("MVI_0343.MP4", clips / "06_harbor.mp4",
               start=1.0, duration=3.6, speed=0.92, grade="wide",
               crop_y="(ih-oh)/2+50", motion="pull")
    plan.append((clips / "06_harbor.mp4", d, "harbor"))

    # 7 Sky breath
    d = render("MVI_0365.MP4", clips / "07_sky.mp4",
               start=8.5, duration=3.2, speed=0.90, grade="wide",
               crop_y="(ih-oh)/2", motion="push")
    plan.append((clips / "07_sky.mp4", d, "sky"))

    # 8 Phone raise (keep short)
    d = render("MVI_0363.MP4", clips / "08_raise.mp4",
               start=9.5, duration=3.0, speed=0.92, grade="wide",
               crop_y="(ih-oh)/2+60", motion="rise")
    plan.append((clips / "08_raise.mp4", d, "phone"))

    # 9 Screen + capture still (use better framed OTS)
    screen = clips / "09_screen_live.mp4"
    d_live = render("MVI_0376.MP4", screen,
                    start=2.0, duration=2.4, speed=0.92, grade="detail",
                    crop_y="(ih-oh)/2+40", motion="push")
    # fallback if 0376 short/bad — check duration
    if d_live < 1.5:
        d_live = render("MVI_0378.MP4", screen,
                        start=3.5, duration=2.4, speed=0.92, grade="detail",
                        crop_y="(ih-oh)/2", motion="push")
    freeze = clips / "09b_still.mp4"
    still_capture(screen, freeze, at=min(1.6, max(0.4, d_live - 0.4)), hold=0.65)
    screen_full = clips / "09_screen.mp4"
    lst = WORK / "screen.txt"
    lst.write_text(f"file '{screen}'\nfile '{freeze}'\n")
    run([FF, "-y", "-f", "concat", "-safe", "0", "-i", str(lst), "-c", "copy", str(screen_full)])
    plan.append((screen_full, probe(screen_full), "screen"))

    # 10 Soft settle (short) then brand plate
    d = render("MVI_0359.MP4", clips / "10_rest.mp4",
               start=5.0, duration=2.2, speed=0.92, grade="face",
               crop_y="(ih-oh)/2+70", motion="rise")
    plan.append((clips / "10_rest.mp4", d, "rest"))

    end = clips / "11_brand.mp4"
    d = end_brand_plate(end, dur=6.6)
    plan.append((end, d, "end"))

    marks_raw: dict[str, float] = {}
    cum = 0.0
    for path, dur, name in plan:
        marks_raw[name] = cum
        print(f"  {path.name}: {dur:.2f}s @{cum:.2f}")
        cum += dur

    paths = [p for p, _, _ in plan]
    durs = [d for _, d, _ in plan]
    xfade = 0.32
    raw = WORK / "picture_raw.mp4"
    total = assemble(paths, durs, raw, xfade=xfade)
    marks = {n: max(0.0, marks_raw[n] - xfade * i) for i, (_, _, n) in enumerate(plan)}
    marks["still"] = marks["screen"] + durs[8] - 0.65
    # hands mark for Foley: after notebook in this plan
    print("Picture:", total, "Marks:", {k: round(v, 2) for k, v in marks.items()})

    pictured = WORK / "picture.mp4"
    sky_whisper(raw, pictured, marks["sky"])
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

    # Final player-safe outputs
    play = EXPORT / "StillScout_PLAY_ME_1080x1920.mp4"
    best = EXPORT / "StillScout_Best_1080x1920.mp4"
    social = EXPORT / "StillScout_BeforeTheCapture_1080x1920.mp4"
    vo_bed = EXPORT / "StillScout_VO_BED_1080x1920.mp4"
    master = EXPORT / "StillScout_BeforeTheCapture_4K_9x16.mp4"

    run(["cp", str(master4k), str(master)])
    export_player_safe(master4k, play)
    run(["cp", str(play), str(best)])
    run(["cp", str(play), str(social)])
    run(["cp", str(play), str(vo_bed)])

    err = subprocess.run(
        [FF, "-v", "error", "-i", str(play), "-f", "null", "-"],
        capture_output=True, text=True,
    )
    print("DECODE:", "CLEAN" if not err.stderr.strip() else err.stderr[:300])

    meta = {
        "title": "StillScout — Movie Reel (v8)",
        "duration_sec": probe(play),
        "review_prior": "7.5/10 — strong arc, weak end brand & phone OTS, pacing soft",
        "upgrades": [
            "cold-open silhouette hook",
            "punchier cuts / shorter dissolves",
            "cinematic warm grade + film grain",
            "better screen still + capture flash",
            "clean dark end brand plate (no notebook scribbles)",
            "no music / no location voice — VO ready",
            "player-safe x264",
        ],
        "vo_start_sec": round(marks["end"] + 1.5, 1),
        "play": str(play),
    }
    (EXPORT / "manifest_v8.json").write_text(json.dumps(meta, indent=2))
    (EXPORT / "REVIEW_v8.md").write_text(
        "# StillScout Reel Review → v8\n\n"
        "## Prior cut: **7.5 / 10**\n"
        "- Story strong, grade clearer than v6\n"
        "- End logo sat on messy notebook scribbles (not movie)\n"
        "- Phone OTS was mostly hair\n"
        "- Pacing a bit soft for Reels\n\n"
        "## v8 movie-Reel upgrades\n"
        "- Cold-open gaze hook\n"
        "- Hero face/profile linger, punchier middle\n"
        "- Clean charcoal brand plate + animated mark\n"
        "- Capture flash still\n"
        "- Foley only (VO bed)\n"
    )
    (EXPORT / "NARRATION_SCRIPT.md").write_text(
        "# StillScout — VO Script (v8 Movie Reel)\n\n"
        f"**Length:** ~{probe(play):.0f}s  \n"
        "**File:** `StillScout_PLAY_ME_1080x1920.mp4`\n\n"
        "## Full read\n\n"
        "| Time | Line |\n|------|------|\n"
        "| 0:03–0:08 | Some moments don’t ask to be posted. |\n"
        "| 0:08–0:14 | They ask to be noticed. |\n"
        "| 0:14–0:19 | Felt first… then found. |\n"
        "| 0:19–0:28 | So you wait. You look. |\n"
        "| 0:28–0:33 | You scout the perfect still. |\n"
        f"| {marks['end']+1.5:.0f}:00–end | **StillScout.** Scout the perfect still. |\n\n"
        "## Copy\n\n"
        "```\n"
        "Some moments don’t ask to be posted.\n"
        "They ask to be noticed.\n"
        "Felt first… then found.\n"
        "So you wait. You look.\n"
        "You scout the perfect still.\n\n"
        "StillScout.\n"
        "Scout the perfect still.\n"
        "```\n"
    )
    print(json.dumps(meta, indent=2))
    print("DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
