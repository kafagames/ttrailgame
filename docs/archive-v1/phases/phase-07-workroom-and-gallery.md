# Phase 07 — Workroom and Gallery

- **Status:** pending
- **Depends on:** 04, 05
- **Can run in parallel with:** 06 (after 04)

## What

Implement the themed **Workroom** main menu (quilt frame + pattern cards) and **Pattern Gallery** clothesline level select with unlock/star display.

## Why

Players need an inviting hub and level picker that match the cozy theme — not placeholder buttons.

## Scope (build only this)

### Workroom (`lib/screens/workroom_screen.dart`)

Replace placeholder with GDD layout:

- `WorkroomBackgroundPainter` — muslin wall, window light parallelogram, wainscoting lines
- `QuiltFrameWidget` — walnut border, inner mini quilt preview from highest completed level (or default patchwork `CustomPainter`)
- `PatternCard` widgets stacked on frame right edge:
  - **Continue Binding** → `ProgressService.getNextLevel()` → `/play/{id}`
  - **Pattern Gallery** → `/gallery`
  - **Stitch Guide** → `/guide`
  - **Our Promise** → `/privacy`
- **Quiet Room** bottom-left: toggles for vibration and stitch sounds (persist keys `quiet_vibration`, `quiet_sounds` via `ProgressService` or `PreferencesService`)

### Gallery (`lib/screens/gallery_screen.dart`)

- `ClotheslinePainter` — ropes, clothespins
- Horizontal `ListView` of `QuiltSwatch` widgets (one per level 1–30)
  - Locked: gray muslin + lock icon
  - Unlocked: mini grid preview (`MiniGridPainter` from level definition)
  - Stars under swatch (0–3 code-drawn stars)
- Selected swatch detail panel: name, stars, **Begin Binding** → `/play/{id}`
- **← Workroom** back tab top-left

### Widgets

- `lib/widgets/pattern_card.dart`
- `lib/widgets/quilt_swatch.dart`
- `lib/widgets/mini_grid_painter.dart`
- `lib/widgets/quiet_room_sheet.dart` — bottom sheet or inline panel for toggles

### Chapter grouping

- Visual section labels on clothesline: First Stitches (1–8), Corner Turnings (9–16), etc. — subtle divider tags, not separate routes

## Out of scope

- Splash animation (phase 08)
- Full stitch guide content (phase 08)
- Win/lose overlay polish (phase 08)
- Motion polish beyond basic card press (phase 09)

## References

- docs/GDD.md — Workroom layout, Gallery layout, chapters, Quiet Room, copy sheet
- docs/DESIGN_LANGUAGE.md — pattern cards, quilt frame, clothesline, stars, colors
- docs/COMPLIANCE.md — no network, local toggles only

## Verify

```bash
flutter run
```

Workroom shows frame and cards (not a vertical button list). Gallery shows 30 swatches; locked levels not tappable; completed level shows saved stars; Begin Binding launches correct level.

## On completion

- Update Status to done; note custom painters used.
- Update Phase 07 row in docs/IMPLEMENTATION_PLAN.md.
