# Phase 03 — Game Rules

- **Status:** pending
- **Depends on:** 02
- **Can run in parallel with:** none (blocks 04, 06)

## What

Add path validation, thread-length (moves) tracking, win/lose detection, undo, and star calculation logic — pure Dart with unit tests, wired into `PatchworkGame`.

## Why

Placement alone is not a game; players need clear win/lose feedback and scoring before levels and UI ship.

## Scope (build only this)

### Path validation (`lib/logic/path_validator.dart`)

- Input: `QuiltGrid` with all placed + fixed patch cells treated as walkable; spool and thimble are walkable endpoints
- BFS/DFS from spool cell through orthogonally adjacent walkable cells
- Return `bool` connected to thimble
- Unit tests: simple straight path, blocked path, path using fixed patch, path requiring player patches

### Game state (`lib/models/game_session.dart`)

- Fields: level id (int stub), `QuiltGrid`, available patches in tray (inventory counts), `threadRemaining`, `threadUsed`, list of placed patches for undo, `goldenThread` par count
- Methods: `placePatch(...)`, `undoLast()`, `rotateSelected()`, `checkWin()`, `checkLose()` (threadRemaining == 0 && !win)

### Pattern note checker (`lib/logic/pattern_note_checker.dart`)

- Parse simple rule types from level metadata string:
  - `maxShape:corner:1`
  - `requireColor:rose`
  - `noUndo`
- Return bool for ★★★ satisfaction
- Default true when pattern note is null

### Star calculator (`lib/logic/star_calculator.dart`)

- Input: won, moves used, golden thread, pattern note result
- Output: 0–3 stars per GDD rules

### Wire into game

- After each successful place: decrement thread, push undo stack, check win → emit `GameEvent.bound` or lose → `GameEvent.tangled`
- `Rip Last`: pop undo stack, refund thread
- Expose `ValueNotifier<GameSessionState>` or Flame overlay callback for UI phases

### Tests (`test/`)

- `path_validator_test.dart` — at least 5 cases
- `star_calculator_test.dart` — par met, pattern note met/missed

## Out of scope

- Persisting stars (phase 04)
- Full level catalog (phase 04)
- Overlay UI for bound/tangled (phase 08)
- Themed HUD dots (phase 06)

## References

- docs/GDD.md — path rule, thread length, stars table, pattern notes, win/lose
- docs/DESIGN_LANGUAGE.md — n/a (logic only)
- docs/COMPLIANCE.md — keep all checks NO

## Verify

```bash
flutter test
flutter run
```

On dev grid: complete a test path → win event fires. Exhaust thread without path → tangled event. Undo refunds thread. Unit tests pass.

## On completion

- Update Status to done; note test count and key classes.
- Update Phase 03 row in docs/IMPLEMENTATION_PLAN.md.
