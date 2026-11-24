import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/board.dart';
import '../engine/shapes.dart';
import '../ui/art.dart';
import '../ui/palette.dart';

/// A patch hovering over the board before it is sewn.
class Ghost {
  const Ghost(this.placement, this.ok);
  final Placement placement;
  final bool ok;
}

/// Paints the quilt on its cutting mat and reports where the finger is.
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.board,
    this.ghost,
    this.hint,
    this.hintPulse = 0,
    this.drop = 1,
    this.trail = 0,
    this.onAim,
    this.onCommit,
    this.semanticsLabel,
  });

  final Board board;
  final Ghost? ghost;
  final Placement? hint;
  final double hintPulse;

  /// 0→1 settle animation for the most recent placement.
  final double drop;

  /// 0→1 thread running along the finished trail.
  final double trail;
  final void Function((int, int)? cell)? onAim;
  final void Function((int, int) cell)? onCommit;
  final String? semanticsLabel;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  (int, int)? _last;
  int? _pointer;

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    return LayoutBuilder(
      builder: (context, box) {
        const margin = 12.0;
        final cell = math.min(
          (box.maxWidth - margin * 2) / board.width,
          (box.maxHeight - margin * 2) / board.height,
        );
        final w = cell * board.width + margin * 2;
        final h = cell * board.height + margin * 2;
        (int, int)? hit(Offset local) {
          final x = ((local.dx - margin) / cell).floor();
          final y = ((local.dy - margin) / cell).floor();
          if (!board.inBounds(x, y)) return null;
          return (x, y);
        }

        return Center(
          child: Semantics(
            label: widget.semanticsLabel,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                if (_pointer != null) return;
                _pointer = e.pointer;
                widget.onAim?.call(_last = hit(e.localPosition));
              },
              onPointerMove: (e) {
                if (e.pointer != _pointer) return;
                final c = hit(e.localPosition);
                if (c != _last) widget.onAim?.call(_last = c);
              },
              onPointerUp: (e) {
                if (e.pointer != _pointer) return;
                _pointer = null;
                final c = _last;
                _last = null;
                widget.onAim?.call(null);
                if (c != null) widget.onCommit?.call(c);
              },
              onPointerCancel: (e) {
                if (e.pointer != _pointer) return;
                _pointer = null;
                _last = null;
                widget.onAim?.call(null);
              },
              child: CustomPaint(
                size: Size(w, h),
                painter: _BoardPainter(
                  board: board,
                  cell: cell,
                  margin: margin,
                  ghost: widget.ghost,
                  hint: widget.hint,
                  hintPulse: widget.hintPulse,
                  drop: widget.drop,
                  trail: widget.trail,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.board,
    required this.cell,
    required this.margin,
    required this.ghost,
    required this.hint,
    required this.hintPulse,
    required this.drop,
    required this.trail,
  }) : _sig = _signature(board);

  final Board board;
  final double cell;
  final double margin;
  final Ghost? ghost;
  final Placement? hint;
  final double hintPulse;
  final double drop;
  final double trail;
  final String _sig;

  static String _signature(Board b) => b.placements.join('|');

  Rect cellRect(int x, int y) =>
      Rect.fromLTWH(margin + x * cell, margin + y * cell, cell, cell);

  @override
  void paint(Canvas canvas, Size size) {
    final printScale = (cell / 128).clamp(0.22, 0.6);
    // Cutting mat with its measuring grid.
    final mat = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    canvas.drawRRect(
      mat.shift(const Offset(0, 4)),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(mat, Paint()..color = Hue.mat);
    final line = Paint()
      ..color = Hue.matLine.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var t = 6.0; t < size.width; t += cell / 2) {
      canvas.drawLine(Offset(t, 3), Offset(t, 9), line);
      canvas.drawLine(
        Offset(t, size.height - 9),
        Offset(t, size.height - 3),
        line,
      );
    }

    final muslin = Art.texturePaint(Art.muslin, Hue.muslin, scale: printScale);
    final batting = Art.texturePaint(
      Art.batting,
      Hue.plaster,
      scale: printScale,
    );
    final seam = Paint()
      ..color = Hue.thread.withValues(alpha: 0.18)
      ..strokeWidth = 1;

    for (var y = 0; y < board.height; y++) {
      for (var x = 0; x < board.width; x++) {
        final i = board.index(x, y);
        final r = cellRect(x, y);
        switch (board.ground[i]) {
          case Ground.batting:
            canvas.drawRect(r, batting);
            canvas.drawRect(r, Paint()..color = const Color(0x1F3B2F28));
            canvas.drawRect(
              r.deflate(1.5),
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3
                ..color = const Color(0x22000000)
                ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 3),
            );
          case Ground.fixed:
            canvas.drawRect(
              r,
              Art.fabricPaint(board.fixedFabric[i], scale: printScale),
            );
          default:
            canvas.drawRect(r, muslin);
            canvas.drawRect(r, seam..style = PaintingStyle.stroke);
        }
      }
    }
    _fixedStitching(canvas);

    // Player patches with a soft lift.
    for (var k = 0; k < board.placements.length; k++) {
      final p = board.placements[k];
      final isLast = k == board.placements.length - 1;
      _patch(canvas, p, printScale, lift: isLast ? (1 - drop) : 0, alpha: 1);
    }

    // Spool, thimble and buttons always sit on top of fabric.
    for (var y = 0; y < board.height; y++) {
      for (var x = 0; x < board.width; x++) {
        final i = board.index(x, y);
        final r = cellRect(x, y);
        switch (board.ground[i]) {
          case Ground.spool:
            Art.sprite(canvas, Art.spool, r.deflate(cell * 0.04));
          case Ground.thimble:
            Art.sprite(canvas, Art.thimble, r.deflate(cell * 0.06));
          case Ground.button:
            final covered = board.owner[i] >= 0;
            Art.sprite(
              canvas,
              Art.button,
              r.deflate(cell * (covered ? 0.16 : 0.2)),
            );
            if (!covered) {
              canvas.drawCircle(
                r.center,
                cell * 0.38,
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1.6
                  ..color = Hue.thread.withValues(alpha: 0.5),
              );
            }
          default:
        }
      }
    }

    if (hint != null) {
      final glow =
          0.45 + 0.55 * (0.5 + 0.5 * math.sin(hintPulse * math.pi * 2));
      _outline(
        canvas,
        hint!.cells,
        Hue.brass.withValues(alpha: glow),
        3,
        dashed: false,
      );
    }
    final g = ghost;
    if (g != null) {
      final inside = g.placement.cells
          .where((c) => board.inBounds(c.$1, c.$2))
          .toList();
      for (final (x, y) in inside) {
        canvas.drawRect(
          cellRect(x, y),
          Art.fabricPaint(
            g.placement.piece.fabric.index,
            scale: printScale,
            alpha: g.ok ? 0.7 : 0.35,
          ),
        );
      }
      _outline(
        canvas,
        inside,
        g.ok ? Hue.walnut : Hue.redThread,
        2.4,
        dashed: !g.ok,
      );
    }
    if (trail > 0) _trail(canvas);
  }

  void _patch(
    Canvas canvas,
    Placement p,
    double printScale, {
    required double lift,
    required double alpha,
  }) {
    final path = Path();
    for (final (x, y) in p.cells) {
      path.addRect(cellRect(x, y));
    }
    final dy = 2 + lift * 6;
    canvas.save();
    if (lift > 0) {
      final b = path.getBounds();
      final s = 1 + lift * 0.06;
      canvas.translate(b.center.dx, b.center.dy - lift * 4);
      canvas.scale(s);
      canvas.translate(-b.center.dx, -b.center.dy);
    }
    canvas.drawPath(
      path.shift(Offset(0, dy)),
      Paint()
        ..color = Color.fromRGBO(40, 24, 12, 0.28 + lift * 0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + lift * 4),
    );
    canvas.drawPath(
      path,
      Art.fabricPaint(p.piece.fabric.index, scale: printScale, alpha: alpha),
    );
    // Light catches the top edge; folded seam darkens the bottom.
    final b = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0x1FFFFFFF),
            Color(0x00FFFFFF),
            Color(0x1A000000),
          ],
        ).createShader(b),
    );
    _stitchOutline(
      canvas,
      p.cells,
      const Color(0xCCFFF8EC),
      inset: cell * 0.09,
    );
    canvas.restore();
  }

  void _fixedStitching(Canvas canvas) {
    // Pre-sewn squares: running stitch around each fabric group plus a
    // diagonal hand-quilting line, so they read as already finished.
    final groups = <int, List<(int, int)>>{};
    for (var y = 0; y < board.height; y++) {
      for (var x = 0; x < board.width; x++) {
        final i = board.index(x, y);
        if (board.ground[i] != Ground.fixed) continue;
        groups.putIfAbsent(board.fixedFabric[i], () => []).add((x, y));
        final r = cellRect(x, y);
        final q = Paint()
          ..color = Hue.walnut.withValues(alpha: 0.35)
          ..strokeWidth = 1.2;
        _dash(
          canvas,
          r.topLeft + Offset(cell * .2, cell * .2),
          r.bottomRight - Offset(cell * .2, cell * .2),
          q,
          cell * 0.09,
        );
      }
    }
    for (final cells in groups.values) {
      _stitchOutline(
        canvas,
        cells,
        Hue.walnut.withValues(alpha: 0.75),
        inset: cell * 0.1,
      );
    }
  }

  void _stitchOutline(
    Canvas canvas,
    List<(int, int)> cells,
    Color color, {
    required double inset,
  }) {
    final set = cells.toSet();
    final p = Paint()
      ..color = color
      ..strokeWidth = math.max(1.3, cell * 0.035)
      ..strokeCap = StrokeCap.round;
    final dash = cell * 0.1;
    for (final (x, y) in cells) {
      final r = cellRect(x, y);
      final inner = r.deflate(inset);
      if (!set.contains((x, y - 1))) {
        _dash(
          canvas,
          Offset(set.contains((x - 1, y)) ? r.left : inner.left, inner.top),
          Offset(set.contains((x + 1, y)) ? r.right : inner.right, inner.top),
          p,
          dash,
        );
      }
      if (!set.contains((x, y + 1))) {
        _dash(
          canvas,
          Offset(set.contains((x - 1, y)) ? r.left : inner.left, inner.bottom),
          Offset(
            set.contains((x + 1, y)) ? r.right : inner.right,
            inner.bottom,
          ),
          p,
          dash,
        );
      }
      if (!set.contains((x - 1, y))) {
        _dash(
          canvas,
          Offset(inner.left, set.contains((x, y - 1)) ? r.top : inner.top),
          Offset(
            inner.left,
            set.contains((x, y + 1)) ? r.bottom : inner.bottom,
          ),
          p,
          dash,
        );
      }
      if (!set.contains((x + 1, y))) {
        _dash(
          canvas,
          Offset(inner.right, set.contains((x, y - 1)) ? r.top : inner.top),
          Offset(
            inner.right,
            set.contains((x, y + 1)) ? r.bottom : inner.bottom,
          ),
          p,
          dash,
        );
      }
    }
  }

  void _outline(
    Canvas canvas,
    List<(int, int)> cells,
    Color color,
    double width, {
    required bool dashed,
  }) {
    final set = cells.toSet();
    final p = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    void seg(Offset a, Offset b) =>
        dashed ? _dash(canvas, a, b, p, cell * 0.12) : canvas.drawLine(a, b, p);
    for (final (x, y) in cells) {
      final r = cellRect(x, y);
      if (!set.contains((x, y - 1))) seg(r.topLeft, r.topRight);
      if (!set.contains((x, y + 1))) seg(r.bottomLeft, r.bottomRight);
      if (!set.contains((x - 1, y))) seg(r.topLeft, r.bottomLeft);
      if (!set.contains((x + 1, y))) seg(r.topRight, r.bottomRight);
    }
  }

  void _dash(Canvas canvas, Offset a, Offset b, Paint p, double dash) {
    final len = (b - a).distance;
    if (len <= 0) return;
    final dir = (b - a) / len;
    for (var t = dash * 0.3; t < len; t += dash * 2) {
      canvas.drawLine(a + dir * t, a + dir * math.min(len, t + dash), p);
    }
  }

  void _trail(Canvas canvas) {
    final cells = board.trail();
    if (cells.length < 2) return;
    final pts = cells
        .map((i) => cellRect(i % board.width, i ~/ board.width).center)
        .toList();
    final total = pts.length - 1;
    final reach = trail * total;
    final p = Paint()
      ..color = Hue.walnut
      ..strokeWidth = math.max(2.2, cell * 0.06)
      ..strokeCap = StrokeCap.round;
    Offset head = pts.first;
    for (var k = 0; k < total; k++) {
      if (k >= reach) break;
      final f = math.min(1.0, reach - k);
      final a = pts[k], b = Offset.lerp(pts[k], pts[k + 1], f)!;
      _dash(canvas, a, b, p, cell * 0.14);
      head = b;
    }
    if (trail < 1) {
      canvas.drawCircle(
        head,
        cell * 0.16,
        Paint()
          ..color = Hue.brass.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old._sig != _sig ||
      old.ghost != ghost ||
      old.hint != hint ||
      old.hintPulse != hintPulse ||
      old.drop != drop ||
      old.trail != trail ||
      old.cell != cell;
}

/// A tray patch drawn on its own (tray and guide diagrams).
class PatchSwatch extends StatelessWidget {
  const PatchSwatch({
    super.key,
    required this.piece,
    required this.rotation,
    this.cell = 20,
  });
  final TrayPiece piece;
  final int rotation;
  final double cell;

  @override
  Widget build(BuildContext context) {
    final cells = piece.shape.cellsFor(rotation);
    final w = cells.map((c) => c.$1).reduce(math.max) + 1;
    final h = cells.map((c) => c.$2).reduce(math.max) + 1;
    return CustomPaint(
      size: Size(w * cell, h * cell),
      painter: _SwatchPainter(piece, cells, cell),
    );
  }
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.piece, this.cells, this.cell);
  final TrayPiece piece;
  final List<Cell> cells;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (final (x, y) in cells) {
      path.addRect(Rect.fromLTWH(x * cell, y * cell, cell, cell));
    }
    canvas.drawPath(
      path.shift(const Offset(0, 2.5)),
      Paint()
        ..color = const Color(0x55301A0C)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(
      path,
      Art.fabricPaint(piece.fabric.index, scale: (cell / 128).clamp(0.2, 0.5)),
    );
    final set = cells.toSet();
    final p = Paint()
      ..color = const Color(0xCCFFF8EC)
      ..strokeWidth = 1.3;
    final inset = cell * 0.12;
    for (final (x, y) in cells) {
      final r = Rect.fromLTWH(x * cell, y * cell, cell, cell).deflate(inset);
      void dash(Offset a, Offset b) {
        final len = (b - a).distance;
        final dir = (b - a) / len;
        for (var t = 0.0; t < len; t += cell * 0.2) {
          canvas.drawLine(
            a + dir * t,
            a + dir * math.min(len, t + cell * 0.1),
            p,
          );
        }
      }

      if (!set.contains((x, y - 1))) dash(r.topLeft, r.topRight);
      if (!set.contains((x, y + 1))) dash(r.bottomLeft, r.bottomRight);
      if (!set.contains((x - 1, y))) dash(r.topLeft, r.bottomLeft);
      if (!set.contains((x + 1, y))) dash(r.topRight, r.bottomRight);
    }
  }

  @override
  bool shouldRepaint(_SwatchPainter old) =>
      old.piece != piece || old.cells != cells || old.cell != cell;
}
