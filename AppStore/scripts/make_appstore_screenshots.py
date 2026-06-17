#!/usr/bin/env python3
"""Build polished App Store screenshots from real app UI captures."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "screenshots" / "iphone-6.5"
OUTPUT_DIR = ROOT / "screenshots" / "iphone-6.5-v2"

CANVAS_SIZE = (1242, 2688)
PHONE_FRAME = (146, 588, 950, 2028)
FRAME_RADIUS = 108
SCREEN_INSET = 28
SCREEN_RADIUS = 82

FONT_REGULAR = Path("/System/Library/Fonts/Supplemental/Arial.ttf")
FONT_BOLD = Path("/System/Library/Fonts/Supplemental/Arial Bold.ttf")

NAVY = (9, 28, 59)
BLUE = (16, 117, 255)
SOFT_BLUE = (230, 239, 255)
TEXT_SECONDARY = (93, 105, 122)
FRAME_BORDER = (11, 35, 75)
WHITE = (255, 255, 255)


@dataclass(frozen=True)
class ScreenshotSpec:
    source: str
    output: str
    title: str
    subtitle: str
    chip: str


SPECS = [
    ScreenshotSpec(
        "01_projects.png",
        "01_projects.png",
        "כל הפרויקטים במקום אחד",
        "ניהול בדיקות ודוחות בצורה מסודרת",
        "פרויקטים",
    ),
    ScreenshotSpec(
        "02_capture.png",
        "02_capture.png",
        "תיעוד ליקויים בשטח",
        "צלם, מיין והוסף הערות לכל תמונה",
        "תמונות",
    ),
    ScreenshotSpec(
        "03_annotate.png",
        "03_annotate.png",
        "סימון ברור על גבי התמונה",
        "חצים, עיגולים וסימון חופשי לתיעוד מדויק",
        "סימון",
    ),
    ScreenshotSpec(
        "04_export.png",
        "04_export.png",
        "ייצוא דוח מקצועי",
        "קבצי וורד או פי-די-אף מוכנים לשיתוף",
        "ייצוא",
    ),
    ScreenshotSpec(
        "05_branding.png",
        "05_branding.png",
        "מיתוג מלא של החברה",
        "לוגו, פרטי קשר וחתימה בדוח הסופי",
        "מיתוג",
    ),
    ScreenshotSpec(
        "06_login.png",
        "06_login.png",
        "כניסה מאובטחת למערכת",
        "סביבת עבודה מסודרת לצוותי בדק ודוחות",
        "גישה",
    ),
]


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_BOLD if bold else FONT_REGULAR), size=size)


def draw_rtl_text(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int],
    text: str,
    fill: tuple[int, int, int],
    size: int,
    bold: bool = False,
    anchor: str = "ra",
) -> None:
    kwargs = {"font": font(size, bold), "fill": fill, "anchor": anchor}
    try:
        draw.text(xy, text, direction="rtl", language="he", **kwargs)
    except Exception:
        draw.text(xy, text[::-1], **kwargs)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def make_background() -> Image.Image:
    width, height = CANVAS_SIZE
    image = Image.new("RGB", CANVAS_SIZE, (248, 251, 255))
    pixels = image.load()
    for y in range(height):
        t = y / (height - 1)
        r = round(247 + 7 * t)
        g = round(251 + 2 * t)
        b = round(255 - 4 * t)
        for x in range(width):
            pixels[x, y] = (r, g, b)

    overlay = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    odraw = ImageDraw.Draw(overlay)
    odraw.ellipse((-230, 330, 360, 920), fill=(31, 128, 255, 24))
    odraw.ellipse((870, 210, 1420, 820), fill=(9, 28, 59, 14))
    odraw.rectangle((0, 0, width, 18), fill=BLUE + (255,))
    return Image.alpha_composite(image.convert("RGBA"), overlay).convert("RGB")


def paste_phone(canvas: Image.Image, screenshot: Image.Image) -> None:
    frame_x, frame_y, frame_w, frame_h = PHONE_FRAME
    screen_x = frame_x + SCREEN_INSET
    screen_y = frame_y + SCREEN_INSET
    screen_w = frame_w - SCREEN_INSET * 2
    screen_h = frame_h - SCREEN_INSET * 2

    shadow = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle(
        (frame_x + 12, frame_y + 22, frame_x + frame_w + 12, frame_y + frame_h + 22),
        radius=FRAME_RADIUS,
        fill=(9, 28, 59, 70),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas.alpha_composite(shadow)

    frame_layer = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
    fdraw = ImageDraw.Draw(frame_layer)
    fdraw.rounded_rectangle((0, 0, frame_w - 1, frame_h - 1), radius=FRAME_RADIUS, fill=FRAME_BORDER)
    fdraw.rounded_rectangle(
        (SCREEN_INSET, SCREEN_INSET, frame_w - SCREEN_INSET - 1, frame_h - SCREEN_INSET - 1),
        radius=SCREEN_RADIUS,
        fill=WHITE,
    )
    canvas.alpha_composite(frame_layer, (frame_x, frame_y))

    fitted = screenshot.convert("RGB").resize((screen_w, screen_h), Image.Resampling.LANCZOS).convert("RGBA")
    mask = rounded_mask((screen_w, screen_h), SCREEN_RADIUS)
    canvas.paste(fitted, (screen_x, screen_y), mask)


def draw_header(canvas: Image.Image, spec: ScreenshotSpec) -> None:
    draw = ImageDraw.Draw(canvas)

    chip_w, chip_h = 190, 58
    chip_x = CANVAS_SIZE[0] - 92 - chip_w
    chip_y = 96
    draw.rounded_rectangle((chip_x, chip_y, chip_x + chip_w, chip_y + chip_h), radius=29, fill=SOFT_BLUE)
    draw_rtl_text(draw, (chip_x + chip_w - 32, chip_y + 30), spec.chip, BLUE, 30, bold=True, anchor="ra")

    draw_rtl_text(draw, (CANVAS_SIZE[0] - 92, 230), spec.title, NAVY, 72, bold=True)
    draw_rtl_text(draw, (CANVAS_SIZE[0] - 92, 350), spec.subtitle, TEXT_SECONDARY, 38, bold=False)

    draw.rounded_rectangle((92, 420, CANVAS_SIZE[0] - 92, 432), radius=6, fill=(226, 234, 246))
    draw.rounded_rectangle((CANVAS_SIZE[0] - 310, 420, CANVAS_SIZE[0] - 92, 432), radius=6, fill=BLUE)


def render(spec: ScreenshotSpec) -> None:
    source = Image.open(SOURCE_DIR / spec.source)
    if source.size != CANVAS_SIZE:
        raise ValueError(f"{spec.source} is {source.size}, expected {CANVAS_SIZE}")

    canvas = make_background().convert("RGBA")
    draw_header(canvas, spec)
    paste_phone(canvas, source)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(OUTPUT_DIR / spec.output, optimize=True)


def main() -> None:
    for spec in SPECS:
        render(spec)
    print(f"Generated {len(SPECS)} screenshots in {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
