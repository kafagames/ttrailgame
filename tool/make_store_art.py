"""Launcher icon layers and Play Store graphics for Thimble Trail.
Run from the project root:  python tool/make_store_art.py
Writes assets/icon/*.png (for flutter_launcher_icons) and store/*.png."""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
import make_art as art  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), '..')
ICON = os.path.join(ROOT, 'assets', 'icon')
STORE = os.path.join(ROOT, 'store')
os.makedirs(ICON, exist_ok=True)
os.makedirs(STORE, exist_ok=True)
FONT = os.path.join(ROOT, 'assets', 'fonts', 'JosefinSlab-Bold.ttf')
FONT_SEMI = os.path.join(ROOT, 'assets', 'fonts', 'JosefinSlab-SemiBold.ttf')
MUSLIN = (243, 234, 219)
WALNUT = (59, 47, 40)


def foreground(size=1024):
    """Logo mark filling the canvas edge to edge; the icon tool adds the
    adaptive-icon inset itself, so no padding here. Soft radial glow only."""
    mark = art.logo_mark(size)
    glow = Image.new('L', (size, size), 0)
    ImageDraw.Draw(glow).ellipse((size * .12, size * .12, size * .88, size * .88), fill=90)
    glow = glow.filter(ImageFilter.GaussianBlur(size * 0.12))
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    out.paste((255, 248, 232, 255), (0, 0), glow)
    out.alpha_composite(mark)
    # Crop the empty margin so the mark uses the full safe zone.
    bbox = mark.getbbox()
    pad = int(size * 0.06)
    box = (max(0, bbox[0] - pad), max(0, bbox[1] - pad), min(size, bbox[2] + pad), min(size, bbox[3] + pad))
    side = max(box[2] - box[0], box[3] - box[1])
    cx, cy = (box[0] + box[2]) // 2, (box[1] + box[3]) // 2
    crop = out.crop((cx - side // 2, cy - side // 2, cx + side // 2, cy + side // 2))
    return crop.resize((size, size), Image.LANCZOS)


def full_icon(size=1024):
    bg = Image.new('RGBA', (size, size), MUSLIN + (255,))
    tex = art.muslin(256).resize((size, size), Image.LANCZOS).convert('RGBA')
    bg = Image.blend(bg, tex, 0.6)
    fg = foreground(size)
    inset = int(size * 0.06)
    fg = fg.resize((size - inset * 2, size - inset * 2), Image.LANCZOS)
    bg.alpha_composite(fg, (inset, inset))
    return bg


def feature_graphic():
    w, h = 1024, 500
    wall = art.wall(1080, 1920).crop((0, 140, 1080, 140 + 528)).resize((w, int(528 * w / 1080)))
    img = wall.crop((0, 0, w, h)).convert('RGBA')
    # A strip of finished quilt blocks across the right side.
    tiles = [art.fabric_rose(256), art.fabric_sage(256), art.fabric_chambray(256),
             art.fabric_mustard(256), art.fabric_plum(256)]
    block = 92
    ox, oy = 560, 92
    shadow = Image.new('L', (w, h), 0)
    ImageDraw.Draw(shadow).rectangle((ox + 8, oy + 14, ox + block * 4 + 20, oy + block * 4 + 26), fill=140)
    img.paste((48, 30, 18, 255), (0, 0), shadow.filter(ImageFilter.GaussianBlur(16)))
    d = ImageDraw.Draw(img)
    d.rectangle((ox - 8, oy - 8, ox + block * 4 + 8, oy + block * 4 + 8), fill=(158, 90, 85))
    mus = art.muslin(256).resize((block, block))
    for r in range(4):
        for c in range(4):
            x, y = ox + c * block, oy + r * block
            img.paste(mus, (x, y))
            t = tiles[(r * 4 + c) % 5].resize((block, block))
            m = Image.new('L', (block, block), 0)
            md = ImageDraw.Draw(m)
            k = (r + c) % 3
            if k == 0:
                md.polygon([(0, 0), (block, 0), (block, block)], fill=255)
            elif k == 1:
                md.rectangle((0, 0, block // 2, block // 2), fill=255)
                md.rectangle((block // 2, block // 2, block, block), fill=255)
            else:
                md.polygon([(0, block), (block // 2, 0), (block, block)], fill=255)
            img.paste(t, (x, y), m)
            d.rectangle((x, y, x + block, y + block), outline=(120, 96, 80), width=1)
    # Stitched trail across the quilt.
    pts = [(ox + 20, oy + 46), (ox + 2 * block + 46, oy + 46), (ox + 2 * block + 46, oy + 3 * block + 46),
           (ox + 4 * block - 20, oy + 3 * block + 46)]
    for a, b in zip(pts, pts[1:]):
        steps = int(max(abs(b[0] - a[0]), abs(b[1] - a[1])) / 18)
        for i in range(steps):
            t0, t1 = i / steps, (i + 0.55) / steps
            d.line(((a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0),
                    (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1)), fill=WALNUT, width=6)
    sp = art.spool(150).resize((96, 96))
    img.alpha_composite(sp, (pts[0][0] - 56, pts[0][1] - 52))
    th = art.thimble(150).resize((90, 90))
    img.alpha_composite(th, (pts[-1][0] - 30, pts[-1][1] - 50))
    # Title.
    title = ImageFont.truetype(FONT, 76)
    sub = ImageFont.truetype(FONT_SEMI, 30)
    d.text((56, 170), 'Thimble', font=title, fill=WALNUT)
    d.text((56, 250), 'Trail', font=title, fill=WALNUT)
    d.text((60, 352), 'A cozy quilt puzzle', font=sub, fill=(110, 94, 81))
    return img.convert('RGB')


if __name__ == '__main__':
    foreground().save(os.path.join(ICON, 'foreground.png'))
    full_icon().save(os.path.join(ICON, 'icon.png'))
    full_icon(512).convert('RGB').save(os.path.join(STORE, 'icon-512.png'))
    feature_graphic().save(os.path.join(STORE, 'feature-graphic.png'))
    print('icon + store art written')
