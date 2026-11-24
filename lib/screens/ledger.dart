import 'package:flutter/material.dart';

import '../data/levels.dart';
import '../services/ribbons.dart';
import '../services/store.dart';
import '../ui/glyphs.dart';
import '../ui/palette.dart';
import '../widgets/stitch.dart';

/// The sewing ledger: tallies and ribbons.
class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Store.instance;
    final today = DateTime.now();
    final rows = <(String, String)>[
      ('Blocks sewn', '${s.blocksSewn} of ${allLevels.length}'),
      ('Stars', '${s.totalStars} of ${allLevels.length * 3}'),
      ('Blocks at par', '${s.perfectBlocks}'),
      ('Patches sewn', '${s.statSewn}'),
      ('Quilts bound', '${s.statBound}'),
      ('Daily patterns', '${s.dailyDone}'),
      ('Daily streak', '${s.streak(today)} (best ${s.bestStreak})'),
      ('Hints used', '${s.statHints}'),
      ('Hints in the tin', '${s.hints}'),
    ];
    final have = s.ribbons;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Ledger'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  for (final (k, v) in rows)
                    MergeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            Expanded(child: Text(k, style: Txt.body)),
                            Text(
                              v,
                              style: Txt.label.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  Text('Ribbons', style: Txt.title.copyWith(fontSize: 20)),
                  Text(
                    '${have.length} of ${allRibbons.length} · each one adds a hint',
                    style: Txt.small,
                  ),
                  const SizedBox(height: 10),
                  for (final r in allRibbons)
                    MergeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            GlyphIcon(
                              Glyph.star,
                              size: 26,
                              color: have.contains(r.id)
                                  ? Hue.brass
                                  : Hue.plaster,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.name,
                                    style: Txt.label.copyWith(
                                      color: have.contains(r.id)
                                          ? Hue.walnut
                                          : Hue.thread,
                                    ),
                                  ),
                                  Text(
                                    have.contains(r.id)
                                        ? 'Earned · ${r.how}'
                                        : r.how,
                                    style: Txt.small,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
