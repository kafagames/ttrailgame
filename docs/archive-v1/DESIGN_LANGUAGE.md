# Patchwork Path — Design Language

Visual system for a sunlit grandmother's quilt workroom. Everything is drawn in code — shapes, gradients, stitches, motion — plus Material Icons and bundled **Josefin Slab** typography. No image, sprite, audio, or animation files.

---

## Vibe

**Warm, tactile, unhurried.** The player should feel fabric under their fingers: soft edges, stitched borders, calico colors, wood and linen surfaces. Motion is gentle — slides, fades, and single pulses — never arcade-snappy. The workroom is quiet and safe.

---

## Color palette

Derived from muslin, calico prints, thread spools, and a wooden cutting table.

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| Background (wall) | Muslin Cream | `#F5EDE0` | Workroom walls, splash base |
| Background (surface) | Table Maple | `#C4A882` | Cutting table, tray base |
| Background (card) | Ledger Paper | `#FFFBF5` | Overlays, guide pages |
| Primary | Thread Rose | `#C87B7B` | Primary actions, Rail Patch default |
| Secondary | Calico Sage | `#7A9E7E` | Secondary patches, success accents |
| Accent | Denim Blue | `#6B8CAE` | Corner Patch default, links |
| Highlight | Golden Thread | `#D4A056` | Stars, selection glow, par indicator |
| Batting | Warm Gray Fill | `#E8DFD4` | Blocked cells cross-hatch base |
| Frame | Workroom Walnut | `#6B5344` | Quilt frame, wooden borders |
| Text primary | Warm Charcoal | `#3D3632` | Headings, body |
| Text secondary | Soft Taupe | `#7A7168` | Subtitles, hints |
| Error (mild) | Amber Snip | `#C9924A` | Tangled state (never harsh red) |
| Path win pulse | Bind Gold | `#E8C468` | Win animation along path |

### Patch fill colors (level-assigned)

Use slightly muted calico tones at ~85% opacity on cells:

- Rose `#D4A0A0`, Sage `#9BB89E`, Blue `#94AEC8`, Lavender `#B8A8C8`, Butter `#E8D4A0`

Draw each patch with a 2-stop linear gradient (top-left lighter → bottom-right darker) for a folded-fabric feel.

### Grid cell states

| State | Fill | Border |
|-------|------|--------|
| Empty | `#FFFBF5` | 1 px dashed `#D4C4B0` (stitch dash) |
| Batting | cross-hatch `#E8DFD4` | solid `#C4B8A8` |
| Spool | radial gold `#D4A056` | 2 px solid Walnut |
| Thimble | radial silver `#B8B8C0` | 2 px solid Walnut |
| Fixed patch | calico gradient | 2 px dashed `#6B5344` outer stitch |
| Placed patch | calico gradient | 2 px solid `#3D3632` |
| Selected target | — | 2 px glow `#D4A056` |

---

## Typography

