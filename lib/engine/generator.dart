import 'dart:math';

import 'board.dart';
import 'shapes.dart';
import 'solver.dart';

/// Knobs for one generated puzzle.
class GenSpec {
  const GenSpec({
    required this.width,
    required this.height,
    required this.shapes,
    required this.minPar,
    required this.maxPar,
    this.fabrics = 3,
    this.decoys = 1,
    this.buttons = 0,
    this.fixedPieces = 0,
    this.seams = false,
    this.batting = 0.45,
    this.wander = 0.3,
    this.waypoints = 0,
    this.nodeBudget = 80000,
  });

  final int width;
  final int height;
  final List<PatchShape> shapes;
  final int minPar;
  final int maxPar;
  final int fabrics;
  final int decoys;
  final int buttons;
  final int fixedPieces;
  final bool seams;

  /// Chance an unused square becomes batting.
  final double batting;

  /// 0 = trail heads straight for its target, 1 = it meanders a lot.
  final double wander;

  /// Hidden squares the trail must bend through before the thimble.
  final int waypoints;
  final int nodeBudget;
}

/// Builds puzzles by sewing a random trail first, then hiding it: unused
/// squares become batting, a few pieces become pre-sewn squares, decoy
/// pieces join the tray, and the solver proves the true par.
class LevelGenerator {
  LevelGenerator(int seed) : _rnd = Random(seed);
  final Random _rnd;

  /// Tries up to [attempts] boards and returns the hardest valid one, scored
  /// by par then search effort. Null if none passed.
  Level? generate(
    GenSpec spec, {
    required int id,
    required String name,
    required int chapter,
    int attempts = 40,
  }) {
    Level? best;
    var bestScore = -1.0;
    for (var a = 0; a < attempts; a++) {
      final lv = _attempt(spec, id: id, name: name, chapter: chapter);
      if (lv == null) continue;
      final res = Solver(
        Board(lv),
        lv.tray,
        nodeBudget: spec.nodeBudget,
      ).solve();
      if (!res.solved || res.length < spec.minPar || res.length > spec.maxPar) {
        continue;
      }
      final finalLevel = Level(
        id: lv.id,
        name: lv.name,
        chapter: lv.chapter,
        rows: lv.rows,
        tray: lv.tray,
        par: res.length,
        seams: lv.seams,
      );
      final score = res.length * 100.0 + log(res.nodes + 1) * 40;
      if (score > bestScore) {
        bestScore = score;
        best = finalLevel;
      }
    }
    return best;
  }

