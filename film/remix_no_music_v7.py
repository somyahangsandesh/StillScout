#!/usr/bin/env python3
"""Remix v7 picture: NO music, NO location voice — Foley + soft nature only.
Leaves headroom for user VO. Player-safe social export."""

from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path("/Users/sandeshsomyahang/stillscout/film")
FF = str(ROOT / "bin" / "ffmpeg")
FP = str(ROOT / "bin" / "ffprobe")
WORK = ROOT / "work_v7"
EXPORT = ROOT / "export"
AUDIO = ROOT / "audio" / "src_v5"
PICTURE = WORK / "picture.mp4"


def run(cmd: list[str]) -> None:
    print("+", " ".join(str(c) for c in cmd[:10]), "...")
    subprocess.run(cmd, check=True)


def probe(path: Path) -> float:
    return float(subprocess.check_output(
        [FP, "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        text=True,
    ).strip())


def main() -> int:
    total = probe(PICTURE)
    # Marks from v7 assemble (xfade-adjusted)
    marks = {
        "hands": 2.95,
        "profile": 7.21,
        "face": 12.73,
        "harbor": 16.88,
        "sky": 20.77,
        "phone": 24.49,
        "screen": 28.11,
        "still": 31.19,
        "rest": 31.36,
        "end": 34.21,
    }

    def ms(sec: float) -> int:
        return max(0, int(sec * 1000))

    t_hands = marks["hands"]
    t_profile = marks["profile"]
    t_face = marks["face"]
    t_harbor = marks["harbor"]
    t_phone = marks["phone"]
    t_still = marks["still"]
    t_end = marks["end"]
    scribble_len = max(2.5, t_harbor - t_hands - 0.3)

    # Soft beds only — no piano, no location dialogue bed
    # Keep Foley clear but leave VO pocket (beds sit under)
    fc = (
        f"[0:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=70,lowpass=f=9000,volume=0.38,"
        f"afade=t=in:st=0:d=1.5,afade=t=out:st={total-2.2}:d=2.2[ocean];"
        f"[1:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=200,lowpass=f=3400,volume=0.09,afade=t=in:st=0:d=1.8[wind];"
        f"[2:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"volume=0.08,highpass=f=900,lowpass=f=5500,"
        f"afade=t=in:st={t_harbor:.2f}:d=2.0,afade=t=out:st={total-3.5}:d=2.5[gulls];"
        # scribble / pens / pages / fabric / whoosh
        f"[3:a]aloop=loop=-1:size=2e+09,atrim=0:{scribble_len:.2f},asetpts=N/SR/TB,"
        f"adelay={ms(t_hands)}|{ms(t_hands)},"
        f"highpass=f=750,lowpass=f=10000,volume=0.85,"
        f"afade=t=in:st=0:d=0.2,afade=t=out:st={scribble_len-0.55:.2f}:d=0.55,"
        f"atrim=0:{total},asetpts=N/SR/TB[scribble];"
        f"[4:a]adelay={ms(t_hands + 0.7)}|{ms(t_hands + 0.7)},volume=0.85,highpass=f=1000,atrim=0:{total},asetpts=N/SR/TB[pen1];"
        f"[5:a]adelay={ms(t_profile + 0.4)}|{ms(t_profile + 0.4)},volume=0.70,highpass=f=1100,atrim=0:{total},asetpts=N/SR/TB[pen2];"
        f"[6:a]adelay={ms(t_profile + 2.0)}|{ms(t_profile + 2.0)},volume=0.65,highpass=f=1000,atrim=0:{total},asetpts=N/SR/TB[pen3];"
        f"[4:a]adelay={ms(t_face + 0.5)}|{ms(t_face + 0.5)},volume=0.45,highpass=f=1000,atrim=0:{total},asetpts=N/SR/TB[pen4];"
        f"[7:a]adelay={ms(0.2)}|{ms(0.2)},volume=0.80,atrim=0:{total},asetpts=N/SR/TB[book];"
        f"[8:a]adelay={ms(0.75)}|{ms(0.75)},volume=0.68,atrim=0:{total},asetpts=N/SR/TB[page1];"
        f"[9:a]adelay={ms(t_end + 0.25)}|{ms(t_end + 0.25)},volume=0.60,atrim=0:{total},asetpts=N/SR/TB[page2];"
        f"[8:a]adelay={ms(t_end + 1.4)}|{ms(t_end + 1.4)},volume=0.42,atrim=0:{total},asetpts=N/SR/TB[page3];"
        f"[10:a]adelay={ms(t_profile)}|{ms(t_profile)},volume=0.32,atrim=0:{total},asetpts=N/SR/TB[fab1];"
        f"[11:a]adelay={ms(t_phone + 0.15)}|{ms(t_phone + 0.15)},volume=0.40,atrim=0:{total},asetpts=N/SR/TB[fab2];"
        f"[12:a]adelay={ms(t_harbor)}|{ms(t_harbor)},volume=0.30,lowpass=f=4200,atrim=0:{total},asetpts=N/SR/TB[whoosh1];"
        f"[12:a]adelay={ms(t_still)}|{ms(t_still)},volume=0.22,lowpass=f=3500,atrim=0:{total},asetpts=N/SR/TB[whoosh2];"
        f"[12:a]adelay={ms(t_end + 0.85)}|{ms(t_end + 0.85)},volume=0.24,lowpass=f=2800,atrim=0:{total},asetpts=N/SR/TB[whoosh3];"
        # Dip beds under end brand for VO tagline
        f"[ocean][wind][gulls][scribble][pen1][pen2][pen3][pen4]"
        f"[book][page1][page2][page3][fab1][fab2][whoosh1][whoosh2][whoosh3]"
        f"amix=inputs=17:normalize=0:dropout_transition=2,"
        f"equalizer=f=3500:t=q:w=1:g=1.5,"
        f"volume='if(lt(t,{t_end:.2f}),1.0,0.40)',"
        f"alimiter=limit=0.90,loudnorm=I=-18:TP=-2.0:LRA=10[aout]"
    )

    mix = WORK / "mix_no_music.m4a"
    inputs = [
        AUDIO / "ocean.mp3",
        AUDIO / "wind.mp3",
        AUDIO / "seagulls.mp3",
        AUDIO / "writing_1.mp3",
        AUDIO / "pen_on_paper.mp3",
        AUDIO / "pencil_scribble.mp3",
        AUDIO / "pen_write.mp3",
        AUDIO / "book_open.mp3",
        AUDIO / "page_turn_soft.mp3",
        AUDIO / "page_flip_2.mp3",
        AUDIO / "fabric_2.mp3",
        AUDIO / "clothes_rustle.mp3",
        AUDIO / "soft_whoosh.mp3",
    ]
    cmd = [FF, "-y"]
    for p in inputs:
        cmd += ["-i", str(p)]
    cmd += [
        "-filter_complex", fc, "-map", "[aout]", "-t", str(total),
        "-c:a", "aac", "-b:a", "320k", str(mix),
    ]
    run(cmd)

    master = EXPORT / "StillScout_BeforeTheCapture_4K_9x16.mp4"
    social = EXPORT / "StillScout_BeforeTheCapture_1080x1920.mp4"
    play = EXPORT / "StillScout_PLAY_ME_1080x1920.mp4"
    best = EXPORT / "StillScout_Best_1080x1920.mp4"
    vo_bed = EXPORT / "StillScout_VO_BED_1080x1920.mp4"  # for recording over

    # 4K master (videotoolbox picture already exists)
    run([
        FF, "-y", "-i", str(PICTURE), "-i", str(mix),
        "-map", "0:v", "-map", "1:a",
        "-c:v", "copy", "-c:a", "aac", "-b:a", "320k",
        "-movflags", "+faststart", "-shortest", str(master),
    ])

    # Player-safe social / VO bed
    run([
        FF, "-y", "-i", str(master),
        "-vf", "scale=1080:1920:flags=lanczos,format=yuv420p",
        "-c:v", "libx264", "-preset", "fast", "-crf", "18",
        "-profile:v", "high", "-level", "4.1",
        "-pix_fmt", "yuv420p",
        "-colorspace", "bt709", "-color_primaries", "bt709",
        "-color_trc", "bt709", "-color_range", "tv",
        "-movflags", "+faststart",
        "-c:a", "aac", "-b:a", "256k",
        str(play),
    ])
    run(["cp", str(play), str(social)])
    run(["cp", str(play), str(best)])
    run(["cp", str(play), str(vo_bed)])

    meta = {
        "title": "StillScout v7 — no music VO bed",
        "duration_sec": probe(play),
        "audio": "ocean + wind + gulls + Foley only (no piano, no location voice)",
        "play": str(play),
        "vo_bed": str(vo_bed),
    }
    (EXPORT / "manifest_v7_nomusic.json").write_text(json.dumps(meta, indent=2))
    print(json.dumps(meta, indent=2))
    print("DONE")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
