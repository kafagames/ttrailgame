# Patchwork Path — Compliance

Every design, asset, and mechanic in this game keeps all Play Store safety checks at **NO**. If any future feature would flip one to YES, change the design before building.

| # | Check | Status | Notes for Patchwork Path |
|---|-------|--------|--------------------------|
| 1 | Violence, blood, or gore | **NO** | No combat, enemies, or harm visuals. Puzzle-only gameplay. |
| 2 | Scary/horrifying content | **NO** | Cozy quilt-shop aesthetic; warm colors, gentle motion. |
| 3 | Sexual content or suggestiveness | **NO** | Family-friendly craft theme; no revealing imagery. |
| 4 | Gambling or casino themes | **NO** | No loot boxes, dice betting, or randomized paid rewards. Stars are earned by puzzle skill. |
| 5 | Offensive language | **NO** | All UI copy is warm, neutral, theme-native craft language. |
| 6 | Drugs, alcohol, or tobacco | **NO** | Setting is a fabric workroom only. |
| 7 | Crude bodily-function humor | **NO** | Not applicable to theme; none used. |
| 8 | Digital purchases or cash rewards | **NO** | Fully offline; no IAP, ads, wallets, or NFTs. |
| 9 | User communication | **NO** | Single-player offline; no chat, voice, or sharing. |
| 10 | Precise location sharing | **NO** | No GPS, maps, or geolocation APIs. |
| 11 | Nazi symbols or propaganda | **NO** | Not present in theme, art, or copy. |
| 12 | Distortion of Korean historical facts | **NO** | Not applicable; no historical narrative content. |
| 13 | Advocacy of terrorism | **NO** | Not present. |
| 14 | Realistic crime descriptions | **NO** | Not present. |

## Offline & privacy posture

- No network calls, accounts, analytics, or crash reporters.
- Progress (stars, unlocked patterns) stored locally via `shared_preferences` only.
- Privacy screen states clearly that no data is collected or transmitted.
