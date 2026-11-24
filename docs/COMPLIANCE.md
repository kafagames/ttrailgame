# Thimble Trail — Play Store Compliance Audit

Audited 2026-11-12 against the 14 pre-submission questions. Scope: all of
`lib/` (every player-facing string, level names, chapter notes, ribbons,
privacy text), `assets/` (images, sounds, music, fonts), the generator
scripts in `tool/`, `AndroidManifest.xml` and `pubspec.yaml`. Method: a
keyword sweep (violence, horror, sexual, gambling, profanity, substances,
crude, purchases, chat, location, extremist, crime terms) plus a manual read
of all text and a visual check of every image and screen.

**Result: all 14 answers are NO. Ready to submit.**

| # | Question | Answer | Evidence / where checked |
|---|----------|--------|--------------------------|
| 1 | Violence / gore | NO | No combat, damage or death. Animations are patches settling, a stitch drawing, stars popping. The only "red" is a red-thread outline for a refused move. A block once named *Burgoyne Surrounded* (a battle) was renamed *Morning Star*. |
| 2 | Scary / horrifying content | NO | Sunny sewing-room art (`tool/make_art.py`), music-box loop and soft sewing SFX (`tool/make_sfx.py`). "Ghost" in code is only the placement preview, never shown as a word to players. |
| 3 | Sexual content / nudity / revealing attire | NO | No characters at all. "Double Wedding Ring" is a traditional quilt-block name with no romantic content. |
| 4 | Gambling | NO | No loot boxes, chance rewards, dice or betting. Rewards (hints, ribbons, table covers) are fixed and earned by play. Block *Card Trick* renamed *Garden Path* to avoid a card-game theme; *Crosses and Losses* renamed *Hens and Chicks*. |
| 5 | Offensive language | NO | All copy read in `lib/screens/*`, `lib/data/*`, `lib/services/ribbons.dart`. |
| 6 | Drugs / alcohol / tobacco | NO | Block *Drunkard's Path* (traditional name, but an alcohol reference) renamed *Winding Ways*. Nothing else found. |
| 7 | Crude humour | NO | No bodily-function content in text, art or sound. Block *Puss in the Corner* renamed *Cat's Cradle* to avoid any crude reading. |
| 8 | Digital purchases / cash-convertible rewards / NFTs | NO | No IAP or billing library in `pubspec.yaml`; no currency; hints cannot be bought. |
| 9 | User communication | NO | Single-player, offline. No chat, sharing or networking code; no INTERNET permission in the release manifest. |
| 10 | Precise location sharing | NO | No location plugin or permission. The Pattern of the Day is seeded only by the device's calendar date. |
| 11 | Nazi symbols / propaganda | NO | Quilt motifs are squares and triangles (four patch, nine patch, pinwheel, hourglass, flying geese, rail fence, log cabin, churn dash); checked none forms a prohibited symbol. |
| 12 | Korean historical distortion | NO | No historical narrative or maps. |
| 13 | Terrorism advocacy | NO | No storyline, objectives or propaganda. |
| 14 | Realistic crime / criminal techniques | NO | Block *Rob Peter to Pay Paul* (theft idiom) renamed *Orange Peel*. No crime content. |

## Related checks

- Release manifest: no `<uses-permission>` (INTERNET exists only in
  `src/debug` and `src/profile`, which are not shipped). Plugin manifests
  (`audioplayers_android`, `shared_preferences_android`, `jni`,
  `jni_flutter`) declare none.
- No ads SDK, no analytics, no crash reporting.
- Name: original working title "Patchwork Path" clashes with an existing
  quilt game on Steam; shipped as **Thimble Trail** (`com.thimbletrail.game`).
- Content rating expectation: Everyone / PEGI 3. Target audience 13+.
