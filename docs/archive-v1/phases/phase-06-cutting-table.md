# Phase 06 — Cutting Table

- **Status:** pending
- **Depends on:** 02, 03, 05
- **Can run in parallel with:** 07 (after 04+05)

## What

Build the full gameplay screen: HUD, patch tray controls, Flame grid integration, pause trigger, and navigation on win/lose events.

## Why

This is the primary play experience — it merges grid mechanics, rules, levels, and routing into one cohesive screen.

## Scope (build only this)

### Screen layout (`lib/screens/cutting_table_screen.dart`)

Flutter `Stack`:

1. **Background** — Table Maple gradient (`CustomPainter` wood grain optional: simple horizontal lines)
2. **Center** — `GameWidget<PatchworkGame>` filling space between HUD and tray
3. **Top HUD** — `CuttingTableHud` widget:
   - Pattern name from `LevelDefinition`
   - Thread dots (remaining count)
   - Rest Hands → opens pause route or overlay callback
4. **Pattern note ribbon** — visible when level has pattern note (★★★ goal text)
5. **Bottom tray bar** — Flutter row: Rip Last | GameWidget bottom tray OR Flutter patch selector mirroring tray state | Turn Patch button

Prefer keeping patch tray in Flame for visual consistency; HUD/tray buttons can be Flutter overlays positioned with `Align`.

### Game integration

- On init: `LevelLoader.loadLevel(levelId)`, pass session to `PatchworkGame`
- Listen to game events: `bound` → save stars via `ProgressService`, navigate to bound overlay; `tangled` → show tangled overlay
- Rip Seam from pause: reload session for same level id

### Widgets (`lib/widgets/`)

- `thread_dots.dart` — HUD thread indicator
- `fabric_icon_button.dart` — reusable themed icon button (Rip Last, Turn Patch, Rest Hands)
- `pattern_note_banner.dart`

### Remove `/dev` route

- Dev grid absorbed into cutting table; delete `dev_grid_screen.dart` or redirect to level 1

## Out of scope

- Themed pause/bound/tangled overlay content (phase 08 — use simple `showDialog` stubs that call correct actions)
- Workroom and Gallery theming (phase 07)
- Splash (phase 08)
- Final animations and haptics (phase 09)

## References

- docs/GDD.md — Cutting Table layout, interactions, copy sheet
- docs/DESIGN_LANGUAGE.md — HUD dots, fabric buttons, grid sizing, colors
- docs/COMPLIANCE.md — keep all checks NO

## Verify

```bash
flutter run
```

From Workroom → level 1. Play full level: place patches, undo, pause stub appears, win navigates to bound stub with stars saved, intentional fail shows tangled stub.

## On completion

- Update Status to done; note main widget structure.
- Update Phase 06 row in docs/IMPLEMENTATION_PLAN.md.
