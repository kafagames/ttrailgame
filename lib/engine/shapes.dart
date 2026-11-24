/// Patch shapes and fabrics. Pure Dart, no Flutter imports, so the engine,
/// solver and level generator can run in tests and in `dart run tool/...`.
library;

typedef Cell = (int, int);

enum PatchShape {
  /// Two squares.
  snip('Snip', [(0, 0), (1, 0)]),

  /// Three in a row.
  rail('Rail', [(0, 0), (1, 0), (2, 0)]),

  /// Three squares bent into an L.
  corner('Corner', [(0, 0), (0, 1), (1, 1)]),

  /// Two by two.
  block('Block', [(0, 0), (1, 0), (0, 1), (1, 1)]),

  /// Three in a row with one hanging below the middle.
  tee('Tee', [(0, 0), (1, 0), (2, 0), (1, 1)]),

  /// A stepped four, like a flying-geese offset.
  step('Step', [(1, 0), (2, 0), (0, 1), (1, 1)]);

  const PatchShape(this.label, this.base);

  final String label;
  final List<Cell> base;

  int get size => base.length;

  /// Distinct rotations (90° clockwise each), every one normalised so its
  /// smallest x and y are 0. Symmetric shapes return fewer than four.
  List<List<Cell>> get rotations => _rotationCache[this] ??= _buildRotations();

  /// Number of distinct orientations; turning past the last wraps to 0.
  int get rotationCount => rotations.length;

  List<Cell> cellsFor(int rotation) => rotations[rotation % rotationCount];

  List<List<Cell>> _buildRotations() {
    final out = <List<Cell>>[];
    final seen = <String>{};
    var cells = List<Cell>.from(base);
    for (var i = 0; i < 4; i++) {
      final norm = _normalise(cells);
      final key = norm.map((c) => '${c.$1},${c.$2}').join(';');
      if (seen.add(key)) out.add(norm);
      // Rotate clockwise in screen space (y down): (x, y) -> (-y, x).
      cells = cells.map((c) => (-c.$2, c.$1)).toList();
    }
    return out;
  }

  static List<Cell> _normalise(List<Cell> cells) {
    var minX = cells.first.$1, minY = cells.first.$2;
    for (final c in cells) {
      if (c.$1 < minX) minX = c.$1;
      if (c.$2 < minY) minY = c.$2;
    }
    final out = cells.map((c) => (c.$1 - minX, c.$2 - minY)).toList()
      ..sort((a, b) => a.$2 != b.$2 ? a.$2 - b.$2 : a.$1 - b.$1);
    return out;
  }
}

final Map<PatchShape, List<List<Cell>>> _rotationCache = {};

/// The five fabrics in the workroom. Order is stable: it is saved in level
/// data as an index.
enum Fabric {
  rose('Rose calico'),
  sage('Sage gingham'),
  chambray('Chambray'),
  mustard('Mustard dot'),
  plum('Plum sprig');

  const Fabric(this.label);
  final String label;
}
