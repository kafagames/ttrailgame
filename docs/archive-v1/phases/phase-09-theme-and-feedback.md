# Phase 09 — Theme and Feedback

- **Status:** pending
- **Depends on:** 06, 07, 08
- **Can run in parallel with:** none

## What

Apply the full design language consistently, add motion polish, and wire haptic/system-sound feedback respecting Quiet Room toggles.

## Why

Visual cohesion and tactile feedback separate a prototype from a store-ready cozy game.

## Scope (build only this)

### Theme audit

- Replace any remaining default Material colors with `patchwork_colors.dart`
- Ensure all text uses Josefin Slab at defined scale
- Standardize padding to spacing tokens (xs–xxl)
- Fabric buttons everywhere CTAs appear

### Motion

Implement DESIGN_LANGUAGE motion table:

- Screen transitions: fade + slide 300 ms
- Patch select scale
- Invalid place shake (verify from phase 02)
- Win path pulse on grid cells
- Star drop on bound overlay
- Card press on Workroom pattern cards

### Feedback service (`lib/services/feedback_service.dart`)

- Read `quiet_vibration` and `quiet_sounds` from preferences
- Methods: `onPlace()`, `onInvalid()`, `onRotate()`, `onBound(starCount)`, `onTangled()`
- Map to `HapticFeedback` and `SystemSound.play(SystemSoundType.click)` per GDD

Wire calls in `PatchworkGame` and overlay show handlers.

### Accessibility

- Semantics labels for spool, thimble, thread count, stars
- Minimum 48 dp touch targets audit

### Responsive pass

- Verify layouts on small (360×640) and large phone sizes
- Gallery detail panel drops below clothesline on short screens

## Out of scope

- New features or levels
- Custom audio files
- Store listing assets beyond launcher icon (phase 10)

## References

- docs/GDD.md — audio/haptic table, Quiet Room toggles
- docs/DESIGN_LANGUAGE.md — full visual system, motion, responsiveness
- docs/COMPLIANCE.md — no extra permissions, no audio files

## Verify

```bash
flutter analyze
flutter run
```

Visual pass: no default blue Material buttons. Toggles in Quiet Room disable vibration/sounds. Animations run smoothly on win and splash. Text readable on 360 dp width.

## On completion

- Update Status to done; note feedback service and any layout fixes.
- Update Phase 09 row in docs/IMPLEMENTATION_PLAN.md.
