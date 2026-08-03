# StillScout in DaVinci Resolve

You have **DaVinci Resolve Lite (Mac App Store)**. Outside automation cannot talk to it until Local scripting is enabled.

## One-time setup (required)

1. Open **DaVinci Resolve** (already launched)
2. Menu: **DaVinci Resolve → Preferences…** (⌘,)
3. Go to **System → General**
4. Set **External scripting using** → **Local**
5. Click **Save**
6. Tell me “scripting on” — I’ll run the build immediately

## What’s already installed

- Script: **Workspace → Scripts → StillScout_BuildFilm**
- Timeline XML: `film/resolve/StillScout_BeforeTheCapture.fcpxml`
- Audio copies: `DaVinci Resolve Media/StillScout/audio/`
- Footage: `Downloads/New Folder With Items`

## What the Resolve script does

Creates project **StillScout_BeforeTheCapture**, builds the creative cut (notebook → face → harbor → sky → phone → brand), applies a soft beauty CDL grade, lays ocean + piano, renders vertical 4K to `film/export/`.
