import 'shapes.dart';

/// What sits on a grid square before any patch is placed.
enum Ground { empty, batting, spool, thimble, button, fixed }

/// One piece waiting in the tray.
class TrayPiece {
  const TrayPiece(this.shape, this.fabric);
  final PatchShape shape;
  final Fabric fabric;

  @override
  bool operator ==(Object other) =>
      other is TrayPiece && other.shape == shape && other.fabric == fabric;

  @override
  int get hashCode => shape.index * 31 + fabric.index;

  @override
  String toString() => '${shape.name}/${fabric.name}';
}

/// A patch sewn onto the board by the player.
class Placement {
  const Placement(this.piece, this.rotation, this.x, this.y);
  final TrayPiece piece;
  final int rotation;
  final int x;
  final int y;

  List<Cell> get cells => piece.shape
      .cellsFor(rotation)
      .map((c) => (x + c.$1, y + c.$2))
      .toList(growable: false);

  @override
  String toString() => '$piece r$rotation @($x,$y)';
}

/// Static description of a puzzle.
///
/// Row legend: `.` empty, `#` batting (can't be covered), `S` spool,
/// `T` thimble, `o` button (must be covered and joined to the path),
/// `1`–`5` a square already sewn in that fabric (counts as path).
class Level {
  const Level({
    required this.id,
    required this.name,
    required this.chapter,
    required this.rows,
    required this.tray,
    required this.par,
    this.seams = false,
  });

  final int id;
  final String name;
  final int chapter;
  final List<String> rows;
  final List<TrayPiece> tray;

  /// Fewest patches that bind this quilt (proved by the solver).
  final int par;

  /// Matching-seams rule: patches of the same fabric may not share an edge.
  final bool seams;

  int get width => rows.first.length;
  int get height => rows.length;
}

/// Mutable play state for one level. All rules live here.
class Board {
  Board(this.level)
    : width = level.width,
      height = level.height,
      ground = List.filled(level.width * level.height, Ground.empty),
      fixedFabric = List.filled(level.width * level.height, -1),
      owner = List.filled(level.width * level.height, -1) {
    for (var y = 0; y < height; y++) {
      final row = level.rows[y];
      for (var x = 0; x < width; x++) {
        final ch = row[x];
        final i = y * width + x;
        switch (ch) {
          case '#':
            ground[i] = Ground.batting;
          case 'S':
            ground[i] = Ground.spool;
            spool = i;
          case 'T':
            ground[i] = Ground.thimble;
            thimble = i;
          case 'o':
            ground[i] = Ground.button;
            buttons.add(i);
          case '1' || '2' || '3' || '4' || '5':
            ground[i] = Ground.fixed;
            fixedFabric[i] = int.parse(ch) - 1;
          default:
            ground[i] = Ground.empty;
        }
      }
    }
  }

  final Level level;
  final int width;
  final int height;
  final List<Ground> ground;

  /// Fabric index for pre-sewn squares, -1 elsewhere.
  final List<int> fixedFabric;

  /// Index into [placements] covering each square, -1 when uncovered.
  final List<int> owner;
  final List<Placement> placements = [];
  final List<int> buttons = [];
  int spool = 0;
  int thimble = 0;

  bool get seams => level.seams;

  int index(int x, int y) => y * width + x;
  bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < width && y < height;

  /// Fabric showing on a square, or -1 for none.
  int fabricAt(int i) {
    final o = owner[i];
    if (o >= 0) return placements[o].piece.fabric.index;
    return fixedFabric[i];
  }

  /// Squares a thread can run through.
  bool isSewn(int i) =>
      owner[i] >= 0 ||
      ground[i] == Ground.spool ||
      ground[i] == Ground.thimble ||
      ground[i] == Ground.fixed;

  /// A square that can take a new patch.
  bool isOpen(int i) =>
      owner[i] < 0 && (ground[i] == Ground.empty || ground[i] == Ground.button);

