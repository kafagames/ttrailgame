# Patchwork Path

**One-line pitch:** Place and rotate fabric patches on a quilt grid to stitch a path from spool to thimble — cozy puzzle trails in a grandmother's workroom.

## Pillars

1. **Cozy craft** — Every screen feels like a sunlit quilt shop: warm fabrics, stitched borders, unhurried motion.
2. **One clear puzzle** — Pick a patch, turn it, place it; connect start to finish before your thread runs out.
3. **Offline & private** — No accounts, no network, no data collection; progress lives only on the device.
4. **Code-drawn beauty** — Shapes, gradients, and motion in Flame/Flutter; no external art files.

## Documents

| Document | Purpose |
|----------|---------|
| [GDD.md](GDD.md) | Full game design: mechanics, screens, progression, copy sheet |
| [DESIGN_LANGUAGE.md](DESIGN_LANGUAGE.md) | Colors, type, spacing, UI components, code-drawn visuals |
| [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) | Phase list, dependency graph, status table |
| [COMPLIANCE.md](COMPLIANCE.md) | Play Store safety checks (all NO) |

## Phases

| Phase | File | Summary |
|-------|------|---------|
| 01 | [phase-01-project-setup.md](phases/phase-01-project-setup.md) | Flutter + Flame project, dependencies, app shell |
| 02 | [phase-02-grid-and-patches.md](phases/phase-02-grid-and-patches.md) | Grid rendering, patch shapes, rotation, placement |
| 03 | [phase-03-game-rules.md](phases/phase-03-game-rules.md) | Path validation, moves, win/lose, stars |
| 04 | [phase-04-level-system.md](phases/phase-04-level-system.md) | Level definitions, progression, local save |
| 05 | [phase-05-navigation-shell.md](phases/phase-05-navigation-shell.md) | Routes and placeholder screens |
| 06 | [phase-06-cutting-table.md](phases/phase-06-cutting-table.md) | Full gameplay screen and HUD |
| 07 | [phase-07-workroom-and-gallery.md](phases/phase-07-workroom-and-gallery.md) | Main menu and pattern gallery |
| 08 | [phase-08-support-screens.md](phases/phase-08-support-screens.md) | Splash, pause, complete, guides, privacy |
| 09 | [phase-09-theme-and-feedback.md](phases/phase-09-theme-and-feedback.md) | Design polish, haptics, system sounds |
| 10 | [phase-10-testing-and-release.md](phases/phase-10-testing-and-release.md) | QA, launcher icon, release prep |

## Stack

- Flutter 3.44 · Dart 3.12.0
- flame ^1.37.0
- shared_preferences ^2.5.5
- hive_ce ^2.19.3 (optional; use only if needed beyond shared_preferences)
- Josefin Slab (bundled under `assets/fonts/`)

## Next step

Run **game-build** phase by phase, starting with [phase-01-project-setup.md](phases/phase-01-project-setup.md).
