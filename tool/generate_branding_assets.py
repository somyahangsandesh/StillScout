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


def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), VOID)
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

    print("Generated StillScout branding assets.")


if __name__ == "__main__":
    main()
