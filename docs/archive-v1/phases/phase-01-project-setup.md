# Phase 01 — Project Setup

- **Status:** pending
- **Depends on:** none
- **Can run in parallel with:** none

## What

Create the Flutter + Flame project scaffold for Patchwork Path: dependencies, folder layout, bundled Josefin Slab font, theme constants, and a minimal app shell that launches to a placeholder screen.

## Why

Everything else depends on a running project with the pinned stack and conventions locked in.

## Scope (build only this)

- Run `flutter create patchwork_path` (or equivalent) in the workspace root with org identifier e.g. `com.patchworkpath.game`.
- Set `pubspec.yaml` dependencies:
  - `flame: ^1.37.0`
  - `shared_preferences: ^2.5.5`
  - `hive_ce: ^2.19.3` and `hive_ce_flutter: ^2.1.0` (add only if needed later; safe to include now)
- Download Josefin Slab Regular (400), SemiBold (600), Bold (700) into `assets/fonts/` and declare in `pubspec.yaml` per `DESIGN_LANGUAGE.md`.
- Create folder structure:

```
lib/
  main.dart
  app.dart
  theme/
    patchwork_colors.dart
    patchwork_theme.dart
  game/
    patchwork_game.dart          # FlameGame entry (stub)
  screens/
    placeholder_screen.dart
  data/
    (empty — phase 04)
  models/
    (empty — phase 02)
  services/
    preferences_service.dart     # stub
```

- `main.dart`: run app, initialize `WidgetsFlutterBinding`, optional `SharedPreferences` warmup.
- `app.dart`: `MaterialApp` with `debugShowCheckedModeBanner: false`, `theme: patchworkTheme`, initial route `/` → placeholder showing title "Patchwork Path" and subtitle "Workroom loading…".
- `patchwork_colors.dart`: export all hex constants from `DESIGN_LANGUAGE.md`.
- `patchwork_theme.dart`: `ThemeData` using Josefin Slab, Muslin Cream scaffold background, Thread Rose primary.
- `patchwork_game.dart`: empty `FlameGame` subclass (no components yet).
- `preferences_service.dart`: singleton wrapper around `SharedPreferences.getInstance()` with no keys yet.

## Out of scope

- Grid, patches, levels, navigation beyond placeholder, gameplay, haptics, launcher icon (phase 10).

## References

- docs/GDD.md — copy sheet (app title strings), technical notes
- docs/DESIGN_LANGUAGE.md — full color palette, typography bundling
- docs/COMPLIANCE.md — keep all checks NO

## Verify

```bash
flutter pub get
flutter analyze
flutter run
```

App launches with no debug banner, cream background, Josefin Slab title visible, no runtime errors.

## On completion

- Update this file's Status to done and add notes (Flutter version, package name, key paths).
- Update the row for Phase 01 in docs/IMPLEMENTATION_PLAN.md.