  Level? _attempt(
    GenSpec s, {
    required int id,
    required String name,
    required int chapter,
  }) {
    final w = s.width, h = s.height;
    // Spool and thimble far apart.
    int sx, sy, tx, ty;
    var guard = 0;
    do {
      sx = _rnd.nextInt(w);
      sy = _rnd.nextInt(h);
      tx = _rnd.nextInt(w);
      ty = _rnd.nextInt(h);
      if (++guard > 200) return null;
    } while ((sx - tx).abs() + (sy - ty).abs() < (w + h) ~/ 2);

    final grid = List.generate(h, (_) => List.filled(w, '.'));
    grid[sy][sx] = 'S';
    grid[ty][tx] = 'T';

    final fabrics = List<Fabric>.of(Fabric.values)..shuffle(_rnd);
    final palette = fabrics.take(s.fabrics).toList();

    // Grow a trail toward the thimble on an open board, bending through
    // hidden waypoints first.
    var level = _wrap(grid, const [], s, id, name, chapter);
    var board = Board(level);
    final used = <TrayPiece>[];
    var steps = 0;
    for (var wp = 0; wp < s.waypoints; wp++) {
      final target = _pickWaypoint(board);
      if (target == null) return null;
      var g = 0;
      while (!board.spoolComponent().contains(target)) {
        if (++g > 4) return null;
        final mv = _growToward(board, s, palette, target);
        if (mv == null) return null;
        board.place(mv.piece, mv.rotation, mv.x, mv.y);
        used.add(mv.piece);
        steps++;
      }
    }
    while (!board.spoolComponent().contains(board.thimble)) {
      if (++steps > s.maxPar + 3) return null;
      final mv = _growToward(board, s, palette, board.thimble);
      if (mv == null) return null;
      board.place(mv.piece, mv.rotation, mv.x, mv.y);
      used.add(mv.piece);
    }

    // Branch out to button squares.
    for (var b = 0; b < s.buttons; b++) {
      final target = _pickButtonTarget(board);
      if (target == null) return null;
      var g = 0;
      while (!board.spoolComponent().contains(target)) {
        if (++g > 3) return null;
        final mv = _growToward(board, s, palette, target);
        if (mv == null) return null;
        board.place(mv.piece, mv.rotation, mv.x, mv.y);
        used.add(mv.piece);
      }
      final bx = target % w, by = target ~/ w;
      grid[by][bx] = 'o';
    }
    if (used.length > s.maxPar + s.fixedPieces + 1) return null;

    // Turn a few trail pieces into pre-sewn squares.
    final fixedIdx = <int>{};
    final order = List<int>.generate(board.placements.length, (i) => i)
      ..shuffle(_rnd);
    for (final i in order) {
      if (fixedIdx.length >= s.fixedPieces) break;
      fixedIdx.add(i);
    }
    final trayFromTrail = <TrayPiece>[];
    for (var i = 0; i < board.placements.length; i++) {
      final p = board.placements[i];
      if (fixedIdx.contains(i)) {
        for (final (cx, cy) in p.cells) {
          if (grid[cy][cx] == '.') {
            grid[cy][cx] = '${p.piece.fabric.index + 1}';
          }
        }
      } else {
        trayFromTrail.add(p.piece);
      }
    }

    // Batting on unused squares.
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (grid[y][x] != '.') continue;
        if (board.owner[board.index(x, y)] >= 0) continue;
        if (_rnd.nextDouble() < s.batting) grid[y][x] = '#';
      }
    }

    final tray = <TrayPiece>[...trayFromTrail];
    for (var d = 0; d < s.decoys; d++) {
      tray.add(
        TrayPiece(
          s.shapes[_rnd.nextInt(s.shapes.length)],
          palette[_rnd.nextInt(palette.length)],
        ),
      );
    }
    tray.shuffle(_rnd);
    if (tray.isEmpty) return null;
    level = _wrap(grid, tray, s, id, name, chapter);
    return level;
  }

  Level _wrap(
    List<List<String>> grid,
    List<TrayPiece> tray,
    GenSpec s,
    int id,
    String name,
    int chapter,
  ) => Level(
    id: id,
    name: name,
    chapter: chapter,
    rows: grid.map((r) => r.join()).toList(),
    tray: tray,
    par: 0,
    seams: s.seams,
  );

  /// An open square 3–4 steps from the trail that does not move it closer
  /// to the thimble, so the route has to bend.
  int? _pickWaypoint(Board board) {
    final comp = board.spoolComponent();
    final tx = board.thimble % board.width, ty = board.thimble ~/ board.width;
    var near = 99;
    for (final c in comp) {
      final d = (c % board.width - tx).abs() + (c ~/ board.width - ty).abs();
      if (d < near) near = d;
    }
    final options = <int>[];
    for (var i = 0; i < board.owner.length; i++) {
      if (!board.isOpen(i) || board.ground[i] != Ground.empty) continue;
      final x = i % board.width, y = i ~/ board.width;
      var best = 99;
      for (final c in comp) {
        final d = (c % board.width - x).abs() + (c ~/ board.width - y).abs();
        if (d < best) best = d;
      }
      final toT = (x - tx).abs() + (y - ty).abs();
      if (best >= 3 && best <= 4 && toT >= near - 1 && toT >= 3) options.add(i);
    }
    if (options.isEmpty) return null;
    return options[_rnd.nextInt(options.length)];
  }

  int? _pickButtonTarget(Board board) {
    final comp = board.spoolComponent();
    final options = <int>[];
    for (var i = 0; i < board.owner.length; i++) {
      if (!board.isOpen(i) || board.ground[i] != Ground.empty) continue;
      final x = i % board.width, y = i ~/ board.width;
      var best = 99;
      for (final c in comp) {
        final d = (c % board.width - x).abs() + (c ~/ board.width - y).abs();
        if (d < best) best = d;
      }
      if (best >= 2 && best <= 3) options.add(i);
    }
    if (options.isEmpty) return null;
    return options[_rnd.nextInt(options.length)];
  }

  /// A random touching placement, biased to close distance to [target].
  Placement? _growToward(
    Board board,
    GenSpec s,
    List<Fabric> palette,
    int target,
  ) {
    final comp = board.spoolComponent();
    final tx = target % board.width, ty = target ~/ board.width;
    final options = <(double, Placement)>[];
    for (final i in comp) {
      final x = i % board.width, y = i ~/ board.width;
      for (final (nx, ny) in [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]) {
        if (!board.inBounds(nx, ny)) continue;
        if (!board.isOpen(board.index(nx, ny))) continue;
        for (final shape in s.shapes) {
          final fabric = palette[_rnd.nextInt(palette.length)];
          final piece = TrayPiece(shape, fabric);
          for (var r = 0; r < shape.rotationCount; r++) {
            for (final c in shape.cellsFor(r)) {
              final ax = nx - c.$1, ay = ny - c.$2;
              if (!board.canPlace(piece, r, ax, ay)) continue;
              final p = Placement(piece, r, ax, ay);
              var bestD = 99;
              for (final (cx, cy) in p.cells) {
                final d = (cx - tx).abs() + (cy - ty).abs();
                if (d < bestD) bestD = d;
              }
              options.add((
                bestD + _rnd.nextDouble() * (1.5 + s.wander * 9),
                p,
              ));
            }
          }
        }
      }
    }
    if (options.isEmpty) return null;
    options.sort((a, b) => a.$1.compareTo(b.$1));
    return options.first.$2;
  }
}

