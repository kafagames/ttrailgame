"""Draws every image the game ships: fabric prints, the workroom wall, table
tops, spool, thimble, button and the logo mark. Pure Pillow + numpy, no
external art. Run from the project root:  python tool/make_art.py"""
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'images')
os.makedirs(OUT, exist_ok=True)

FABRICS = {
    'rose': ((201, 123, 118), (238, 214, 205), (150, 78, 74)),
    'sage': ((143, 174, 139), (226, 234, 216), (92, 124, 92)),
    'chambray': ((111, 141, 174), (214, 224, 236), (68, 94, 128)),
    'mustard': ((217, 166, 70), (246, 230, 190), (164, 116, 36)),
    'plum': ((142, 106, 143), (230, 214, 226), (96, 66, 98)),
}
MUSLIN = (243, 234, 219)
INK = (59, 47, 40)
MAPLE = (201, 162, 122)


def save(img, name):
    img.save(os.path.join(OUT, name), optimize=True)
    print('wrote', name, img.size)


def noise(w, h, scale, seed, octaves=4):
    """Tileable value noise in [0, 1]."""
    rng = np.random.default_rng(seed)
    acc = np.zeros((h, w))
    amp, total = 1.0, 0.0
    for o in range(octaves):
        cells = max(2, int(scale * 2 ** o))
        grid = rng.random((cells, cells))
        ys = np.linspace(0, cells, h, endpoint=False)
        xs = np.linspace(0, cells, w, endpoint=False)
        y0 = ys.astype(int) % cells
        x0 = xs.astype(int) % cells
        y1 = (y0 + 1) % cells
        x1 = (x0 + 1) % cells
        fy = (ys - ys.astype(int))[:, None]
        fx = (xs - xs.astype(int))[None, :]
        fy = fy * fy * (3 - 2 * fy)
        fx = fx * fx * (3 - 2 * fx)
        a = grid[y0][:, x0]
        b = grid[y0][:, x1]
        c = grid[y1][:, x0]
        d = grid[y1][:, x1]
        acc += amp * ((a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy)
        total += amp
        amp *= 0.5
    return acc / total


def weave(img, strength=10, seed=1):
    """Adds a fine cotton weave and slub so prints read as cloth."""
    w, h = img.size
    a = np.asarray(img).astype(float)
    yy, xx = np.mgrid[0:h, 0:w]
    threads = (np.sin(xx * math.pi / 2.0) * np.sin(yy * math.pi / 2.0)) * 0.5
    slub = noise(w, h, 3, seed) - 0.5
    a += (threads * strength + slub * strength * 1.6)[..., None]
    return Image.fromarray(np.clip(a, 0, 255).astype('uint8'))


def tiled_draw(size, draw_fn):
    """Draw on a 3x3 canvas and crop the centre so motifs wrap seamlessly."""
    big = Image.new('RGB', (size * 3, size * 3))
    draw_fn(big, size)
    return big.crop((size, size, size * 2, size * 2))


# ---------------------------------------------------------------- fabrics

def fabric_rose(size=256):
    base, light, dark = FABRICS['rose']
    def fn(img, s):
        d = ImageDraw.Draw(img)
        d.rectangle((0, 0, s * 3, s * 3), fill=base)
        rng = random.Random(3)
        pts = [(rng.random() * s, rng.random() * s) for _ in range(14)]
        for ox in range(3):
            for oy in range(3):
                for (x, y) in pts:
                    cx, cy = x + ox * s, y + oy * s
                    for k in range(5):  # five-petal ditsy flower
                        ang = k * 2 * math.pi / 5 + x
                        px, py = cx + math.cos(ang) * 7, cy + math.sin(ang) * 7
                        d.ellipse((px - 5, py - 5, px + 5, py + 5), fill=light)
                    d.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=(214, 166, 70))
                    lx, ly = cx + 13, cy + 9
                    d.ellipse((lx - 6, ly - 3, lx + 6, ly + 3), fill=(120, 140, 96))
    return weave(tiled_draw(size, fn), 9, 11)


