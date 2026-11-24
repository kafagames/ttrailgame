import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/chapters.dart';
import '../engine/board.dart';
import '../ui/art.dart';
import '../ui/palette.dart';

enum BlockState { locked, open, sewn }

/// The heirloom quilt on the workroom wall: one block per level, sewn in
/// with a traditional motif when the level is won.
class HeirloomQuilt extends StatelessWidget {
  const HeirloomQuilt({
    super.key,
    required this.levels,
    required this.stateOf,
    required this.starsOf,
    required this.onTap,
    required this.blockSize,
    this.fresh,
    this.freshT = 1,
    this.pulse = 0,
    this.columns = 6,
  });

  final List<Level> levels;
  final BlockState Function(int id) stateOf;
  final int Function(int id) starsOf;
  final void Function(Level level) onTap;
  final double blockSize;

  /// Level just won, animating in with [freshT] 0→1.
  final int? fresh;
  final double freshT;

  /// 0→1 looping value for the waiting block's breathing pin.
  final double pulse;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = (levels.length / columns).ceil();
    const binding = 7.0;
    return Container(
      decoration: BoxDecoration(
        color: Hue.binding,
        boxShadow: const [
          BoxShadow(
            color: Color(0x55301A0C),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
        borderRadius: BorderRadius.circular(3),
      ),
      padding: const EdgeInsets.all(binding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < rows; r++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var c = 0; c < columns; c++)
                  if (r * columns + c < levels.length)
                    _block(levels[r * columns + c]),
              ],
            ),
        ],
      ),
    );
  }

  Widget _block(Level l) {
    final st = stateOf(l.id);
    final stars = starsOf(l.id);
    final chapterName = chapters[l.chapter].name;
    final label = switch (st) {
      BlockState.sewn => 'Block ${l.id}, ${l.name}, $stars of 3 stars',
      BlockState.open => 'Block ${l.id}, ${l.name}, ready to sew',
      BlockState.locked => 'Block ${l.id}, not yet open',
    };
    return Semantics(
      button: true,
      label: '$label. $chapterName.',
      child: GestureDetector(
        onTap: () => onTap(l),
        child: CustomPaint(
          size: Size.square(blockSize),
          painter: _BlockPainter(
            level: l,
            state: st,
            stars: stars,
            appear: l.id == fresh ? freshT : 1,
            pulse: st == BlockState.open ? pulse : 0,
          ),
        ),
      ),
    );
  }
}

class _BlockPainter extends CustomPainter {
  _BlockPainter({
    required this.level,
    required this.state,
    required this.stars,
    required this.appear,
    required this.pulse,
  });

  final Level level;
  final BlockState state;
  final int stars;
  final double appear;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;
    final muslin = Art.texturePaint(Art.muslin, Hue.muslin, scale: 0.3);
    canvas.drawRect(rect, muslin);

    if (state == BlockState.sewn) {
      canvas.save();
      if (appear < 1) {
        final k = Curves.easeOutBack.transform(appear);
        canvas.translate(s / 2, s / 2);
        canvas.scale(0.55 + 0.45 * k);
        canvas.translate(-s / 2, -s / 2);
      }
      final fabrics = chapters[level.chapter].fabrics;
      final paints = [
        for (var i = 0; i < 3; i++)
          Art.fabricPaint(
            fabrics[(i + level.id) % fabrics.length],
            scale: 0.16,
            alpha: appear.clamp(0.0, 1.0),
          ),
      ];
      for (final (poly, slot) in _motif(level.id % _motifCount)) {
        final path = Path()..moveTo(poly.first.dx * s, poly.first.dy * s);
        for (final p in poly.skip(1)) {
          path.lineTo(p.dx * s, p.dy * s);
        }
        path.close();
        canvas.drawPath(path, slot < 0 ? muslin : paints[slot]);
      }
      canvas.restore();
      // Stars as small brass stitches in the corner.
      final star = Paint()
        ..color = Hue.brass
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < stars; i++) {
        final c = Offset(s - 6 - i * 7.0, s - 6);
        canvas.drawCircle(c, 3.2, Paint()..color = const Color(0xE6FFF8EC));
        canvas.drawLine(
          c - const Offset(1.8, 0),
          c + const Offset(1.8, 0),
          star,
        );
        canvas.drawLine(
          c - const Offset(0, 1.8),
          c + const Offset(0, 1.8),
          star,
        );
      }
    } else if (state == BlockState.open) {
      // A pinned square waiting to be sewn: dashed chalk line and a pin.
      final chalk = Paint()
        ..color = Hue.thread.withValues(alpha: 0.75)
        ..strokeWidth = 1.4;
      final r = rect.deflate(s * 0.14);
      _dashRect(canvas, r, chalk, s * 0.07);
      final head = Offset(s * 0.68, s * 0.3 - pulse * 2.5);
      canvas.drawLine(
        head,
        head + Offset(-s * 0.26, s * 0.3),
        Paint()
          ..color = const Color(0xFF9A928A)
          ..strokeWidth = 1.6,
      );
      canvas.drawCircle(
        head + const Offset(0.8, 1.6),
        s * 0.075,
        Paint()..color = const Color(0x44000000),
      );
      canvas.drawCircle(head, s * 0.075, Paint()..color = Hue.redThread);
      canvas.drawCircle(
        head - Offset(s * 0.022, s * 0.022),
        s * 0.025,
        Paint()..color = const Color(0x99FFFFFF),
      );
    } else {
      // Not yet open: the motif is only chalked onto the muslin.
      final chalk = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Hue.thread.withValues(alpha: 0.2);
      for (final (poly, slot) in _motif(level.id % _motifCount)) {
        if (slot < 0) continue;
        final path = Path()..moveTo(poly.first.dx * s, poly.first.dy * s);
        for (final p in poly.skip(1)) {
          path.lineTo(p.dx * s, p.dy * s);
        }
        canvas.drawPath(path..close(), chalk);
      }
    }
    // Seam between blocks.
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x33503A2A),
    );
  }

  void _dashRect(Canvas c, Rect r, Paint p, double d) {
    void line(Offset a, Offset b) {
      final len = (b - a).distance;
      final dir = (b - a) / len;
      for (var t = 0.0; t < len; t += d * 2) {
        c.drawLine(a + dir * t, a + dir * math.min(len, t + d), p);
      }
    }

    line(r.topLeft, r.topRight);
    line(r.topRight, r.bottomRight);
    line(r.bottomRight, r.bottomLeft);
    line(r.bottomLeft, r.topLeft);
  }

  @override
  bool shouldRepaint(_BlockPainter old) =>
      old.state != state ||
      old.stars != stars ||
      old.appear != appear ||
      old.pulse != pulse ||
      old.level.id != level.id;
}

