#!/usr/bin/env python
"""
StillScout — Before the Capture
Run FROM DaVinci Resolve: Workspace > Scripts > StillScout_BuildFilm

Builds vertical 9:16 timeline, beauty grade (CDL), audio, titles, renders.
"""

import os
import sys
import time

FOOTAGE = "/Users/sandeshsomyahang/Downloads/New Folder With Items"
AUDIO_DIR = "/Users/sandeshsomyahang/stillscout/film/audio/src_v3"
EXPORT = "/Users/sandeshsomyahang/stillscout/film/export"
PROJECT_NAME = "StillScout_BeforeTheCapture"
TIMELINE_NAME = "Before the Capture"
FPS = 24.0  # source is ~23.98

# Creative cut: (filename, in_sec, out_sec, speed_optional)
# speed: 1.0 normal; Resolve uses Retime via clip properties when possible
SHOTS = [
    ("MVI_0387.MP4", 0.8, 4.0),     # notebook pages
    ("MVI_0356.MP4", 6.0, 10.0),    # hands
    ("MVI_0358.MP4", 3.5, 8.5),     # handsome profile
    ("MVI_0353.MP4", 18.0, 22.5),   # soft face
    ("MVI_0343.MP4", 1.2, 6.0),     # harbor reveal
    ("MVI_0365.MP4", 10.0, 15.0),   # sky breath
    ("MVI_0363.MP4", 10.0, 15.0),   # phone raise
    ("MVI_0378.MP4", 4.0, 8.0),     # OTS screen still
    ("MVI_0359.MP4", 6.0, 10.0),    # rest with notebook
    ("MVI_0387.MP4", 3.0, 8.5),     # end notebook
]

AUDIO_FILES = [
    os.path.join(AUDIO_DIR, "sfx_1206.mp3"),       # ocean
    os.path.join(AUDIO_DIR, "km_peaceful.mp3"),    # piano
    os.path.join(AUDIO_DIR, "seagulls.mp3"),
]


def get_resolve():
    try:
        import DaVinciResolveScript as dvr
        return dvr.scriptapp("Resolve")
    except Exception:
        pass
    # Fallback paths
    for modpath in [
        "/Applications/DaVinci Resolve.app/Contents/Resources/Developer/Scripting/Modules",
        os.path.expanduser(
            "~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting/Modules"
        ),
    ]:
        if modpath not in sys.path:
            sys.path.insert(0, modpath)
    import DaVinciResolveScript as dvr
    return dvr.scriptapp("Resolve")


def sec_to_frame(sec, fps=FPS):
    return int(round(sec * fps))


def apply_beauty_cdl(timeline_item):
    """Korean-drama soft look via CDL on node 1."""
    try:
        timeline_item.SetCDL({
            "NodeIndex": "1",
            # Slight warm lift, soft contrast feel via power
            "Slope": "1.02 1.00 0.96",
            "Offset": "0.02 0.015 0.01",
            "Power": "0.95 0.97 1.00",
            "Saturation": "0.82",
        })
        return True
    except Exception as e:
        print("CDL failed:", e)
        return False


