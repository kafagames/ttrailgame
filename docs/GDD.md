# Thimble Trail — Game Design

## Pitch

Lay rotatable fabric patches on a little quilt to stitch a trail from the
spool to the thimble, using as few patches as you can. Every block you bind
is sewn into the heirloom quilt hanging in your workroom.

## Rules

- The quilt is a grid. Squares are **muslin** (open), **batting** (can't be
  covered), the **spool** (start), the **thimble** (finish), **buttons** or
  **pre-sewn** squares.
- The tray holds patches: **Snip** (2), **Rail** (3 in a row), **Corner**
  (3 in an L), **Block** (2×2), **Tee** (4), **Step** (4). Each has a fabric.
- Tap a patch to pick it, tap it again (or *Turn*) to rotate.
- Tap or drag on the quilt: the patch lands so that it covers the square
  under your finger, centre squares first. A ghost shows where; red thread
  means it can't go there, with a one-line reason.
- Tap a laid patch to unpick it. *Unpick last* and *Start over* are free.
- **Bound** when sewn squares join the spool to the thimble edge-to-edge,
  and every button is covered and on that same trail.
- **Matching seams** (chapter 4+, some blocks after): two patches of the
  same fabric may never share an edge — including pre-sewn squares.
- If the tray empties without binding, a note suggests unpicking. There is
  no fail state.

## Stars

★ bound · ★★ bound with par + 1 patches · ★★★ bound at par.
Par is the solver-proven minimum.

## Structure

48 blocks, 5 chapters (6 / 10 / 9 / 12 / 11). Block *n* opens when block
*n−1* is bound. Each chapter's first block shows a one-time note on its new
idea. See `IMPROVEMENT_PLAN.md` §3.

## Hints

A hint asks the solver for the best route from the current layout,
outlines the next patch in brass and pre-selects/turns it. If the current
layout can't bind, it says so and costs nothing. Start with 3; +1 per
ribbon, +1 per Pattern of the Day.

## Retention

Pattern of the Day (offline, date-seeded, same for everyone, streak), 12
ribbons, 4 table covers unlocked at 0 / 30 / 70 / 115 stars, Ledger stats,
and the quilt filling up.

## Screens

Splash (stitch draws under the logo) → **Workroom** hub (quilt on the wall,
*Sew block n* label, Daily pattern / Ledger / How to sew / Quiet room) →
**Cutting table** (play) with pause sheet (*Set your work down?*), result
sheet (*Quilt bound*), chapter notes → **How to sew** (interactive practice
quilt + rules) · **Quiet room** (sound, music, vibration, reduce motion,
table cover, Our promise, Unpick everything) · **Ledger** · **Our promise**
(in-game privacy).

## Persistence

`shared_preferences` on device only: stars per block, hints, ribbons,
streak, stats, settings, seen chapter notes. A level in progress is not
saved (blocks take a minute or two).