**Font:** [Josefin Slab](https://fonts.google.com/specimen/Josefin+Slab) — geometric slab serif with a vintage craft-shop feel. **Do not use Fredoka.**

### Bundling (offline)

Download and bundle under `assets/fonts/`:

- `JosefinSlab-Regular.ttf` (400)
- `JosefinSlab-SemiBold.ttf` (600)
- `JosefinSlab-Bold.ttf` (700)

Declare in `pubspec.yaml`:

```yaml
fonts:
  - family: JosefinSlab
    fonts:
      - asset: assets/fonts/JosefinSlab-Regular.ttf
        weight: 400
      - asset: assets/fonts/JosefinSlab-SemiBold.ttf
        weight: 600
      - asset: assets/fonts/JosefinSlab-Bold.ttf
        weight: 700
```

Reference: `fontFamily: 'JosefinSlab'`. Do **not** use runtime `GoogleFonts` fetching.

### Type scale

| Role | Size | Weight | Letter-spacing |
|------|------|--------|----------------|
| App title | 32 sp | 700 | 0.5 |
| Screen title | 24 sp | 600 | 0.3 |
| Card title | 20 sp | 600 | 0.2 |
| Body | 16 sp | 400 | 0 |
| Caption / HUD | 14 sp | 400 | 0.1 |
| Button label | 16 sp | 600 | 0.8 (uppercase optional on primary CTAs) |
| Pattern note ribbon | 13 sp | 600 | 0.2 |

Minimum body size 14 sp on smallest supported phones. Line height 1.4× for body text.

---

## Spacing scale

Base unit **4 dp**. Use multiples consistently:

| Token | Value | Typical use |
|-------|-------|-------------|
| xs | 4 | Icon padding, stitch inset |
| sm | 8 | Inner card padding |
| md | 16 | Standard padding, grid gap |
| lg | 24 | Section separation |
| xl | 32 | Screen edge margins |
| xxl | 48 | Minimum touch target |

**Touch targets:** minimum 48×48 dp for all tappable elements.

**Safe areas:** respect `MediaQuery.padding`; add xl horizontal padding on notched devices.

---

## Layout rules

- **Grid fit:** Gameplay grid scales to fit `(screenWidth - 2×xl)` and `(availableHeight - HUD - tray - 2×md)`, maintaining square cells.
- **Hierarchy:** One focal element per screen (frame on Workroom, grid on Cutting Table, clothesline on Gallery).
- **Alignment:** Menu cards right-aligned to frame; gameplay grid centered; HUD full-width.
- **Depth:** Use soft shadows (`Color(0x403D3632)`, blur 8, offset (0, 2)) for elevated cards and selected patches — never harsh drop shadows.

---

## UI elements

### Fabric button (primary CTA)

- Rounded rect `borderRadius: 12`
- Fill: Thread Rose gradient (top `#D4A0A0` → bottom `#C87B7B`)
- Border: 2 px `#6B5344` "stitched" (optional dashed overlay via `CustomPainter`)
- Label: Josefin Slab 600, Ledger Paper or Warm Charcoal depending on contrast
- Press state: scale 0.97, darken 8%

### Fabric swatch row (secondary / pause actions)

- Full-width, height 52 dp
- Alternating subtle calico tints (Rose/Sage/Blue at 15% opacity)
- Left-aligned label, optional right chevron (Material Icons `chevron_right`)

### Pattern card (Workroom navigation)

- Size ~120×88 dp, `borderRadius: 8`
- Paper fill `#FFFBF5`, 2 px Walnut border
- Offset stack: each card rotated 1–2° and translated 8 dp vertically for fan effect
- Selected/hover: translate forward 4 dp

### Quilt frame (Workroom)

- Outer walnut border 12 dp
- Inner padding md
- Corner accents: small L-shaped stitch marks (4 dp lines) at four corners

### Linen overlay card (pause, complete, fail)

- Width 85% screen, max 400 dp
- Fill Ledger Paper
- Border: dashed stitch `#D4C4B0`, 2 px
- `borderRadius: 16`

### HUD thread dots

- Circle 10 dp diameter, gap sm
- Filled: Golden Thread; empty: `#D4C4B0` outline only

### Stars

- Draw as five-point paths in code (`Path` star), fill Golden Thread
- Empty star: outline only `#D4C4B0`

### Clothesline (Gallery)

- Two parallel bezier curves, stroke 3 px `#6B5344`
- Clothespin: small rotated rectangle 12×6 dp

---

## Motion

| Event | Animation | Duration | Curve |
|-------|-----------|----------|-------|
| Splash thread draw | CustomPainter trim | 1200 ms | easeInOut |
| Screen transition | Fade + slide up 12 dp | 300 ms | easeOutCubic |
| Patch select | Scale 1.0 → 1.05 | 150 ms | easeOut |
| Invalid place | Horizontal shake ±4 dp | 300 ms | elasticOut |
| Win path pulse | Cell fill opacity 0.5→1 loop once | 600 ms | easeInOut |
| Star drop | Translate Y −24→0, fade in | 400 ms each, stagger 150 ms | bounceOut |
| Card press | Translate Y 0→2 | 100 ms | linear |

No particle asset files — win sparkle is 6–8 small circles along the path, fade out over 500 ms, drawn in code.

---

## Icons

Use **Material Icons** only:

| Icon | Use |
|------|-----|
| `pause` | Rest Hands |
| `rotate_right` | Turn Patch |
| `undo` | Rip Last |
| `arrow_back` | Back to Workroom |
| `volume_off` / `volume_up` | Quiet Room sounds |
| `vibration` | Quiet Room haptics |
| `lock_outline` | Locked gallery swatch |

Spool and thimble on grid are **code-drawn** (circle + trapezoid), not icon fonts.

---

## Responsiveness

- Test layout on 360×640 (small) through 412×915 (large phone).
- Workroom frame scales to 90% width on narrow screens; cards stack tighter (sm overlap).
- Gallery clothesline scrolls horizontally; detail panel moves below line on height < 640.
- Grid cell size = `min(availableWidth, availableHeight) / max(gridW, gridH)` floored to nearest even dp for crisp strokes.

---

## Code-drawn graphics checklist

Implement via Flame components and/or Flutter `CustomPainter`:

- [ ] Grid cells with stitch borders
- [ ] Batting cross-hatch
- [ ] Patch shapes (Rail, Corner, Block) with fabric gradient
- [ ] Thread spool and thimble markers
- [ ] Quilt frame and pattern cards
- [ ] Clothesline and clothespins
- [ ] Star shapes
- [ ] Splash needle and thread
- [ ] Win sparkle dots

**Permitted binary files:** Josefin Slab `.ttf` weights + generated launcher icon only.
