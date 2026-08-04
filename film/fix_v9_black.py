#!/usr/bin/env python3
"""Fix v9 'black' feel: UI on bright lifestyle plates + soft end + player-safe MOV."""

from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path("/Users/sandeshsomyahang/stillscout/film")
FOOTAGE = Path("/Users/sandeshsomyahang/Downloads/New Folder With Items")
SHOTS = Path("/Users/sandeshsomyahang/stillscout/docs/asc_assets/screenshots_67")
FF = str(ROOT / "bin" / "ffmpeg")
FP = str(ROOT / "bin" / "ffprobe")
WORK = ROOT / "work_v9"
CLIPS = WORK / "clips"
EXPORT = ROOT / "export"
AUDIO = ROOT / "audio" / "src_v5"
MARK = ROOT / "assets" / "stillscout_mark_light.png"
W, H, FPS = 2160, 3840, 30


def run(cmd: list[str]) -> None:
    print("+", " ".join(str(c) for c in cmd[:10]), "...")
    subprocess.run(cmd, check=True)


def probe(path: Path) -> float:
    return float(subprocess.check_output(
        [FP, "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        text=True,
    ).strip())


def render_bg(src: str, dst: Path, *, start: float, duration: float, crop_y: str) -> None:
    vf = (
        f"deshake=rx=16:ry=16,setpts=PTS/0.95,"
        f"scale={int(W*1.12)}:{int(H*1.12)}:force_original_aspect_ratio=increase:flags=lanczos,"
        f"crop={W}:{H}:(iw-ow)/2:{crop_y},"
        "eq=contrast=1.02:brightness=0.04:saturation=0.95,"
        "gblur=sigma=8"  # soft plate under UI
    )
    run([
        FF, "-y", "-ss", f"{start:.2f}", "-t", f"{duration:.2f}",
        "-i", str(FOOTAGE / src), "-vf", vf, "-an", "-r", str(FPS),
        "-c:v", "h264_videotoolbox", "-b:v", "35M", "-pix_fmt", "yuv420p",
        "-t", f"{duration/0.95:.3f}", str(dst),
    ])


def ui_over_lifestyle(png: Path, bg: Path, dst: Path, *, dur: float) -> float:
    """Bright lifestyle under a readable phone screenshot card."""
    # Screenshot fits width with margin; soft shadow via pad
    fc = (
        f"[0:v]scale={W}:{H},trim=duration={dur},setpts=PTS-STARTPTS,eq=brightness=0.05[bg];"
        f"[1:v]scale='min({int(W*0.88)}\\,iw)':-1:flags=lanczos,"
        f"pad=iw+40:ih+40:20:20:color=black@0.0,"
        f"format=rgba[ui];"
        f"[bg][ui]overlay=(W-w)/2:(H-h)/2+80:format=auto,"
        f"fade=t=in:st=0:d=0.25,fade=t=out:st={dur-0.25:.2f}:d=0.25[vout]"
    )
    run([
        FF, "-y",
        "-stream_loop", "-1", "-i", str(bg),
        "-loop", "1", "-i", str(png),
        "-filter_complex", fc, "-map", "[vout]",
        "-t", f"{dur:.3f}",
        "-c:v", "h264_videotoolbox", "-b:v", "40M", "-pix_fmt", "yuv420p",
        str(dst),
    ])
    return probe(dst)


def end_over_lifestyle(bg: Path, dst: Path, *, dur: float = 6.2) -> float:
    logo = MARK if MARK.exists() else ROOT / "assets" / "stillscout_mark.png"
    comma = r"\,"
    fc = (
        f"[0:v]scale={W}:{H},trim=duration={dur},setpts=PTS-STARTPTS,"
        f"eq=brightness=-0.15:saturation=0.7,gblur=sigma=12[bg];"
        f"[1:v]format=rgba,scale=700:700,"
        f"fade=t=in:st=0:d=0.8:alpha=1,"
        f"fade=t=out:st={dur-1.3:.2f}:d=1.1:alpha=1[lg];"
        f"[bg][lg]overlay=x='(W-w)/2':"
        f"y='H*0.28-h/2+24*(1-min(1{comma}max(0{comma}(t-0.5)/1.0)))':"
        f"format=auto[v1];"
        f"[v1]"
        f"drawbox=x=0:y=ih*0.55:w=iw:h=ih*0.45:color=black@0.35:t=fill,"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Didot.ttc:"
        f"text='StillScout':fontsize=132:fontcolor=0xFFFAF5@0.0:"
        f"x=(w-text_w)/2:y=h*0.58:"
        f"alpha='if(lt(t,1.2),0,if(lt(t,2.1),(t-1.2)/0.9,if(gt(t,{dur-1.2:.2f}),"
        f"({dur:.2f}-t)/1.2,0.98)))',"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Georgia.ttf:"
        f"text='Scout the perfect still.':fontsize=52:fontcolor=0xF2E8DA@0.0:"
        f"x=(w-text_w)/2:y=h*0.58+145:"
        f"alpha='if(lt(t,2.0),0,if(lt(t,2.8),(t-2.0)/0.8,if(gt(t,{dur-1.1:.2f}),"
        f"({dur:.2f}-t)/1.1,0.92)))',"
        f"drawtext=fontfile=/System/Library/Fonts/Supplemental/Helvetica.ttc:"
        f"text='Drop any video. AI finds your best photo.':fontsize=40:fontcolor=0xE8E0D4@0.0:"
        f"x=(w-text_w)/2:y=h*0.58+240:"
        f"alpha='if(lt(t,2.6),0,if(lt(t,3.3),(t-2.6)/0.7,if(gt(t,{dur-1.1:.2f}),"
        f"({dur:.2f}-t)/1.1,0.88)))',"
        f"fade=t=in:st=0:d=0.35,fade=t=out:st={dur-1.2:.2f}:d=1.2[vout]"
    )
    run([
        FF, "-y",
        "-stream_loop", "-1", "-i", str(bg),
        "-loop", "1", "-i", str(logo),
        "-filter_complex", fc, "-map", "[vout]",
        "-t", f"{dur:.3f}",
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
        parts.append(
            f"[{prev}][{i}:v]xfade=transition=fade:duration={xfade}:offset={offset:.3f}[{out}]"
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


def burn_copy(video: Path, dst: Path, marks: dict[str, float]) -> float:
    lines = [
        (marks["hook"] + 0.4, marks["hook"] + 2.5, "You filmed the moment.", 64, 0.78),
        (marks["hands"] + 0.3, marks["profile"] + 0.15, "Finding the still is the hard part.", 56, 0.80),
        (marks["phone"] + 0.2, marks["still"] + 0.05, "Lost in the scrub.", 62, 0.78),
        (marks["still"] + 0.15, marks["ui1"] - 0.1, "StillScout finds it.", 70, 0.76),
        (marks["proof"] + 0.25, marks["proof"] + 2.5, "Same clip. Better still.", 66, 0.78),
    ]
    font = "/System/Library/Fonts/Supplemental/Georgia.ttf"
    didot = "/System/Library/Fonts/Supplemental/Didot.ttc"
    parts = []
    for st, en, text, size, yf in lines:
        safe = text.replace(":", "\\:")
        fn = didot if "StillScout" in text else font
        alpha = (
            f"if(lt(t,{st:.2f}),0,if(lt(t,{st+0.3:.2f}),(t-{st:.2f})/0.3,"
            f"if(lt(t,{en-0.3:.2f}),0.92,if(lt(t,{en:.2f}),({en:.2f}-t)/0.3*0.92,0))))"
        )
        parts.append(
            f"drawtext=fontfile={fn}:text='{safe}':fontsize={size}:"
            f"fontcolor=white@0.0:x=(w-text_w)/2:y=h*{yf}:"
            f"borderw=3:bordercolor=black@0.45:alpha='{alpha}'"
        )
    run([
        FF, "-y", "-i", str(video), "-vf", ",".join(parts),
        "-c:v", "h264_videotoolbox", "-b:v", "48M", "-pix_fmt", "yuv420p", "-an",
        str(dst),
    ])
    return probe(dst)


def mix(total: float, marks: dict[str, float], dst: Path) -> None:
    def ms(s: float) -> int:
        return max(0, int(s * 1000))

    t_hands, t_profile = marks["hands"], marks["profile"]
    t_phone, t_still = marks["phone"], marks["still"]
    t_ui1, t_end = marks["ui1"], marks["end"]
    scribble_len = max(2.0, t_phone - t_hands)
    fc = (
        f"[0:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"highpass=f=70,volume=0.36,afade=t=in:st=0:d=1.2,afade=t=out:st={total-2}:d=2[ocean];"
        f"[1:a]aloop=loop=-1:size=2e+09,atrim=0:{total},asetpts=N/SR/TB,"
        f"volume=0.07,afade=t=in:st=0:d=1.5[wind];"
        f"[2:a]aloop=loop=-1:size=2e+09,atrim=0:{scribble_len:.2f},asetpts=N/SR/TB,"
        f"adelay={ms(t_hands)}|{ms(t_hands)},volume=0.8,highpass=f=800,"
        f"afade=t=in:st=0:d=0.15,afade=t=out:st={scribble_len-0.4:.2f}:d=0.4,"
        f"atrim=0:{total},asetpts=N/SR/TB[scribble];"
        f"[3:a]adelay={ms(t_hands+0.6)}|{ms(t_hands+0.6)},volume=0.75,atrim=0:{total},asetpts=N/SR/TB[pen];"
        f"[4:a]adelay={ms(0.2)}|{ms(0.2)},volume=0.7,atrim=0:{total},asetpts=N/SR/TB[book];"
        f"[5:a]adelay={ms(t_still)}|{ms(t_still)},volume=0.3,atrim=0:{total},asetpts=N/SR/TB[shutter];"
        f"[5:a]adelay={ms(t_ui1)}|{ms(t_ui1)},volume=0.2,atrim=0:{total},asetpts=N/SR/TB[uiw];"
        f"[ocean][wind][scribble][pen][book][shutter][uiw]amix=inputs=7:normalize=0,"
        f"volume='if(lt(t,{t_end:.2f}),1.0,0.35)',"
        f"loudnorm=I=-18:TP=-2:LRA=9[aout]"
    )
    cmd = [FF, "-y"]
    for p in [
        AUDIO / "ocean.mp3", AUDIO / "wind.mp3", AUDIO / "writing_1.mp3",
        AUDIO / "pen_on_paper.mp3", AUDIO / "book_open.mp3", AUDIO / "soft_whoosh.mp3",
    ]:
        cmd += ["-i", str(p)]
    cmd += ["-filter_complex", fc, "-map", "[aout]", "-t", str(total),
            "-c:a", "aac", "-b:a", "320k", str(dst)]
    run(cmd)


def export_safe(src: Path, mp4: Path, mov: Path) -> None:
    # Extra-compatible for QuickTime / Photos
    common = [
        "-vf", "scale=1080:1920:flags=lanczos,format=yuv420p,eq=brightness=0.02:contrast=1.02",
        "-c:v", "libx264", "-preset", "fast", "-crf", "17",
        "-profile:v", "main", "-level", "4.0",
        "-pix_fmt", "yuv420p", "-tag:v", "avc1",
        "-colorspace", "bt709", "-color_primaries", "bt709",
        "-color_trc", "bt709", "-color_range", "tv",
        "-movflags", "+faststart",
        "-c:a", "aac", "-b:a", "256k", "-ar", "44100", "-ac", "2",
    ]
    run([FF, "-y", "-i", str(src), *common, str(mp4)])
    run([FF, "-y", "-i", str(mp4), "-c", "copy", str(mov)])


def main() -> int:
    # Bright plates for UI / end
    bg_ui = WORK / "bg_ui.mp4"
    bg_end = WORK / "bg_end.mp4"
    render_bg("MVI_0343.MP4", bg_ui, start=1.0, duration=8.0, crop_y="(ih-oh)/2+40")
    render_bg("MVI_0365.MP4", bg_end, start=8.0, duration=8.0, crop_y="(ih-oh)/2")

    # Rebuild dark clips
    ui1 = CLIPS / "07_ui_scout.mp4"
    ui2 = CLIPS / "08_ui_picks.mp4"
    ui3 = CLIPS / "09_ui_export.mp4"
    brand = CLIPS / "11_brand.mp4"
    ui_over_lifestyle(SHOTS / "02_ai_scouting.png", bg_ui, ui1, dur=4.0)
    ui_over_lifestyle(SHOTS / "01_hero.png", bg_ui, ui2, dur=3.8)
    ui_over_lifestyle(SHOTS / "05_export.png", bg_ui, ui3, dur=3.0)
    end_over_lifestyle(bg_end, brand, dur=6.2)

    # Keep lifestyle clips from prior build
    plan = [
        (CLIPS / "01_hook.mp4", "hook"),
        (CLIPS / "02_hands.mp4", "hands"),
        (CLIPS / "03_profile.mp4", "profile"),
        (CLIPS / "04_harbor.mp4", "harbor"),
        (CLIPS / "05_phone.mp4", "phone"),
        (CLIPS / "06_still.mp4", "still"),
        (ui1, "ui1"),
        (ui2, "ui2"),
        (ui3, "ui3"),
        (CLIPS / "10_proof.mp4", "proof"),
        (brand, "end"),
    ]
    for p, _ in plan:
        if not p.exists():
            raise SystemExit(f"missing {p}")

    durs = [probe(p) for p, _ in plan]
    marks_raw = {}
    cum = 0.0
    for (p, name), d in zip(plan, durs):
        marks_raw[name] = cum
        print(f"  {p.name}: {d:.2f}s @{cum:.2f}")
        cum += d

    xfade = 0.28
    paths = [p for p, _ in plan]
    raw = WORK / "picture_raw_fixed.mp4"
    total = assemble(paths, durs, raw, xfade=xfade)
    marks = {n: max(0.0, marks_raw[n] - xfade * i) for i, (_, n) in enumerate(plan)}
    print("Marks", {k: round(v, 2) for k, v in marks.items()})

    pictured = WORK / "picture_fixed.mp4"
    burn_copy(raw, pictured, marks)
    total = probe(pictured)

    audio = WORK / "mix_fixed.m4a"
    mix(total, marks, audio)

    master = WORK / "master_fixed.mp4"
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

    # brightness sanity
    for t in (1, 10, 18, 22, 28, 34):
        out = subprocess.check_output(
            [FF, "-ss", str(t), "-i", str(play),
             "-vf", "signalstats,metadata=print:key=lavfi.signalstats.YAVG",
             "-frames:v", "1", "-f", "null", "-"],
            stderr=subprocess.STDOUT, text=True,
        )
        for line in out.splitlines():
            if "YAVG=" in line:
                print(f"t={t}", line.strip().split()[-1])
                break

    meta = {
        "fix": "UI over bright lifestyle + soft end brand + QuickTime-safe encode",
        "duration_sec": probe(play),
        "play_mp4": str(play),
        "play_mov": str(mov),
    }
    (EXPORT / "manifest_v9_fixed.json").write_text(json.dumps(meta, indent=2))
    print(json.dumps(meta, indent=2))
    print("DONE")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
