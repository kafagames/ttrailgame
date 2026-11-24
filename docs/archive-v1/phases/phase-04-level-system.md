# Phase 04 — Level System

- **Status:** pending
- **Depends on:** 03
- **Can run in parallel with:** 05 (after 03), 06 (partial)

## What

Define all 30 levels as Dart constants, load them into `GameSession`, and persist stars plus unlock progress with `shared_preferences`.

## Why

Progression and replay value require real puzzles and saved state before Workroom and Gallery screens mean anything.

## Scope (build only this)

### Level model (`lib/models/level_definition.dart`)

- Fields: id, displayName, chapterIndex, gridW, gridH, cell layout encoding, inventory (patches available), threadLimit, goldenThread, patternNote (nullable String), patternNoteRule (nullable structured rule for checker)

### Level encoding

Use a simple string row format per row (e.g. `.` empty, `#` batting, `S` spool, `T` thimble, `F`+shape code for fixed patches) — keep readable in source. Parser in `lib/data/level_parser.dart` builds `QuiltGrid`.

### Level catalog (`lib/data/levels.dart`)

- `const allLevels = [ LevelDefinition(...), ... ]` — 30 levels following GDD difficulty table:
  - 1–8 First Stitches (5×5, rail)
  - 9–16 Corner Turnings (6×6, corner)
  - 17–24 Block by Block (7×7, block)
  - 25–30 Pattern Notes (7–8×8, pattern goals)
- Each level manually solvable (author verify during implementation)

### Progress service (`lib/services/progress_service.dart`)

- Keys: `highest_unlocked_level`, `level_{n}_stars`
- Methods: `getStars(n)`, `setStars(n, stars)` (keep best), `isUnlocked(n)`, `unlockThrough(n)`, `getNextLevel()`, `getHighestUnlocked()`
- Load/save via `preferences_service.dart`

### Level loader (`lib/services/level_loader.dart`)

- `GameSession loadLevel(int id)` — builds grid + session from `LevelDefinition`

### Remove dev hard-coded grid

- `PatchworkGame` accepts `GameSession` from loader instead of inline test grid

## Out of scope

- Gallery UI (phase 07)
- Star display animations (phase 08/09)
- Hive (use shared_preferences only unless a strong reason appears)

## References

- docs/GDD.md — chapters, difficulty scaling, level data fields, unlock rules
- docs/DESIGN_LANGUAGE.md — n/a
- docs/COMPLIANCE.md — local-only storage, no network

## Verify

```bash
flutter test test/level_parser_test.dart
flutter run
```

Load level 1 and level 15 via temporary debug buttons; grids differ correctly. Complete level 1 → stars saved; level 2 unlocks after restart.

## On completion

- Update Status to done; note level count and storage keys.
- Update Phase 04 row in docs/IMPLEMENTATION_PLAN.md.
