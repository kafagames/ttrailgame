/// The five chapters. Each one teaches something new.
class Chapter {
  const Chapter(this.name, this.note, this.fabrics);

  final String name;

  /// Shown once on the chapter's first block.
  final String note;

  /// Fabric indexes used for this chapter's blocks on the hub quilt.
  final List<int> fabrics;
}

const chapters = [
  Chapter(
    'First Stitches',
    'Lay patches from the spool to the thimble. Fewer patches earns more stars.',
    [0, 3],
  ),
  Chapter(
    'Turning Corners',
    'Corner and Block patches arrive. Tap a patch in the tray again to turn it.',
    [1, 2],
  ),
  Chapter(
    'Buttons',
    'Buttons must be sewn under fabric and joined to the trail before the quilt binds.',
    [2, 3],
  ),
  Chapter(
    'Matching Seams',
    'On these quilts, two patches of the same fabric may never touch side by side.',
    [4, 0],
  ),
  Chapter(
    'The Heirloom',
    'Every technique at once, on the biggest frames. Take your time.',
    [0, 1, 4],
  ),
];

class TableCover {
  const TableCover(this.id, this.name, this.stars);
  final String id;
  final String name;

  /// Total stars needed to unlock.
  final int stars;
}

const tableCovers = [
  TableCover('maple', 'Maple bench', 0),
  TableCover('gingham', 'Picnic gingham', 30),
  TableCover('walnut', 'Walnut desk', 70),
  TableCover('indigo', 'Indigo sashiko', 115),
];
