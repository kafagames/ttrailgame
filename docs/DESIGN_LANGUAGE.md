# Thimble Trail — Design Language

**World:** a grandmother's sewing room on a sunny afternoon. Plaster wall,
wooden peg rail, maple cutting table with a green self-healing mat, real
cotton prints, a wooden spool and a brass thimble. Everything in the UI is
something you could find in that room.

**Audience:** relaxed adult puzzlers, short calm sessions, no timers.

## Composition choices (and why)

| Choice | Why it fits this game |
|--------|----------------------|
| **Hub = one heirloom quilt hanging on the wall**, 6×8 blocks, each block a level | Level select *is* the progress: unsewn blocks are chalked muslin, won blocks are sewn in with a traditional motif. No grid of numbered tiles, no map. |
| Title sits above the peg rail, actions on the wainscot below | Uses the room's own architecture as layout; asymmetric, edge-aligned. |
| Play = a cutting mat on the table, tray as a muslin cloth along the bottom | The board is the hero; the tray reads as fabric waiting to be cut. |
| Primary action = a sewn-in walnut **label tag** with dashed stitching | Like a maker's label; replaces generic buttons. |
| Secondary actions = icon + word, no boxes | Quiet; separated by space, not borders. |
| Overlays = **pattern paper** sheets with a stitched edge | Result, pause and chapter notes feel like dressmaker's pattern paper. |

## Palette — every colour has a job

| Token | Hex | Job |
|-------|-----|-----|
| `muslin` | #F3EADB | Page, unsewn squares, tray cloth |
| `plaster` | #E6DACA | Quiet surfaces, unearned stars |
| `walnut` | #3B2F28 | Text, icons, stitches, label tag |
| `thread` | #6E5E51 | Secondary text (4.6:1 on muslin) |
| `brass` / `brassDeep` | #B8873A / #8A6224 | Rewards only: stars, ribbons, hints, selection underline |
| `redThread` | #A2463E | The single warning: refused placement, seam clash, destructive reset |
| `mat` / `matLine` | #55745F / #7E9A86 | Cutting mat under the board, switch track |
| `binding` | #9E5A55 | Quilt binding and hanging tabs on the hub |
| Fabrics | rose #C97B76 · sage #8FAE8B · chambray #6F8DAE · mustard #D9A646 · plum #8E6A8F | Only ever on fabric (prints come from `assets/images/fabric_*.png`) |

Gradients appear only as real light: the window light on the wall, the
brass falloff on the thimble, the subtle top-light on each patch.

## Type

**Josefin Slab** (OFL, bundled, static 400/600/700 cut from the variable
font). Slab serifs echo typewritten pattern envelopes. Display 30–40/700,
title 20–24/700, label 17/600, body 17/400 at 1.4 line height, small
14.5/600 in `thread`. Tabular figures in the Ledger.

## Icons

Own glyph set (`lib/ui/glyphs.dart`): 2.2 px walnut stroke, round caps, on
a 24 grid — needle (hint), seam ripper (unpick), turn arrow, restart, spool
(quiet room), ledger book, paper pattern (guide), star, lock, back. No
stock icon font, no emoji.

## Spacing

8-point rhythm: 4 / 8 / 12 / 16 / 20 / 24. 16–20 px side gutters. Groups
are tight (4–8), sections separated by 22–26.

## Motion

Soft and tactile, like cloth being handled:
- Press: squash to 0.94, release with a small elastic settle (220 ms).
- Patch lands: lifts 6 % and drops with `easeOutBack` (260 ms).
- Refused: 7 px side shake, decaying (320 ms) + red thread outline.
- Win: a running stitch draws along the trail (1.3 s), then the pattern
  sheet slides up; stars pop in one by one with a chime.
- Hub: the waiting block's pin breathes; a newly won block sews in with
  `easeOutBack` scale from 55 %.
- Screens fade and lift 2.5 % (320 ms, `easeOutCubic`).
- **Reduce motion** (Quiet room, or the OS setting) removes the shake,
  pulse and trail draw, and shortens transitions to fades.

## Sound

Synthesised (`tool/make_sfx.py`): cloth rustle (pick), wood tick (turn),
pressed-cloth thump + needle tick (place), thread pull (unpick), muted
double thud (refused), music-box arpeggio (bound), bell (star), two bright
notes (ribbon), needle glint (hint), soft tap (menu); a 27 s F-major
music-box loop.

## Bans honoured

No decorative gradients, glass, neon, emoji icons, nested cards, borders on
every box, rainbow accents, Inter/Fredoka, or "Play / Settings" labels
(the copy says *Sew block 12*, *Quiet room*, *Ledger*, *How to sew*).