// ---- traditional block motifs on a unit square --------------------------

typedef Poly = (List<Offset>, int);

const _motifCount = 8;

List<Poly> _sq(double x, double y, double w, double h, int slot) => [
  (
    [Offset(x, y), Offset(x + w, y), Offset(x + w, y + h), Offset(x, y + h)],
    slot,
  ),
];

/// Half-square triangle in cell (x, y, size), split on the given diagonal.
List<Poly> _hst(
  double x,
  double y,
  double s,
  int a,
  int b, {
  bool flip = false,
}) {
  final tl = Offset(x, y), tr = Offset(x + s, y);
  final bl = Offset(x, y + s), br = Offset(x + s, y + s);
  return flip
      ? [
          ([tl, tr, bl], a),
          ([tr, br, bl], b),
        ]
      : [
          ([tl, tr, br], a),
          ([tl, br, bl], b),
        ];
}

List<Poly> _motif(int k) {
  switch (k) {
    case 0: // Four patch
      return [
        ..._sq(0, 0, .5, .5, 0),
        ..._sq(.5, 0, .5, .5, -1),
        ..._sq(0, .5, .5, .5, -1),
        ..._sq(.5, .5, .5, .5, 1),
      ];
    case 1: // Nine patch
      return [
        for (var y = 0; y < 3; y++)
          for (var x = 0; x < 3; x++)
            ..._sq(
              x / 3,
              y / 3,
              1 / 3,
              1 / 3,
              (x + y).isEven ? (x == 1 ? 1 : 0) : -1,
            ),
      ];
    case 2: // Pinwheel
      return [
        ..._hst(0, 0, .5, 0, -1, flip: true),
        ..._hst(.5, 0, .5, -1, 1),
        ..._hst(0, .5, .5, 1, -1),
        ..._hst(.5, .5, .5, -1, 0, flip: true),
      ];
    case 3: // Hourglass
      return [
        ([const Offset(0, 0), const Offset(1, 0), const Offset(.5, .5)], 0),
        ([const Offset(1, 0), const Offset(1, 1), const Offset(.5, .5)], -1),
        ([const Offset(1, 1), const Offset(0, 1), const Offset(.5, .5)], 1),
        ([const Offset(0, 1), const Offset(0, 0), const Offset(.5, .5)], -1),
      ];
    case 4: // Flying geese, two rows
      return [
        for (var r = 0; r < 2; r++) ...[
          ..._sq(0, r * .5, 1, .5, -1),
          (
            [
              Offset(0, r * .5 + .5),
              Offset(.5, r * .5),
              Offset(1, r * .5 + .5),
            ],
            r,
          ),
        ],
      ];
    case 5: // Rail fence
      return [
        ..._sq(0, 0, 1, 1 / 3, 0),
        ..._sq(0, 1 / 3, 1, 1 / 3, -1),
        ..._sq(0, 2 / 3, 1, 1 / 3, 1),
      ];
    case 6: // Log cabin
      return [
        ..._sq(0, 0, 1, 1, -1),
        ..._sq(0, 0, .25, 1, 0),
        ..._sq(.25, 0, .75, .25, 0),
        ..._sq(.75, .25, .25, .75, 1),
        ..._sq(.25, .75, .5, .25, 1),
        ..._sq(.375, .375, .25, .25, 2),
      ];
    default: // Churn dash
      return [
        ..._sq(0, 0, 1, 1, -1),
        ..._hst(0, 0, 1 / 3, 0, -1, flip: true),
        ..._hst(2 / 3, 0, 1 / 3, 0, -1),
        ..._hst(0, 2 / 3, 1 / 3, -1, 0),
        ..._hst(2 / 3, 2 / 3, 1 / 3, -1, 0, flip: true),
        ..._sq(1 / 3, 0, 1 / 3, 1 / 6, 1),
        ..._sq(1 / 3, 5 / 6, 1 / 3, 1 / 6, 1),
        ..._sq(0, 1 / 3, 1 / 6, 1 / 3, 1),
        ..._sq(5 / 6, 1 / 3, 1 / 6, 1 / 3, 1),
        ..._sq(1 / 3, 1 / 3, 1 / 3, 1 / 3, 2),
      ];
  }
}
