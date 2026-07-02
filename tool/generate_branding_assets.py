#!/usr/bin/env python3
"""Generate StillScout launcher icons (gold viewfinder on void black)."""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ACCENT = (232, 201, 122)
VOID = (5, 5, 5)
SLATE = (28, 28, 30)

SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

# iOS AppIcon.appiconset — filename -> pixel size. iOS icons must be fully
# opaque (no alpha channel) or App Store validation flags them.
IOS_ICON_SIZES = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}

# iOS LaunchImage.imageset — the storyboard centers this at 168x185pt.
IOS_LAUNCH_IMAGE_SIZES = {
    "LaunchImage.png": 1,
    "LaunchImage@2x.png": 2,
    "LaunchImage@3x.png": 3,
}
LAUNCH_IMAGE_POINT_SIZE = (168, 185)


def _draw_glyph(img: Image.Image, size: int) -> None:
    """Draws the viewfinder + reticle glyph onto `img` in place."""
    draw = ImageDraw.Draw(img)
    pad = size * 0.14
    corner = size * 0.22
    stroke = max(2, size // 24)

    # Subtle inner vignette
    draw.ellipse(
        (pad, pad, size - pad, size - pad),
        outline=(232, 201, 122, 40),
        width=max(1, stroke // 2),
    )

    # Viewfinder corners
    for x0, y0, x1, y1 in [
        (pad, pad, pad + corner, pad + stroke),
        (pad, pad, pad + stroke, pad + corner),
        (size - pad - corner, pad, size - pad, pad + stroke),
        (size - pad - stroke, pad, size - pad, pad + corner),
        (pad, size - pad - stroke, pad + corner, size - pad),
        (pad, size - pad - corner, pad + stroke, size - pad),
        (size - pad - corner, size - pad - stroke, size - pad, size - pad),
        (size - pad - stroke, size - pad - corner, size - pad, size - pad),
    ]:
        draw.rectangle((x0, y0, x1, y1), fill=ACCENT)

    # Center reticle dot
    r = size * 0.055
    cx = cy = size / 2
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=ACCENT)

    # Scout sparkle
    spark_r = size * 0.028
    sx = size * 0.68
    sy = size * 0.30
    draw.ellipse((sx - spark_r, sy - spark_r, sx + spark_r, sy + spark_r), fill=ACCENT)


def draw_icon(size: int) -> Image.Image:
    """Full-bleed square icon — void-black backdrop, for app launcher icons."""
    img = Image.new("RGBA", (size, size), VOID)
    _draw_glyph(img, size)
    return img


def draw_logomark(size: int) -> Image.Image:
    """Same glyph on a transparent backdrop, for contexts that already
    supply their own background (e.g. the iOS launch screen)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    _draw_glyph(img, size)
    return img


def main() -> None:
    assets = ROOT / "assets" / "branding"
    assets.mkdir(parents=True, exist_ok=True)

    master = draw_icon(512)
    master.save(assets / "app_icon.png")

    for folder, px in SIZES.items():
        out_dir = ROOT / "android" / "app" / "src" / "main" / "res" / folder
        out_dir.mkdir(parents=True, exist_ok=True)
        icon = draw_icon(px)
        icon.save(out_dir / "ic_launcher.png")
        icon.save(out_dir / "ic_launcher_round.png")

    # iOS app icons must be fully opaque (RGB, no alpha channel) or App
    # Store validation flags them.
    ios_icon_dir = (
        ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    )
    for filename, px in IOS_ICON_SIZES.items():
        draw_icon(px).convert("RGB").save(ios_icon_dir / filename)

    # iOS launch screen — transparent logomark centered over the
    # storyboard's own void-black background (see LaunchScreen.storyboard).
    launch_dir = (
        ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
    )
    for filename, scale in IOS_LAUNCH_IMAGE_SIZES.items():
        w = LAUNCH_IMAGE_POINT_SIZE[0] * scale
        h = LAUNCH_IMAGE_POINT_SIZE[1] * scale
        canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        glyph_size = min(w, h)
        glyph = draw_logomark(glyph_size)
        canvas.paste(glyph, ((w - glyph_size) // 2, (h - glyph_size) // 2), glyph)
        canvas.save(launch_dir / filename)

    print("Generated StillScout branding assets (Android + iOS).")


if __name__ == "__main__":
    main()
