# Phase 10 — Testing and Release

- **Status:** pending
- **Depends on:** 09
- **Can run in parallel with:** none

## What

Run automated tests, execute a manual QA checklist, generate the launcher icon, and prepare a signed release build configuration.

## Why

Final verification and release prep ensure the game is stable and Play-Store-submittable.

## Scope (build only this)

### Automated tests

Ensure passing:

- `test/path_validator_test.dart`
- `test/star_calculator_test.dart`
- `test/level_parser_test.dart`
- Add `test/progress_service_test.dart` — stars persist best, unlock increments
- Add `test/widget_test.dart` — smoke: app pumps, splash navigates (use fake async)

```bash
flutter test
flutter analyze
```

### Manual QA checklist

Execute and note results in this file on completion:

- [ ] Cold start → splash → workroom < 3 s on mid device
- [ ] Complete level 1 → 2 unlocks
- [ ] Stars persist after app restart
- [ ] Pause/resume preserves grid state
- [ ] Rip Seam resets level
- [ ] Return to Workroom from pause and fail screens
- [ ] All 30 levels load without crash (spot-check 1, 9, 17, 25, 30)
- [ ] Quiet Room toggles work
- [ ] Airplane mode — full game playable (offline)
- [ ] No debug banner visible
- [ ] Back gesture does not trap user (Android predictive back)

### Launcher icon

- Generate app launcher icon (single permitted binary besides fonts) using Flutter `flutter_launcher_icons` or manual adaptive icon with quilt/patch motif in code-exported PNG — warm rose + sage on cream; no external art dependency beyond generated icon

### Release config

- `android/app/build.gradle`: set `applicationId`, `versionCode`, `versionName` (1.0.0)
- Enable minify if desired (keep simple — default release build OK)
- Document release command in this file:

```bash
flutter build appbundle --release
```

### Store metadata draft (in this file notes section, not separate doc unless requested)

- Title: Patchwork Path
- Short description: Stitch fabric patches into trails across cozy quilt puzzles. Offline, no ads, no data collected.
- Category: Puzzle
- Content rating: Everyone

### Remove temporary code

- Delete any debug routes, print statements, TODO stubs flagged during QA

## Out of scope

- Play Store console submission (user action)
- Custom art/audio assets
- Post-launch levels beyond 30

## References

- docs/GDD.md — full feature set for QA
- docs/DESIGN_LANGUAGE.md — launcher icon colors
- docs/COMPLIANCE.md — verify all 14 checks still NO before release

## Verify

```bash
flutter test
flutter analyze
flutter build appbundle --release
```

All tests green, analyze clean, release AAB builds successfully.

## On completion

- Update Status to done; paste QA checklist results and AAB path.
- Update Phase 10 row in docs/IMPLEMENTATION_PLAN.md.
- All phases should read **done** in IMPLEMENTATION_PLAN status table.
