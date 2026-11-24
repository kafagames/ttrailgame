import '../data/levels.dart';
import 'store.dart';

/// A local achievement. Each one earned also gives one hint.
class Ribbon {
  const Ribbon(this.id, this.name, this.how, this.test);
  final String id;
  final String name;
  final String how;
  final bool Function(Store s) test;
}

final allRibbons = <Ribbon>[
  Ribbon(
    'first',
    'First Stitch',
    'Bind your first block.',
    (s) => s.blocksSewn >= 1,
  ),
  for (var c = 0; c < 5; c++)
    Ribbon(
      'chapter$c',
      _chapterRibbon[c],
      'Finish chapter ${c + 1}.',
      (s) => s.chapterComplete(c),
    ),
  Ribbon(
    'neat10',
    'Neat Seams',
    'Bind 10 blocks at par.',
    (s) => s.perfectBlocks >= 10,
  ),
  Ribbon(
    'neat30',
    'Even Hand',
    'Bind 30 blocks at par.',
    (s) => s.perfectBlocks >= 30,
  ),
  Ribbon(
    'daily1',
    'Daily Darning',
    'Finish a Pattern of the Day.',
    (s) => s.dailyDone >= 1,
  ),
  Ribbon(
    'streak7',
    'Week of Stitches',
    'Keep a 7-day daily streak.',
    (s) => s.bestStreak >= 7,
  ),
  Ribbon(
    'sewn200',
    'Busy Needle',
    'Sew 200 patches in all.',
    (s) => s.statSewn >= 200,
  ),
  Ribbon(
    'heirloom',
    'Heirloom',
    'Bind every block at par.',
    (s) => s.perfectBlocks >= allLevels.length,
  ),
];

const _chapterRibbon = [
  'Threaded',
  'Square Corners',
  'Button Box',
  'True Seams',
  'Finished Quilt',
];
