# Phase 05 — Navigation Shell

- **Status:** pending
- **Depends on:** 01
- **Can run in parallel with:** 02

## What

Set up named routes and placeholder screens for every destination in the GDD flow, with basic navigation working between them.

## Why

Screens can be filled in independently once routes exist; parallel work on gameplay and menus needs a shared router.

## Scope (build only this)

### Router (`lib/navigation/app_routes.dart`)

Routes (names and paths):

| Route | Path | Widget |
|-------|------|--------|
| splash | `/` | `SplashScreen` (placeholder) |
| workroom | `/workroom` | `WorkroomScreen` (placeholder) |
| cuttingTable | `/play/:levelId` | `CuttingTableScreen` (placeholder) |
| gallery | `/gallery` | `GalleryScreen` (placeholder) |
| stitchGuide | `/guide` | `StitchGuideScreen` (placeholder) |
| privacy | `/privacy` | `PrivacyScreen` (placeholder) |

Use Flutter built-in `onGenerateRoute` or `go_router` — pick whichever is already in project; default to `onGenerateRoute` for simplicity.

### Placeholder screens (`lib/screens/`)

Each shows: screen name (theme title), one line description, and **Back to Workroom** or auto-forward where appropriate.

- `splash_screen.dart` — auto `Navigator.pushReplacementNamed('/workroom')` after 1 s (full splash in phase 08)
- `workroom_screen.dart` — buttons (temporary plain labels) to gallery, guide, privacy, cutting table level 1
- `cutting_table_screen.dart` — accepts `levelId` argument; shows "Cutting Table — Level N"; embed `GameWidget` only if phase 02 dev game exists, else text placeholder
- `gallery_screen.dart`, `stitch_guide_screen.dart`, `privacy_screen.dart` — stubs

### App entry

- `app.dart`: initial route `/` (splash), theme applied, `debugShowCheckedModeBanner: false`

## Out of scope

- Themed Workroom layout (phase 07)
- Real splash animation (phase 08)
- Pause/bound/tangled overlays (phase 08)
- Game logic wiring (phase 06)

## References

- docs/GDD.md — UI/UX flow diagram, all screen names, copy sheet
- docs/DESIGN_LANGUAGE.md — n/a for placeholders
- docs/COMPLIANCE.md — keep all checks NO

## Verify

```bash
flutter run
```

Splash → Workroom. Navigate to every route and back without errors. `/play/1` receives level id 1.

## On completion

- Update Status to done; list route names.
- Update Phase 05 row in docs/IMPLEMENTATION_PLAN.md.