/// Offline daily puzzle, seeded by the calendar date.
Level dailyLevel(DateTime day) {
  final seed = day.year * 10000 + day.month * 100 + day.day;
  final rnd = Random(seed);
  final variants = [
    const GenSpec(
      width: 6,
      height: 6,
      shapes: [PatchShape.rail, PatchShape.corner, PatchShape.snip],
      minPar: 3,
      maxPar: 5,
      decoys: 2,
      nodeBudget: 40000,
    ),
    const GenSpec(
      width: 6,
      height: 6,
      shapes: [PatchShape.rail, PatchShape.corner, PatchShape.block],
      minPar: 3,
      maxPar: 5,
      decoys: 2,
      buttons: 1,
      nodeBudget: 40000,
    ),
    const GenSpec(
      width: 6,
      height: 6,
      shapes: [PatchShape.rail, PatchShape.corner, PatchShape.tee],
      minPar: 3,
      maxPar: 5,
      decoys: 2,
      seams: true,
      nodeBudget: 40000,
    ),
  ];
  final spec = variants[rnd.nextInt(variants.length)];
  for (var salt = 0; salt < 20; salt++) {
    final lv = LevelGenerator(seed * 31 + salt).generate(
      spec,
      id: 1000,
      name: 'Pattern of the Day',
      chapter: -1,
      attempts: 6,
    );
    if (lv != null) return lv;
  }
  // Extremely unlikely fallback: a fixed gentle board.
  return const Level(
    id: 1000,
    name: 'Pattern of the Day',
    chapter: -1,
    rows: ['S....#', '.##...', '....#.', '.#....', '...#.T', '#.....'],
    tray: [
      TrayPiece(PatchShape.rail, Fabric.rose),
      TrayPiece(PatchShape.corner, Fabric.sage),
      TrayPiece(PatchShape.rail, Fabric.chambray),
      TrayPiece(PatchShape.corner, Fabric.rose),
      TrayPiece(PatchShape.snip, Fabric.sage),
    ],
    par: 3,
  );
}
