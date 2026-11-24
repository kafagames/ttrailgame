import 'board.dart';

class SolveResult {
  const SolveResult(this.moves, this.nodes, {this.exhausted = false});

  /// Patches to add, in order. Null when no solution was found.
  final List<Placement>? moves;
  final int nodes;

  /// True when the node budget ran out before the search finished.
  final bool exhausted;

  bool get solved => moves != null;
  int get length => moves?.length ?? -1;
}

/// Finds the fewest extra patches that bind a board.
///
/// Iterative deepening over placements that touch the spool's sewn region.
/// That restriction keeps the search complete: any binding set of patches
/// contains a minimal connected subset holding the spool, and that subset can
/// always be laid down one touching patch at a time.
class Solver {
  Solver(this.board, List<TrayPiece> tray, {this.nodeBudget = 2000000}) {
    for (final p in tray) {
      final k = _kinds.indexOf(p);
      if (k < 0) {
        _kinds.add(p);
        _counts.add(1);
      } else {
        _counts[k]++;
      }
    }
  }

  final Board board;
  final int nodeBudget;
  final List<TrayPiece> _kinds = [];
  final List<int> _counts = [];
  int _nodes = 0;
  bool _out = false;
  final Map<String, int> _failed = {};
  final List<Placement> _stack = [];

  SolveResult solve({int? maxDepth}) {
    final limit = maxDepth ?? _counts.fold<int>(0, (a, b) => a + b);
    if (board.isBound) return SolveResult(const [], 0);
    for (var depth = _lowerBound(); depth <= limit; depth++) {
      _failed.clear();
      if (_dfs(depth)) {
        return SolveResult(List.of(_stack), _nodes);
      }
      if (_out) return SolveResult(null, _nodes, exhausted: true);
    }
    return SolveResult(null, _nodes);
  }

  bool _dfs(int left) {
    if (board.isBound) return true;
    if (left == 0) return false;
    if (++_nodes > nodeBudget) {
      _out = true;
      return false;
    }
    if (_lowerBound() > left) return false;
    final key = _key();
    final seen = _failed[key];
    if (seen != null && seen >= left) return false;

    final comp = board.spoolComponent();
    final frontier = <int>{};
    for (final i in comp) {
      final x = i % board.width, y = i ~/ board.width;
      for (final (nx, ny) in [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]) {
        if (!board.inBounds(nx, ny)) continue;
        final n = board.index(nx, ny);
        if (board.isOpen(n)) frontier.add(n);
      }
    }

    final tried = <String>{};
    for (var k = 0; k < _kinds.length; k++) {
      if (_counts[k] == 0) continue;
      final piece = _kinds[k];
      final shape = piece.shape;
      for (var r = 0; r < shape.rotationCount; r++) {
        final cells = shape.cellsFor(r);
        for (final f in frontier) {
          final fx = f % board.width, fy = f ~/ board.width;
          for (final c in cells) {
            final ax = fx - c.$1, ay = fy - c.$2;
            final sig = '$k:$r:$ax:$ay';
            if (!tried.add(sig)) continue;
            if (!board.canPlace(piece, r, ax, ay)) continue;
            board.place(piece, r, ax, ay);
            _counts[k]--;
            _stack.add(Placement(piece, r, ax, ay));
            if (_dfs(left - 1)) return true;
            _stack.removeLast();
            _counts[k]++;
            board.unpickLast();
            if (_out) return false;
          }
        }
      }
    }
    _failed[key] = left;
    return false;
  }

  String _key() {
    final codes = List<int>.generate(
      board.owner.length,
      (i) => 48 + board.fabricAt(i) + 1,
    );
    return '${String.fromCharCodes(codes)}|${_counts.join(',')}';
  }

  /// Patches still needed, at least: open squares that must be covered to
  /// reach the farthest target, filled greedily with the biggest pieces left.
  int _lowerBound() {
    final need = _coverNeeded();
    if (need <= 0) return need == 0 ? 0 : 1;
    final sizes = <int>[];
    for (var k = 0; k < _kinds.length; k++) {
      for (var n = 0; n < _counts[k]; n++) {
        sizes.add(_kinds[k].shape.size);
      }
    }
    sizes.sort((a, b) => b - a);
    var sum = 0, count = 0;
    for (final s in sizes) {
      sum += s;
      count++;
      if (sum >= need) return count;
    }
    return 1 << 20; // not enough fabric left
  }

  /// 0-1 BFS from the spool region: covered squares cost 0, open squares 1.
  /// Returns the largest cost among thimble and buttons (-1 = already bound
  /// targets but not connected, which still needs one patch).
  int _coverNeeded() {
    final n = board.owner.length;
    final dist = List<int>.filled(n, 1 << 20);
    final deque = <int>[];
    var head = 0;
    for (final i in board.spoolComponent()) {
      dist[i] = 0;
      deque.add(i);
    }
    // Small grids: a simple label-correcting pass is fast enough.
    while (head < deque.length) {
      final i = deque[head++];
      final x = i % board.width, y = i ~/ board.width;
      for (final (nx, ny) in [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]) {
        if (!board.inBounds(nx, ny)) continue;
        final m = board.index(nx, ny);
        final int step;
        if (board.isSewn(m)) {
          step = 0;
        } else if (board.isOpen(m)) {
          step = 1;
        } else {
          continue;
        }
        final d = dist[i] + step;
        if (d < dist[m]) {
          dist[m] = d;
          deque.add(m);
        }
      }
    }
    var worst = dist[board.thimble];
    for (final b in board.buttons) {
      if (dist[b] > worst) worst = dist[b];
    }
    if (worst == 0 && !board.isBound) return -1;
    return worst;
  }
}

/// Convenience: fewest patches for a fresh level.
SolveResult solveLevel(Level level, {int nodeBudget = 2000000}) =>
    Solver(Board(level), level.tray, nodeBudget: nodeBudget).solve();
