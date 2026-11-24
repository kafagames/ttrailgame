# Phase 02 — Grid and Patches

- **Status:** pending
- **Depends on:** 01
- **Can run in parallel with:** 05

## What

Implement the quilt grid renderer and fabric patch system: cell types, patch shapes (Rail, Corner, Block), rotation, selection, and tap-to-place on a Flame canvas inside a test harness screen.

## Why

The core tactile loop — see grid, pick patch, turn, place — must work before rules, levels, or polished UI.

## Scope (build only this)

### Models (`lib/models/`)

- `cell_type.dart` — enum: empty, batting, spool, thimble, fixedPatch, placedPatch
- `patch_shape.dart` — enum: rail, corner, block; method `List<Offset> cellsForRotation(int quarterTurns)` returning relative cell offsets
- `patch_instance.dart` — shape, color index, rotation (0–3), anchor grid position (nullable until placed)
- `grid_cell.dart` — type + optional patch data for fixed/placed
- `quilt_grid.dart` — width, height, `List<List<GridCell>>`, helpers: `cellAt(x,y)`, `canPlace(patch, anchor)`, `place(patch, anchor)`, `removeAt(x,y)`

### Rendering (`lib/game/components/`)

- `quilt_grid_component.dart` — Flame component drawing grid using `Canvas`: cell fills, stitch borders, batting cross-hatch per DESIGN_LANGUAGE
- `patch_component.dart` — draws a patch shape at grid coordinates with calico gradient
- `spool_marker.dart` / `thimble_marker.dart` — code-drawn markers on spool/thimble cells

### Game shell

- `patchwork_game.dart` — add `QuiltGridComponent`, accept a hard-coded 5×5 test grid (1 spool, 1 thimble, 2 batting, 1 fixed rail)
- Tap handling: convert tap to grid cell; if patch selected in tray, attempt place; if tap on placed player patch, select for removal (removal logic finalized in phase 03)

### Patch tray (minimal)

- `lib/game/components/patch_tray_component.dart` — shows 2–3 patch previews bottom of Flame viewport; tap selects; button area for rotate (callback to game)

### Dev screen

- `lib/screens/dev_grid_screen.dart` — hosts `GameWidget<PatchworkGame>` for testing; reachable via temporary route `/dev` from placeholder

### Placement rules (geometry only)

- Patch cells must be in bounds, all empty, not overlapping batting/spool/thimble/fixed/others
- Invalid placement triggers shake animation on tray (horizontal offset tween 300 ms)

## Out of scope

- Path validation and win/lose (phase 03)
- Level data files (phase 04)
- Themed Cutting Table HUD, pause, navigation polish (phases 06–08)
- Star scoring

## References

- docs/GDD.md — grid rules, patch shapes table, Cutting Table layout
- docs/DESIGN_LANGUAGE.md — cell state colors, patch gradients, motion (shake)
- docs/COMPLIANCE.md — keep all checks NO

## Verify

```bash
flutter run
```

Navigate to `/dev` (temporary). Grid renders with distinct cell types. Select patch, tap Turn, place on valid cells; invalid cells shake tray. Fixed patches cannot be overwritten.

## On completion

- Update Status to done; list model and component file paths.
- Update Phase 02 row in docs/IMPLEMENTATION_PLAN.md.
