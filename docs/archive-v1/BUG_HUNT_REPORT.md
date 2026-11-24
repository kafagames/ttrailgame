# Bug Hunt Report — Patchwork Path — June 2, 2026

## Summary

The game is in good shape after this pass: **7/7 tests pass**, `flutter analyze` reports no errors (4 info-level lint hints only). Fixed one **critical** level-design bug (unsolvable tutorial), one **high** scoring bug, layout overlaps, and gallery overflow. Remaining open items are polish (launcher icon, full level solvability audit for levels 6–30).

## Fixed

| Issue | Severity | Location | Fix |
|-------|----------|----------|-----|
| Level 1 impossible — thimble shared cell with required rail placement | critical | `lib/data/levels.dart` | Moved thimble to `(4,2)` (`S...T` row) so one rail at `(1,2)` connects spool to thimble without overlapping thimble |
| Level 5 impossible — fixed patch disconnected from spool/thimble | critical | `lib/data/levels.dart` | Redesigned as 6-wide row: spool + fixed middle rail + thimble; player adds vertical rail at `(1,1)` |
| ★★★ awarded on levels with no Pattern Note | high | `lib/logic/game_rules.dart`, `lib/models/game_session.dart` | Added `hasPatternNote` flag; third star only when level defines a pattern rule |
| Grid drew over patch tray (overlap with bottom controls) | medium | `lib/game/patchwork_game.dart` | Reserved 88px tray height in grid layout calculation |
| Gallery `QuiltSwatch` Column overflow (~15px) | medium | `lib/widgets/quilt_swatch.dart`, `lib/screens/gallery_screen.dart` | Compact swatch sizing; reduced clothesline padding (fixed in prior session, verified) |
| Locked gallery **Begin Binding** looked tappable | low | `lib/widgets/fabric_widgets.dart` | `FabricButton` dims when `onPressed` is null |
| Workroom horizontal overflow on narrow viewports | medium | `lib/screens/workroom_screen.dart` | `LayoutBuilder` + scroll/wrap layout under 520px width |
| Star calculator tests out of date | low | `test/star_calculator_test.dart` | Updated for `hasPatternNote` parameter |
| Tutorial solvability regression guard | low | `test/level_solvability_test.dart` | Added brute-force check that level 1 is solvable |

## Open / needs user decision

| Issue | Why not auto-fixed | Suggested fix |
|-------|-------------------|---------------|
| No custom launcher icon / `flutter_launcher_icons` config | Phase 10 release prep; needs art direction | Run `game-build` phase 10 or add `flutter_launcher_icons` with quilt-themed icon |
| Levels 6–30 not brute-force verified | Solvability search is exponential; hung CI on multi-patch levels | Manual play-through of chapters 2–4, or add a level-design lint tool with smarter search |
| `docs/IMPLEMENTATION_PLAN.md` phases still `pending` | Doc sync not requested; game code is built | Mark phases done if you want docs to match reality |
| Josefin Slab bundled as variable font for all weights | Google Fonts static downloads failed; variable `.ttf` copied | Works offline; optional: replace with distinct static weight files |
| Pause icon is Material `pause`, GDD mentions thimble icon | GDD says thimble for Rest Hands; code-drawn thimble on grid only | Swap HUD icon for a small code-drawn thimble widget if strict GDD match matters |

## Verification

- flutter analyze: **pass** (0 errors, 4 info)
- flutter test: **7/7 pass**
- Manual checks performed:
  - GDD route map: splash → workroom → play/gallery/guide/privacy → pause/bound/tangled overlays
  - `debugShowCheckedModeBanner: false` on `MaterialApp`
  - No `flame_audio`, no runtime `google_fonts`, no INTERNET in release `AndroidManifest.xml`
  - Bundled fonts referenced in `pubspec.yaml` under `assets/fonts/`
  - Theme-native copy (Continue Binding, Rest Hands, Rip Seam, etc.)
  - Gallery overflow fix from Chrome session (quilt swatch layout)
