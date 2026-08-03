#!/usr/bin/env python3
"""StillScout v5 — best cut (~45s)
Beauty face grade + Foley (scribble, page turns, fabric) + StillScout branding.
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
WORK = ROOT / "work_v5"
EXPORT = ROOT / "export"
AUDIO = ROOT / "audio" / "src_v5"
W, H, FPS = 2160, 3840, 30

BEAUTY = (
    "format=yuv420p,"
    "hqdn3d=4:2.5:5:3,"
    "bilateral=sigmaS=4.2:sigmaR=0.14,"
    "eq=contrast=0.83:brightness=0.055:saturation=0.74:gamma=1.08,"
    "curves="
    "red='0/0.08 0.28/0.36 0.55/0.62 1/0.995':"
    "green='0/0.07 0.28/0.34 0.55/0.58 1/0.98':"
    "blue='0/0.09 0.28/0.33 0.55/0.55 1/0.955',"
    "colorbalance=rs=0.045:gs=0.018:bs=-0.025:rm=0.055:gm=0.02:bm=-0.03:rh=0.03:gh=0.012:bh=-0.015,"
    "split[base][glow];[glow]gblur=sigma=14[g];"
    "[base][g]blend=all_mode=screen:all_opacity=0.16,"
    "unsharp=5:5:0.28:5:5:0.0,"
    "vignette=PI/5"
)

WIDE = (
    "format=yuv420p,"
    "hqdn3d=2.5:1.5:3.5:2,"
    "eq=contrast=0.86:brightness=0.04:saturation=0.77:gamma=1.05,"
    "curves=all='0/0.06 0.5/0.55 1/0.975',"
    "colorbalance=rs=0.03:gs=0.012:bs=-0.016:rm=0.035:gm=0.014:bm=-0.02,"
    "split[base][glow];[glow]gblur=sigma=10[g];"
    "[base][g]blend=all_mode=screen:all_opacity=0.12,"
    "unsharp=5:5:0.25:5:5:0.0"
)


def run(cmd: list[str]) -> None:
    print("+", " ".join(str(c) for c in cmd[:10]), "...")
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
        "-c:v", "h264_videotoolbox", "-b:v", "45M", "-pix_fmt", "yuv420p",
        "-t", f"{out_dur:.3f}", str(dst),
    ])
    return out_dur


def concat_copy(clips: list[Path], dst: Path) -> float:
    lst = WORK / "concat.txt"
    lst.write_text("".join(f"file '{c}'\n" for c in clips))
    run([FF, "-y", "-f", "concat", "-safe", "0", "-i", str(lst), "-c", "copy", str(dst)])
    return probe(dst)


def burn_brand_overlay(video: Path, dst: Path, total: float, mid_at: float) -> None:
    """StillScout: whisper mid-film over sky + strong end card."""
    end_start = total - 5.4
    mid_end = mid_at + 2.6
    vf = (
        # Soft mid StillScout over empty sky
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Didot.ttc:"
        f"text='StillScout':fontsize=96:fontcolor=white@0.72:"
        f"x=(w-text_w)/2:y=h*0.14:"
        f"enable='between(t,{mid_at:.2f},{mid_end:.2f})',"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Georgia.ttf:"
        f"text='Scout the perfect still.':fontsize=44:fontcolor=white@0.58:"
        f"x=(w-text_w)/2:y=h*0.14+108:"
        f"enable='between(t,{mid_at + 0.35:.2f},{mid_end:.2f})',"
        # End card bar + titles
        f"drawbox=x=0:y=ih*0.70:w=iw:h=ih*0.30:color=black@0.35:t=fill:"
        f"enable='gte(t,{end_start:.2f})',"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Didot.ttc:"
        f"text='StillScout':fontsize=128:fontcolor=0xFFFAF5@0.96:"
        f"x=(w-text_w)/2:y=h*0.78:"
        f"enable='gte(t,{end_start + 0.8:.2f})',"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Georgia.ttf:"
        f"text='Scout the perfect still.':fontsize=54:fontcolor=0xFFF8F0@0.90:"
        f"x=(w-text_w)/2:y=h*0.78+140:"
        f"enable='gte(t,{end_start + 1.3:.2f})',"
        f"fade=t=out:st={total - 1.3:.2f}:d=1.3"
    )
    run([
        FF, "-y", "-i", str(video), "-vf", vf,
        "-c:v", "h264_videotoolbox", "-b:v", "45M", "-pix_fmt", "yuv420p",
        "-an", str(dst),
    ])


def build_foley_mix(total: float, dst: Path, marks: dict[str, float]) -> None:
    """Sound-engineer grade mix with timed Foley synced to shot marks."""
    A = AUDIO

    def ms(sec: float) -> int:
        return max(0, int(sec * 1000))

    t_hands = marks["hands"]
    t_profile = marks["profile"]
    t_face = marks["face"]
    t_harbor = marks["harbor"]
    t_sky = marks["sky"]
    t_phone = marks["phone"]
    t_rest = marks["rest"]
    t_endnb = marks["end_notebook"]

    fc = (
        # --- beds ---
        f"[0:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=70,lowpass=f=9000,volume=0.40,"
        f"afade=t=in:st=0:d=2,afade=t=out:st={total-2.5}:d=2.5[ocean];"
        f"[1:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=200,lowpass=f=3500,volume=0.11,afade=t=in:st=0:d=2[wind];"
        f"[2:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"volume=0.10,highpass=f=900,lowpass=f=5500,"
        f"afade=t=in:st={t_harbor:.2f}:d=2.5,afade=t=out:st={total-4}:d=3[gulls];"
        f"[3:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=140,lowpass=f=4500,volume=0.10,afade=t=in:st=0:d=1.5[loc];"
        # Piano soft under — enters as writing begins
        f"[4:a]adelay={ms(t_hands)}|{ms(t_hands)},atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=100,lowpass=f=5600,"
        f"acompressor=threshold=-24dB:ratio=2.8:attack=60:release=350,"
        f"volume=0.28,afade=t=in:st=0:d=3.2,afade=t=out:st={total-3}:d=3[piano];"
        # Scribble bed under writing block (hands → face write)
        f"[5:a]aloop=loop=-1:size=2e+09,atrim=0:{t_harbor - t_hands + 1:.2f},asetpts=N/SR/TB,"
        f"adelay={ms(t_hands)}|{ms(t_hands)},"
        f"highpass=f=800,lowpass=f=9000,volume=0.58,"
        f"afade=t=in:st=0:d=0.35,afade=t=out:st={t_harbor - t_hands - 0.8:.2f}:d=1.0,"
        f"atrim=0:{total},asetpts=N/SR/TB[scribble];"
        # Pen accents on writing shots
        f"[6:a]adelay={ms(t_hands + 1.1)}|{ms(t_hands + 1.1)},volume=0.68,highpass=f=1000,atrim=0:{total},asetpts=N/SR/TB[pen1];"
        f"[7:a]adelay={ms(t_profile + 0.6)}|{ms(t_profile + 0.6)},volume=0.52,highpass=f=1200,atrim=0:{total},asetpts=N/SR/TB[pen2];"
        f"[15:a]adelay={ms(t_face + 0.8)}|{ms(t_face + 0.8)},volume=0.55,highpass=f=1000,atrim=0:{total},asetpts=N/SR/TB[pen3];"
        f"[6:a]adelay={ms(t_face + 2.4)}|{ms(t_face + 2.4)},volume=0.42,highpass=f=1000,atrim=0:{total},asetpts=N/SR/TB[pen4];"
        # Page / book open + closing pages
        f"[8:a]adelay={ms(0.30)}|{ms(0.30)},volume=0.72,atrim=0:{total},asetpts=N/SR/TB[book];"
        f"[9:a]adelay={ms(0.95)}|{ms(0.95)},volume=0.58,atrim=0:{total},asetpts=N/SR/TB[page1];"
        f"[10:a]adelay={ms(t_endnb + 0.4)}|{ms(t_endnb + 0.4)},volume=0.62,atrim=0:{total},asetpts=N/SR/TB[page2];"
        f"[11:a]adelay={ms(t_endnb + 1.8)}|{ms(t_endnb + 1.8)},volume=0.68,atrim=0:{total},asetpts=N/SR/TB[page3];"
        f"[9:a]adelay={ms(t_endnb + 2.7)}|{ms(t_endnb + 2.7)},volume=0.48,atrim=0:{total},asetpts=N/SR/TB[page4];"
        # Fabric / whoosh into world + phone raise
        f"[12:a]adelay={ms(t_profile + 0.2)}|{ms(t_profile + 0.2)},volume=0.36,atrim=0:{total},asetpts=N/SR/TB[fab1];"
        f"[13:a]adelay={ms(t_phone + 0.3)}|{ms(t_phone + 0.3)},volume=0.42,atrim=0:{total},asetpts=N/SR/TB[fab2];"
        f"[14:a]adelay={ms(t_harbor)}|{ms(t_harbor)},volume=0.30,lowpass=f=4000,atrim=0:{total},asetpts=N/SR/TB[whoosh1];"
        f"[14:a]adelay={ms(t_phone + 0.1)}|{ms(t_phone + 0.1)},volume=0.22,lowpass=f=3500,atrim=0:{total},asetpts=N/SR/TB[whoosh2];"
        # Mix
        f"[ocean][wind][gulls][loc][piano][scribble][pen1][pen2][pen3][pen4]"
        f"[book][page1][page2][page3][page4][fab1][fab2][whoosh1][whoosh2]"
        f"amix=inputs=19:normalize=0:dropout_transition=2,"
        f"equalizer=f=220:t=q:w=1:g=-2,"
        f"equalizer=f=3500:t=q:w=1:g=1.5,"
        f"equalizer=f=6000:t=q:w=1:g=0.8,"
        f"alimiter=limit=0.90,loudnorm=I=-16:TP=-1.5:LRA=9[aout]"
    )

    inputs = [
        A / "ocean.mp3",
        A / "wind.mp3" if (A / "wind.mp3").exists() else A / "ocean.mp3",
        A / "seagulls.mp3",
        A / "loc.wav" if (A / "loc.wav").exists() else A / "ocean.mp3",
        A / "piano.mp3",
        A / "writing_1.mp3",
        A / "pen_on_paper.mp3",
        A / "pencil_scribble.mp3",
        A / "book_open.mp3",
        A / "page_turn_soft.mp3",
        A / "page_flip_2.mp3",
        A / "page_flip_1.mp3",
        A / "fabric_2.mp3",
        A / "clothes_rustle.mp3",
        A / "soft_whoosh.mp3",
        A / "pen_write.mp3",
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

    # ~45s picture plan (durations after speed)
    shots = []
    # 1 notebook open
    shots.append(render("MVI_0387.MP4", clips / "01.mp4",
                        start=0.6, duration=3.2, speed=0.85, beauty=True, fade_in=0.9,
                        crop_y="(ih-oh)/2-80"))
    # 2 hands writing
    shots.append(render("MVI_0356.MP4", clips / "02.mp4",
                        start=5.0, duration=3.8, speed=0.80, beauty=True))
    # 3 best handsome profile
    shots.append(render("MVI_0358.MP4", clips / "03.mp4",
                        start=2.5, duration=4.8, speed=0.86, beauty=True,
                        crop_y="(ih-oh)/2+40"))
    # 4 soft face
    shots.append(render("MVI_0353.MP4", clips / "04.mp4",
                        start=16.0, duration=4.0, speed=0.84, beauty=True,
                        crop_y="(ih-oh)/2+240"))
    # 5 face write beauty (short)
    shots.append(render("MVI_0355.MP4", clips / "05.mp4",
                        start=7.0, duration=3.2, speed=0.85, beauty=True,
                        crop_y="(ih-oh)/2+180"))
    # 6 harbor reveal
    shots.append(render("MVI_0343.MP4", clips / "06.mp4",
                        start=1.0, duration=4.2, speed=0.90,
                        crop_y="(ih-oh)/2+60"))
    # 7 sky breath (StillScout mid-title overlays here)
    shots.append(render("MVI_0365.MP4", clips / "07.mp4",
                        start=8.0, duration=4.0, speed=0.88))
    # 8 phone scout
    shots.append(render("MVI_0363.MP4", clips / "08.mp4",
                        start=9.0, duration=4.2, speed=0.88,
                        crop_y="(ih-oh)/2+90"))
    # 9 rest
    shots.append(render("MVI_0359.MP4", clips / "09.mp4",
                        start=5.0, duration=3.5, speed=0.88, beauty=True,
                        crop_y="(ih-oh)/2+80"))
    # 10 end notebook
    shots.append(render("MVI_0387.MP4", clips / "10.mp4",
                        start=2.5, duration=5.0, speed=0.90, beauty=True,
                        crop_y="(ih-oh)/2-40"))

    paths = [clips / f"{i:02d}.mp4" for i in range(1, 11)]
    durs = [probe(p) for p in paths]
    for p, d, plan in zip(paths, durs, shots):
        print(f"  {p.name}: {d:.2f}s (plan {plan:.2f})")

    # Cumulative start marks for Foley + brand sync
    cum = 0.0
    names = [
        "notebook", "hands", "profile", "face", "facewrite",
        "harbor", "sky", "phone", "rest", "end_notebook",
    ]
    marks = {}
    for name, d in zip(names, durs):
        marks[name] = cum
        cum += d
    print("Marks:", {k: round(v, 2) for k, v in marks.items()})

    silent = WORK / "picture_raw.mp4"
    total = concat_copy(paths, silent)
    print("Raw picture:", total)

    branded = WORK / "picture_branded.mp4"
    burn_brand_overlay(silent, branded, total, mid_at=marks["sky"] + 0.6)
    total = probe(branded)

    # Keep ~45s social length
    if total > 47.5:
        trimmed = WORK / "picture_trim.mp4"
        run([FF, "-y", "-i", str(branded), "-t", "46", "-c", "copy", str(trimmed)])
        branded = trimmed
        total = probe(branded)

    audio = WORK / "mix.m4a"
    build_foley_mix(total, audio, marks)

    master = EXPORT / "StillScout_BeforeTheCapture_4K_9x16.mp4"
    social = EXPORT / "StillScout_BeforeTheCapture_1080x1920.mp4"
    # also update "best" alias
    best4k = EXPORT / "StillScout_Best_4K_9x16.mp4"
    best1080 = EXPORT / "StillScout_Best_1080x1920.mp4"

    run([
        FF, "-y", "-i", str(branded), "-i", str(audio),
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
    run(["cp", str(master), str(best4k)])
    run(["cp", str(social), str(best1080)])

    err = subprocess.run(
        [FF, "-v", "error", "-i", str(master), "-f", "null", "-"],
        capture_output=True, text=True,
    )
    print("DECODE:", "CLEAN" if not err.stderr.strip() else err.stderr[:300])

    meta = {
        "title": "StillScout — Before the Capture (v5 best)",
        "duration_sec": probe(master),
        "sound": "ocean + wind + gulls + location + soft piano + scribble/pen/page/fabric Foley",
        "branding": "mid-film StillScout whisper + end card",
        "master": str(master),
        "social": str(social),
        "best_alias": str(best1080),
    }
    (EXPORT / "manifest_v5.json").write_text(json.dumps(meta, indent=2))
    (EXPORT / "AUDIO_CREDITS_v5.txt").write_text(
        "Music: Dreams Become Real — Kevin MacLeod (incompetech.com) CC BY 4.0\n"
        "Ambience: Mixkit ocean / wind / seagulls\n"
        "Foley: Mixkit paper, page turns, pen/pencil writing, fabric\n"
        "Location air from source footage\n"
    )
    print(json.dumps(meta, indent=2))
    print("DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
