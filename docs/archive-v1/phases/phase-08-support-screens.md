# Phase 08 — Support Screens

- **Status:** pending
- **Depends on:** 05, 06
- **Can run in parallel with:** 07 (partial)

## What

Implement Splash, Pause, Quilt Bound, Tangled Threads, Stitch Guide, and Our Promise screens/overlays with full GDD copy and navigation.

## Why

Every screen in the flow must be complete for a shippable, Play-Store-quality experience.

## Scope (build only this)

### Splash (`lib/screens/splash_screen.dart`)

- Muslin gradient background
- `SplashThreadPainter` — animated thread stitching title over 1.2 s
- Subtitle fade-in; auto-navigate to Workroom at 2.5 s; tap to skip
- Remove temporary 1 s auto-forward from phase 05

### Pause overlay (`lib/widgets/overlays/rest_hands_overlay.dart`)

- Linen card on semi-transparent muslin
- Actions: Resume Stitching, Rip Seam (confirm inline on second tap), Return to Workroom
- Called from Cutting Table Rest Hands; freezes `PatchworkGame` (`pauseEngine()`)

### Quilt Bound (`lib/widgets/overlays/quilt_bound_overlay.dart`)

- Star drop animation (sequential, code-drawn stars)
- Completed grid preview at 80% scale
- Next Pattern / Admire Gallery / Restitch buttons
- Save stars before show (if not already saved in phase 06)

### Tangled Threads (`lib/widgets/overlays/tangled_overlay.dart`)

- Amber-accent card, copy from GDD
- Rip Seam / Return to Workroom

### Stitch Guide (`lib/screens/stitch_guide_screen.dart`)

- Ledger book scrollable layout with 5 sections and small inline `CustomPainter` diagrams (grid icons, not images)
- Back to Workroom
- First launch: if `has_seen_stitch_guide` false, show optional prompt on Workroom once (dismiss + set flag)

### Privacy (`lib/screens/privacy_screen.dart`)

- Our Promise full text from GDD
- Back to Workroom

### Routing updates

- Bound/tangled can be overlays on Cutting Table (preferred) rather than separate routes — keeps grid visible underneath

## Out of scope

- Final haptic/sound wiring (phase 09)
- Deep animation polish beyond star drop and splash thread (phase 09)
- Launcher icon (phase 10)

## References

- docs/GDD.md — every support screen section, copy sheet, flow diagram
- docs/DESIGN_LANGUAGE.md — linen cards, motion table, typography
- docs/COMPLIANCE.md — privacy wording, no data collection

## Verify

```bash
flutter run
```

Full flow: Splash → Workroom → play → pause all three actions work → win overlay with stars → gallery → guide → privacy. Fresh install shows stitch guide prompt once.

## On completion

- Update Status to done; list overlay widgets.
- Update Phase 08 row in docs/IMPLEMENTATION_PLAN.md.