  /// Why a placement is refused, or null if it fits.
  PlaceProblem? check(TrayPiece piece, int rotation, int x, int y) {
    final cells = piece.shape.cellsFor(rotation);
    for (final c in cells) {
      final cx = x + c.$1, cy = y + c.$2;
      if (!inBounds(cx, cy)) return PlaceProblem.offEdge;
      if (!isOpen(index(cx, cy))) return PlaceProblem.covered;
    }
    if (seams) {
      final f = piece.fabric.index;
      for (final c in cells) {
        final cx = x + c.$1, cy = y + c.$2;
        for (final (nx, ny) in _around(cx, cy)) {
          if (!inBounds(nx, ny)) continue;
          if (cells.contains((nx - x, ny - y))) continue;
          if (fabricAt(index(nx, ny)) == f) return PlaceProblem.seam;
        }
      }
    }
    return null;
  }

  bool canPlace(TrayPiece piece, int rotation, int x, int y) =>
      check(piece, rotation, x, y) == null;

  /// Sews a patch on. Returns its placement index.
  int place(TrayPiece piece, int rotation, int x, int y) {
    assert(canPlace(piece, rotation, x, y));
    final p = Placement(piece, rotation, x, y);
    placements.add(p);
    final id = placements.length - 1;
    for (final (cx, cy) in p.cells) {
      owner[index(cx, cy)] = id;
    }
    return id;
  }

  /// Unpicks the patch covering square [i]. Returns it, or null.
  Placement? unpickAt(int i) {
    final id = owner[i];
    if (id < 0) return null;
    final removed = placements.removeAt(id);
    for (var k = 0; k < owner.length; k++) {
      if (owner[k] == id) {
        owner[k] = -1;
      } else if (owner[k] > id) {
        owner[k]--;
      }
    }
    return removed;
  }

  /// Unpicks the most recently placed patch.
  Placement? unpickLast() {
    if (placements.isEmpty) return null;
    final p = placements.last;
    final (cx, cy) = p.cells.first;
    return unpickAt(index(cx, cy));
  }

  /// Squares joined to the spool through sewn squares.
  Set<int> spoolComponent() {
    final seen = <int>{spool};
    final queue = <int>[spool];
    while (queue.isNotEmpty) {
      final i = queue.removeLast();
      final x = i % width, y = i ~/ width;
      for (final (nx, ny) in _around(x, y)) {
        if (!inBounds(nx, ny)) continue;
        final n = index(nx, ny);
        if (seen.contains(n) || !isSewn(n)) continue;
        seen.add(n);
        queue.add(n);
      }
    }
    return seen;
  }

  /// Bound: spool reaches thimble, and every button is covered and joined.
  bool get isBound {
    final comp = spoolComponent();
    if (!comp.contains(thimble)) return false;
    for (final b in buttons) {
      if (!comp.contains(b)) return false;
    }
    return true;
  }

  /// The trail itself for the win animation: shortest route through sewn
  /// squares from spool to thimble (empty when not bound).
  List<int> trail() {
    final prev = <int, int>{spool: -1};
    final queue = <int>[spool];
    var head = 0;
    while (head < queue.length) {
      final i = queue[head++];
      if (i == thimble) break;
      final x = i % width, y = i ~/ width;
      for (final (nx, ny) in _around(x, y)) {
        if (!inBounds(nx, ny)) continue;
        final n = index(nx, ny);
        if (prev.containsKey(n) || !isSewn(n)) continue;
        prev[n] = i;
        queue.add(n);
      }
    }
    if (!prev.containsKey(thimble)) return const [];
    final out = <int>[];
    for (var i = thimble; i != -1; i = prev[i]!) {
      out.add(i);
    }
    return out.reversed.toList();
  }

  Board clone() {
    final b = Board(level);
    for (final p in placements) {
      b.place(p.piece, p.rotation, p.x, p.y);
    }
    return b;
  }

  static List<Cell> _around(int x, int y) => [
    (x + 1, y),
    (x - 1, y),
    (x, y + 1),
    (x, y - 1),
  ];
}

enum PlaceProblem { offEdge, covered, seam }

/// Star rule, shared by the game and tests.
/// ★ bound · ★★ within one patch of par · ★★★ at par.
int starsFor({required bool bound, required int used, required int par}) {
  if (!bound) return 0;
  if (used <= par) return 3;
  if (used <= par + 1) return 2;
  return 1;
}