def fabric_sage(size=256):
    base, light, dark = FABRICS['sage']
    img = Image.new('RGB', (size, size), light)
    a = np.asarray(img).astype(float)
    band = size // 8
    yy, xx = np.mgrid[0:size, 0:size]
    vx = ((xx // band) % 2 == 0)
    vy = ((yy // band) % 2 == 0)
    col = np.array(light, float)
    mid = np.array(base, float)
    deep = np.array(dark, float)
    a[:] = col
    a[vx ^ vy] = mid
    a[vx & vy] = deep
    return weave(Image.fromarray(a.astype('uint8')), 12, 12)


def fabric_chambray(size=256):
    base, light, dark = FABRICS['chambray']
    yy, xx = np.mgrid[0:size, 0:size]
    n = noise(size, size, 6, 21)
    warp = np.sin(xx * math.pi) * 0.5 + 0.5
    weft = (np.sin(yy * math.pi * 1.0) * 0.5 + 0.5)
    mix = (warp * 0.55 + weft * 0.25 + n * 0.4)
    mix = (mix - mix.min()) / (mix.max() - mix.min())
    a = np.array(dark, float) * (1 - mix[..., None]) + np.array(light, float) * mix[..., None] * 0.55 \
        + np.array(base, float) * 0.45 * mix[..., None]
    img = Image.fromarray(np.clip(a, 0, 255).astype('uint8'))
    d = ImageDraw.Draw(img)
    for x in range(0, size, size // 4):  # pinstripe
        d.line((x + 6, 0, x + 6, size), fill=light, width=2)
    return weave(img, 6, 13)


def fabric_mustard(size=256):
    base, light, dark = FABRICS['mustard']
    def fn(img, s):
        d = ImageDraw.Draw(img)
        d.rectangle((0, 0, s * 3, s * 3), fill=base)
        step = s // 6
        for row in range(18):
            for col in range(18):
                x = col * step + (step // 2 if row % 2 else 0)
                y = row * step
                d.ellipse((x - 6, y - 6, x + 6, y + 6), fill=light)
    return weave(tiled_draw(size, fn), 9, 14)


def fabric_plum(size=256):
    base, light, dark = FABRICS['plum']
    def fn(img, s):
        d = ImageDraw.Draw(img)
        d.rectangle((0, 0, s * 3, s * 3), fill=base)
        rng = random.Random(9)
        sprigs = [(rng.random() * s, rng.random() * s, rng.random() * math.pi) for _ in range(9)]
        for ox in range(3):
            for oy in range(3):
                for (x, y, a) in sprigs:
                    cx, cy = x + ox * s, y + oy * s
                    ex, ey = cx + math.cos(a) * 22, cy + math.sin(a) * 22
                    d.line((cx, cy, ex, ey), fill=light, width=2)
                    for t in (0.35, 0.65, 0.95):
                        px, py = cx + (ex - cx) * t, cy + (ey - cy) * t
                        for side in (-1, 1):
                            la = a + side * 0.9
                            qx, qy = px + math.cos(la) * 7, py + math.sin(la) * 7
                            d.line((px, py, qx, qy), fill=light, width=4)
                    d.ellipse((ex - 3, ey - 3, ex + 3, ey + 3), fill=(232, 196, 120))
    return weave(tiled_draw(size, fn), 9, 15)


def muslin(size=256):
    n = noise(size, size, 4, 31)
    a = np.array(MUSLIN, float)[None, None, :] + ((n - 0.5) * 14)[..., None]
    img = Image.fromarray(np.clip(a, 0, 255).astype('uint8'))
    return weave(img, 7, 32)


def batting(size=256):
    """Puffy quilted padding: diamond channels with soft shading."""
    yy, xx = np.mgrid[0:size, 0:size].astype(float)
    p = size / 2
    u = np.abs(((xx + yy) % p) - p / 2) / (p / 2)
    v = np.abs(((xx - yy) % p) - p / 2) / (p / 2)
    puff = np.minimum(u, v)
    light = 0.82 + 0.18 * np.sqrt(np.clip(1 - puff, 0, 1))
    n = noise(size, size, 5, 41)
    base = np.array((222, 210, 192), float)
    a = base[None, None, :] * light[..., None] + ((n - 0.5) * 10)[..., None]
    img = Image.fromarray(np.clip(a, 0, 255).astype('uint8'))
    return weave(img, 5, 42)


# ---------------------------------------------------------------- scenes

def wood(w, h, base, seed, grain=0.55, planks=0):
    n = noise(w, h, 3, seed)
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    rings = np.sin((xx * 0.012 + n * 9.0) * math.pi * 2) * 0.5 + 0.5
    fine = noise(w, h, 40, seed + 1, 2)
    shade = 0.82 + rings * 0.12 * grain + (fine - 0.5) * 0.12
    a = np.array(base, float)[None, None, :] * shade[..., None]
    img = Image.fromarray(np.clip(a, 0, 255).astype('uint8'))
    if planks:
        d = ImageDraw.Draw(img)
        for i in range(1, planks):
            x = i * w // planks
            d.line((x, 0, x, h), fill=tuple(int(c * 0.62) for c in base), width=3)
            d.line((x + 3, 0, x + 3, h), fill=tuple(min(255, int(c * 1.08)) for c in base), width=1)
    return img


def wall(w=1080, h=1920):
    n = noise(w, h, 6, 51)
    plaster = np.array((238, 226, 206), float)
    a = plaster[None, None, :] + ((n - 0.5) * 18)[..., None]
    img = Image.fromarray(np.clip(a, 0, 255).astype('uint8')).convert('RGBA')
    # Window light: a soft parallelogram falling from the upper left.
    light = Image.new('L', (w, h), 0)
    ld = ImageDraw.Draw(light)
    ld.polygon([(-200, 120), (520, 60), (1180, 1260), (300, 1420)], fill=70)
    light = light.filter(ImageFilter.GaussianBlur(120))
    warm = Image.new('RGBA', (w, h), (255, 240, 205, 255))
    img = Image.composite(warm, img, light)
    # Wainscot below.
    top = int(h * 0.80)
    panel = wood(w, h - top, (150, 108, 76), 52, planks=6).convert('RGBA')
    img.paste(panel, (0, top))
    d = ImageDraw.Draw(img)
    d.rectangle((0, top - 22, w, top), fill=(120, 84, 58))
    d.rectangle((0, top - 22, w, top - 16), fill=(170, 128, 92))
    # Peg rail the quilt hangs from.
    rail_y = int(h * 0.105)
    d.rectangle((40, rail_y, w - 40, rail_y + 26), fill=(132, 94, 64))
    d.rectangle((40, rail_y, w - 40, rail_y + 6), fill=(176, 134, 96))
    for px in (130, w // 2, w - 130):
        d.ellipse((px - 20, rail_y - 6, px + 20, rail_y + 34), fill=(108, 76, 52))
        d.ellipse((px - 12, rail_y + 2, px + 8, rail_y + 18), fill=(150, 110, 78))
    # Soft shadow under the rail.
    sh = Image.new('L', (w, h), 0)
    ImageDraw.Draw(sh).rectangle((40, rail_y + 26, w - 40, rail_y + 46), fill=60)
    sh = sh.filter(ImageFilter.GaussianBlur(10))
    img = Image.composite(Image.new('RGBA', (w, h), (80, 60, 40, 255)), img, sh)
    return img.convert('RGB')


def table(kind, w=1080, h=1920):
    if kind == 'maple':
        return wood(w, h, MAPLE, 61, planks=4)
    if kind == 'walnut':
        return wood(w, h, (112, 78, 56), 62, grain=0.8, planks=4)
    if kind == 'gingham':
        img = Image.new('RGB', (w, h), (240, 228, 214))
        a = np.asarray(img).astype(float)
        yy, xx = np.mgrid[0:h, 0:w]
        band = 60
        vx = (xx // band) % 2 == 0
        vy = (yy // band) % 2 == 0
        a[vx ^ vy] = (214, 150, 140)
        a[vx & vy] = (182, 104, 98)
        return weave(Image.fromarray(a.astype('uint8')), 10, 63)
    if kind == 'indigo':
        n = noise(w, h, 5, 64)
        base = np.array((44, 58, 92), float)
        a = base[None, None, :] * (0.85 + n * 0.25)[..., None]
        img = Image.fromarray(np.clip(a, 0, 255).astype('uint8'))
        d = ImageDraw.Draw(img)
        rng = random.Random(64)
        for _ in range(140):  # sashiko-like running stitch crosses
            x, y = rng.randrange(w), rng.randrange(h)
            for k in range(-2, 3):
                d.line((x + k * 14, y, x + k * 14 + 7, y), fill=(214, 222, 236), width=2)
        return weave(img, 6, 65)
    raise ValueError(kind)


# ---------------------------------------------------------------- objects

def spool(size=384):
    s = size
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Shadow
    sh = Image.new('L', (s, s), 0)
    ImageDraw.Draw(sh).ellipse((s * .16, s * .78, s * .9, s * .96), fill=110)
    img.paste((40, 28, 20, 255), (0, 0), sh.filter(ImageFilter.GaussianBlur(14)))
    d = ImageDraw.Draw(img)
    wood_c, wood_d, wood_l = (196, 150, 104), (140, 100, 64), (226, 190, 146)
    # Bottom flange
    d.ellipse((s * .14, s * .70, s * .86, s * .88), fill=wood_d)
    d.rectangle((s * .14, s * .70, s * .86, s * .79), fill=wood_d)
    d.ellipse((s * .14, s * .62, s * .86, s * .80), fill=wood_c)
    # Thread core with wound lines (rose thread).
    core = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    cd = ImageDraw.Draw(core)
    cd.rectangle((s * .24, s * .26, s * .76, s * .72), fill=(190, 108, 102))
    for i in range(46):
        y = s * .27 + i * (s * .44 / 46)
        shade = 150 + int(40 * math.sin(i * 0.9))
        cd.line((s * .24, y, s * .76, y + 3), fill=(shade + 50, shade - 40, shade - 46), width=2)
    # Cylinder shading
    grad = Image.new('L', (s, s), 0)
    gd = ImageDraw.Draw(grad)
    for x in range(int(s * .24), int(s * .76)):
        t = (x - s * .24) / (s * .52)
        gd.line((x, 0, x, s), fill=int(120 * (abs(t - 0.32) ** 1.3)))
    core.paste((40, 16, 14, 255), (0, 0), Image.composite(grad, Image.new('L', (s, s), 0), core.split()[3]))
    img.alpha_composite(core)
    d = ImageDraw.Draw(img)
    # Top flange
    d.ellipse((s * .14, s * .18, s * .86, s * .36), fill=wood_d)
    d.ellipse((s * .14, s * .14, s * .86, s * .32), fill=wood_c)
    d.ellipse((s * .2, s * .16, s * .62, s * .26), fill=wood_l)
    d.ellipse((s * .44, s * .2, s * .56, s * .26), fill=(92, 64, 40))
    # Loose thread tail
    pts = [(s * .76, s * .45), (s * .86, s * .5), (s * .9, s * .62), (s * .96, s * .7)]
    d.line(pts, fill=(190, 108, 102), width=4, joint='curve')
    return img


def thimble(size=384):
    s = size
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    sh = Image.new('L', (s, s), 0)
    ImageDraw.Draw(sh).ellipse((s * .2, s * .78, s * .86, s * .94), fill=110)
    img.paste((40, 28, 20, 255), (0, 0), sh.filter(ImageFilter.GaussianBlur(14)))
    body = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    bd.polygon([(s * .3, s * .22), (s * .7, s * .22), (s * .8, s * .82), (s * .2, s * .82)], fill=(184, 135, 58))
    bd.ellipse((s * .3, s * .1, s * .7, s * .34), fill=(184, 135, 58))
    bd.ellipse((s * .2, s * .74, s * .8, s * .9), fill=(150, 104, 40))
    # Metallic falloff (real light on brass).
    a = np.asarray(body).astype(float)
    xs = np.linspace(0, 1, s)[None, :]
    light = 0.65 + 0.7 * np.exp(-((xs - 0.38) ** 2) / 0.012) + 0.15 * np.exp(-((xs - 0.75) ** 2) / 0.004)
    a[..., :3] *= light[..., None]
    body = Image.fromarray(np.clip(a, 0, 255).astype('uint8'))
    bd = ImageDraw.Draw(body)
    # Dimples
    for row in range(7):
        y = s * .2 + row * s * .075
        half = (s * .2 + row * s * .013)
        n = 6 + row
        for k in range(n):
            x = s / 2 - half + (k + .5) * (2 * half / n)
            r = s * .014
            bd.ellipse((x - r, y - r, x + r, y + r), fill=(110, 76, 30))
    bd.ellipse((s * .2, s * .76, s * .8, s * .86), outline=(232, 196, 120), width=4)
    img.alpha_composite(body)
    return img


def button(size=256):
    s = size
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    sh = Image.new('L', (s, s), 0)
    ImageDraw.Draw(sh).ellipse((s * .14, s * .18, s * .92, s * .96), fill=120)
    img.paste((40, 28, 20, 255), (0, 0), sh.filter(ImageFilter.GaussianBlur(10)))
    d = ImageDraw.Draw(img)
    d.ellipse((s * .1, s * .1, s * .88, s * .88), fill=(236, 226, 206))
    d.ellipse((s * .18, s * .18, s * .8, s * .8), fill=(222, 208, 184))
    d.ellipse((s * .1, s * .1, s * .88, s * .88), outline=(170, 150, 120), width=5)
    for (x, y) in ((.4, .4), (.58, .4), (.4, .58), (.58, .58)):
        r = s * .045
        d.ellipse((s * x - r, s * y - r, s * x + r, s * y + r), fill=(120, 100, 80))
    d.line((s * .4, s * .4, s * .58, s * .58), fill=(190, 108, 102), width=6)
    d.line((s * .58, s * .4, s * .4, s * .58), fill=(190, 108, 102), width=6)
    d.arc((s * .16, s * .16, s * .7, s * .7), 200, 280, fill=(252, 246, 232), width=6)
    return img


def logo_mark(size=1024, bg=None):
    """Four patches (rose, sage, chambray, mustard) with a stitched trail
    running from a tiny spool to a thimble. Used for icon and splash."""
    s = size
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0) if bg is None else bg)
    tiles = {'rose': fabric_rose(256), 'sage': fabric_sage(256),
             'chambray': fabric_chambray(256), 'mustard': fabric_mustard(256)}
    cell = int(s * 0.36)
    ox = oy = (s - cell * 2) // 2
    order = [('rose', 0, 0), ('sage', 1, 0), ('mustard', 0, 1), ('chambray', 1, 1)]
    sh = Image.new('L', (s, s), 0)
    ImageDraw.Draw(sh).rounded_rectangle((ox + 14, oy + 30, ox + cell * 2 + 14, oy + cell * 2 + 30), 40, fill=150)
    img.paste((40, 28, 20, 255), (0, 0), sh.filter(ImageFilter.GaussianBlur(28)))
    for name, cx, cy in order:
        t = tiles[name].resize((cell, cell), Image.LANCZOS)
        img.paste(t, (ox + cx * cell, oy + cy * cell))
    d = ImageDraw.Draw(img)
    # Seams
    d.line((ox + cell, oy, ox + cell, oy + cell * 2), fill=(250, 244, 230), width=6)
    d.line((ox, oy + cell, ox + cell * 2, oy + cell), fill=(250, 244, 230), width=6)
    # Stitched trail: an S through the four patches.
    pts = []
    for i in range(80):
        t = i / 79
        x = ox + cell * 0.35 + t * cell * 1.3
        y = oy + cell * (0.45 + 1.1 * (0.5 - 0.5 * math.cos(t * math.pi)))
        pts.append((x, y))
    for i in range(0, len(pts) - 3, 5):
        d.line((pts[i], pts[i + 3]), fill=INK, width=int(s * 0.018))
    # Thimble cap at the end, spool hole at the start.
    ex, ey = pts[-1]
    r = s * 0.06
    d.ellipse((ex - r, ey - r, ex + r, ey + r), fill=(184, 135, 58), outline=(120, 84, 30), width=6)
    sx, sy = pts[0]
    r2 = s * 0.05
    d.ellipse((sx - r2, sy - r2, sx + r2, sy + r2), fill=(196, 150, 104), outline=(110, 76, 48), width=6)
    d.ellipse((sx - r2 * .35, sy - r2 * .35, sx + r2 * .35, sy + r2 * .35), fill=(92, 64, 40))
    return img


if __name__ == '__main__':
    makers = {'rose': fabric_rose, 'sage': fabric_sage, 'chambray': fabric_chambray,
              'mustard': fabric_mustard, 'plum': fabric_plum}
    for name, fn in makers.items():
        save(fn(256), f'fabric_{name}.png')
    save(muslin(256), 'muslin.png')
    save(batting(256), 'batting.png')
    save(wall(), 'wall.png')
    for k in ('maple', 'walnut', 'gingham', 'indigo'):
        save(table(k), f'table_{k}.png')
    save(spool(), 'spool.png')
    save(thimble(), 'thimble.png')
    save(button(), 'button.png')
    save(logo_mark(1024), 'logo.png')
