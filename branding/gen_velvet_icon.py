"""
Velvet launcher icon generator.

Design intent (locked to v25 design tokens):
- Black void background with subtle radial warm-gold ambient
- Single gold accent (#C9A961) — no other brand color
- Display-grade serif "V" rendered from CormorantGaramond-Medium
- Negative letterspacing on big type → cinematic, not template
- Hairline rule under the glyph (Sanity-style 1px alpha boundary)
- Anti-template: NO emoji, NO multi-color gradient bg, NO drop shadow trio

Outputs:
- /tmp/velvet_icon_master.png        1024x1024 master (Play Store + adaptive fg)
- /tmp/velvet_icon_legacy.png        1024x1024 with rounded mask (legacy launcher)
- /tmp/velvet_icon_fg.png            432x432 adaptive foreground (logo only, transparent bg)
- /tmp/velvet_icon_bg.png            432x432 adaptive background (radial gold ambient)
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math

FONT = "/root/velvet/velvet-flutter/google_fonts/CormorantGaramond-Medium.ttf"
GOLD_HIGHLIGHT = (240, 217, 138)   # 18% stop
GOLD_LIGHT     = (232, 200, 121)   # bright
GOLD           = (201, 169,  97)   # primary accent #C9A961
GOLD_DARK      = (140, 117,  54)   # 8C7536
GOLD_DEEPEST   = ( 74,  46,  10)   # 4A2E0A
BG_VOID        = ( 10,   8,   7)   # Vt.bgVoid
BG_AMBIENT     = ( 26,  20,  16)   # warm near-black at center
HAIRLINE       = (201, 169,  97, 77)  # gold @ 30% alpha

SIZE = 1024


def radial_ambient(size: int, center=(0.5, 0.5), inner=BG_AMBIENT, outer=BG_VOID, falloff=1.4):
    """Soft radial gradient — center warm-charcoal, edge true void."""
    img = Image.new("RGB", (size, size), outer)
    px = img.load()
    cx, cy = center[0] * size, center[1] * size
    max_d = math.hypot(cx, cy)
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - cx, y - cy) / max_d
            t = min(1.0, d ** falloff)
            r = int(inner[0] + (outer[0] - inner[0]) * t)
            g = int(inner[1] + (outer[1] - inner[1]) * t)
            b = int(inner[2] + (outer[2] - inner[2]) * t)
            px[x, y] = (r, g, b)
    return img


def vertical_gold_gradient(w: int, h: int) -> Image.Image:
    """5-stop gold gradient (light top → deep bottom) for ShaderMask-style fill."""
    stops = [
        (0.00, GOLD_HIGHLIGHT),
        (0.18, GOLD_LIGHT),
        (0.50, GOLD),
        (0.82, GOLD_DARK),
        (1.00, GOLD_DEEPEST),
    ]
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        # find segment
        for i in range(len(stops) - 1):
            t0, c0 = stops[i]
            t1, c1 = stops[i + 1]
            if t0 <= t <= t1:
                k = (t - t0) / max(1e-6, (t1 - t0))
                r = int(c0[0] + (c1[0] - c0[0]) * k)
                g = int(c0[1] + (c1[1] - c0[1]) * k)
                b = int(c0[2] + (c1[2] - c0[2]) * k)
                row = (r, g, b)
                break
        for x in range(w):
            px[x, y] = row
    return img


def draw_v_monogram(canvas: Image.Image, with_rule: bool = True, size: int = SIZE):
    """Compose the 'V' glyph with a hairline rule beneath."""
    glyph = "V"
    font_size = int(size * 0.78)
    font = ImageFont.truetype(FONT, font_size)

    # Render glyph in white on transparent — used as a mask for gold gradient
    mask = Image.new("L", (size, size), 0)
    mdraw = ImageDraw.Draw(mask)
    bbox = mdraw.textbbox((0, 0), glyph, font=font)
    gw, gh = bbox[2] - bbox[0], bbox[3] - bbox[1]
    gx = (size - gw) // 2 - bbox[0]
    # Push slightly UP so the V's pointed base sits on the optical baseline above the rule
    gy = (size - gh) // 2 - bbox[1] - int(size * 0.04)
    mdraw.text((gx, gy), glyph, fill=255, font=font)

    # Apply gold gradient through the mask
    grad = vertical_gold_gradient(size, size)
    glyph_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glyph_layer.paste(grad.convert("RGBA"), (0, 0), mask)

    # Subtle inner glow — 1px gold haze around glyph (Ferrari chiaroscuro hint)
    glow = mask.filter(ImageFilter.GaussianBlur(radius=int(size * 0.012)))
    glow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_rgba = (*GOLD_LIGHT, 80)
    Image.new("RGBA", (size, size), glow_rgba).putalpha(glow)
    halo = Image.new("RGBA", (size, size), (*GOLD_LIGHT, 0))
    halo.putalpha(glow)
    halo_solid = Image.new("RGBA", (size, size), GOLD_LIGHT + (255,))
    halo_solid.putalpha(glow)
    canvas.alpha_composite(halo_solid)

    canvas.alpha_composite(glyph_layer)

    if with_rule:
        # Hairline rule under the V — Sanity-style alpha boundary
        rule_y = int(size * 0.86)
        rule_w = int(size * 0.30)
        rule_h = max(1, int(size * 0.0035))
        rule_x = (size - rule_w) // 2
        rdraw = ImageDraw.Draw(canvas)
        rdraw.rectangle(
            [rule_x, rule_y, rule_x + rule_w, rule_y + rule_h],
            fill=HAIRLINE,
        )

    return canvas


def make_master():
    bg = radial_ambient(SIZE).convert("RGBA")
    canvas = bg.copy()
    draw_v_monogram(canvas, with_rule=True, size=SIZE)
    canvas.save("/tmp/velvet_icon_master.png", optimize=True)
    return canvas


def make_legacy_rounded(master: Image.Image):
    """Square master with a soft 22% radius mask for legacy launchers that don't honor adaptive."""
    radius = int(SIZE * 0.22)
    mask = Image.new("L", (SIZE, SIZE), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.rounded_rectangle([0, 0, SIZE, SIZE], radius=radius, fill=255)
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(master, (0, 0), mask)
    out.save("/tmp/velvet_icon_legacy.png", optimize=True)


def make_adaptive():
    """Adaptive icon split — Android crops 108dp foreground inside a safe 66dp circle."""
    # Background (full bleed): radial gold ambient on void
    bg = radial_ambient(432, falloff=1.6).convert("RGBA")
    bg.save("/tmp/velvet_icon_bg.png", optimize=True)

    # Foreground: glyph centered, 25% inner safe-zone padding (Android requirement)
    fg = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    # Render glyph at full 432, then we rely on Android to mask — V already sits at ~62% of frame
    draw_v_monogram(fg, with_rule=False, size=432)
    fg.save("/tmp/velvet_icon_fg.png", optimize=True)


if __name__ == "__main__":
    master = make_master()
    make_legacy_rounded(master)
    make_adaptive()
    print("ok")