def main():
    resolve = get_resolve()
    if not resolve:
        print("ERROR: Could not connect to Resolve. Run this from Workspace > Scripts.")
        return

    print("Resolve:", resolve.GetProductName(), resolve.GetVersionString())
    pm = resolve.GetProjectManager()

    # Create / load project
    project = pm.LoadProject(PROJECT_NAME)
    if not project:
        project = pm.CreateProject(PROJECT_NAME)
    if not project:
        print("ERROR: cannot create project")
        return
    print("Project:", project.GetName())

    # Vertical 4K timeline settings
    project.SetSetting("timelineResolutionWidth", "2160")
    project.SetSetting("timelineResolutionHeight", "3840")
    project.SetSetting("timelineFrameRate", "24")
    project.SetSetting("timelinePlaybackFrameRate", "24")
    try:
        project.SetSetting("timelineOutputResolutionWidth", "2160")
        project.SetSetting("timelineOutputResolutionHeight", "3840")
    except Exception:
        pass

    mp = project.GetMediaPool()
    root = mp.GetRootFolder()
    mp.SetCurrentFolder(root)

    # Import video
    video_paths = []
    for name, _, _ in SHOTS:
        p = os.path.join(FOOTAGE, name)
        if os.path.exists(p) and p not in video_paths:
            video_paths.append(p)

    print("Importing", len(video_paths), "video files...")
    clips = mp.ImportMedia(video_paths) or []
    print("Imported video items:", len(clips))

    # Map basename -> MediaPoolItem
    by_name = {}
    for c in (mp.GetRootFolder().GetClipList() or []):
        props = c.GetClipProperty()
        fn = props.get("File Name") or props.get("FileName") or ""
        by_name[fn] = c
        # also key without path
        by_name[os.path.basename(fn)] = c

    # Import audio
    audio_paths = [p for p in AUDIO_FILES if os.path.exists(p)]
    print("Importing audio:", audio_paths)
    if audio_paths:
        mp.ImportMedia(audio_paths)

    # Refresh map
    for c in (mp.GetRootFolder().GetClipList() or []):
        props = c.GetClipProperty()
        fn = props.get("File Name") or ""
        by_name[os.path.basename(fn)] = c
        by_name[fn] = c

    # Empty timeline
    # Delete old timeline with same name if exists
    for i in range(1, int(project.GetTimelineCount()) + 1):
        tl = project.GetTimelineByIndex(i)
        if tl and tl.GetName() == TIMELINE_NAME:
            mp.DeleteTimelines([tl])
            break

    timeline = mp.CreateEmptyTimeline(TIMELINE_NAME)
    if not timeline:
        print("ERROR: CreateEmptyTimeline failed")
        return
    project.SetCurrentTimeline(timeline)
    resolve.OpenPage("edit")

    # Append subclips
    append_list = []
    for name, in_s, out_s in SHOTS:
        item = by_name.get(name)
        if not item:
            print("MISSING clip in pool:", name)
            continue
        sf = sec_to_frame(in_s)
        ef = sec_to_frame(out_s)
        append_list.append({
            "mediaPoolItem": item,
            "startFrame": sf,
            "endFrame": ef,
            "mediaType": 1,  # video only — audio designed separately
        })
        print(f"  + {name} {in_s}-{out_s}s frames {sf}-{ef}")

    if not append_list:
        print("ERROR: nothing to append")
        return

    added = mp.AppendToTimeline(append_list)
    print("Appended items:", len(added) if added else 0)

    # Add audio tracks content
    timeline.AddTrack("audio", "stereo")
    # Append ocean full length-ish
    ocean = by_name.get("sfx_1206.mp3")
    piano = by_name.get("km_peaceful.mp3")
    gulls = by_name.get("seagulls.mp3")

    # Get timeline duration in frames
    try:
        start_tc = timeline.GetStartFrame()
        end_tc = timeline.GetEndFrame()
        tl_len = end_tc - start_tc
        print("Timeline frames:", tl_len)
    except Exception:
        tl_len = sec_to_frame(45)

    audio_append = []
    if ocean:
        audio_append.append({
            "mediaPoolItem": ocean,
            "startFrame": 0,
            "endFrame": min(tl_len + 24, sec_to_frame(120)),
            "mediaType": 2,
            "trackIndex": 1,
            "recordFrame": start_tc if 'start_tc' in dir() else 0,
        })
    if piano:
        # piano starts ~2s in
        audio_append.append({
            "mediaPoolItem": piano,
            "startFrame": 0,
            "endFrame": min(tl_len + 24, sec_to_frame(90)),
            "mediaType": 2,
            "trackIndex": 2,
            "recordFrame": (start_tc if 'start_tc' in locals() else 0) + sec_to_frame(2),
        })
    if gulls:
        audio_append.append({
            "mediaPoolItem": gulls,
            "startFrame": 0,
            "endFrame": min(tl_len, sec_to_frame(40)),
            "mediaType": 2,
            "trackIndex": 3,
            "recordFrame": (start_tc if 'start_tc' in locals() else 0) + sec_to_frame(6),
        })

    if audio_append:
        try:
            mp.AppendToTimeline(audio_append)
            print("Audio laid out")
        except Exception as e:
            print("Audio append note:", e)
            # fallback simpler
            for a in [ocean, piano, gulls]:
                if a:
                    try:
                        mp.AppendToTimeline([a])
                    except Exception:
                        pass

    # Color page grade
    resolve.OpenPage("color")
    time.sleep(0.5)
    track_count = int(timeline.GetTrackCount("video"))
    for t in range(1, track_count + 1):
        items = timeline.GetItemListInTrack("video", t) or []
        for it in items:
            apply_beauty_cdl(it)
            # Mild retime toward slow-mo feel on key clips (optional)
            try:
                it.SetProperty("RetimeProcess", "Optical Flow")
            except Exception:
                pass
    print("Beauty CDL applied to video clips")

    # End title
    resolve.OpenPage("edit")
    try:
        title = timeline.InsertTitleIntoTimeline("Text+")
        if title:
            # Place near end — best effort
            print("Inserted Text+ title — set text to StillScout in Inspector if needed")
    except Exception as e:
        print("Title insert:", e)

    # Deliver
    os.makedirs(EXPORT, exist_ok=True)
    resolve.OpenPage("deliver")
    project.SetCurrentRenderFormatAndCodec("mp4", "H264")
    project.SetRenderSettings({
        "SelectAllFrames": 1,
        "TargetDir": EXPORT,
        "CustomName": "StillScout_BeforeTheCapture_Resolve",
        "ExportVideo": True,
        "ExportAudio": True,
        "FormatWidth": 2160,
        "FormatHeight": 3840,
        "FrameRate": 24,
        "VideoQuality": 0,  # automatic / best effort
    })
    job = project.AddRenderJob()
    print("Render job:", job)
    if job:
        project.StartRendering(job)
        while project.IsRenderingInProgress():
            time.sleep(2)
            print("Rendering...")
        print("Render complete ->", EXPORT)
        project.DeleteAllRenderJobs()

    pm.SaveProject()
    print("DONE — open Color page to refine skin further; Fairlight to balance audio.")


if __name__ == "__main__":
    main()
