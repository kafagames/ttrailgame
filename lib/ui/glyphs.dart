import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'palette.dart';

/// The game's own icon set: one 2.2 px walnut stroke, round caps, drawn on a
/// 24-unit grid. No stock icon font.
enum Glyph {
  back,
  needle,
  unpick,
  turn,
  restart,
  spool,
  ledger,
  guide,
  star,
  lock,
  close,
}

class GlyphIcon extends StatelessWidget {
  const GlyphIcon(
    this.glyph, {
    super.key,
    this.size = 24,
    this.color = Hue.walnut,
  });
  final Glyph glyph;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _GlyphPainter(glyph, color),
  );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color);
  final Glyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    canvas.scale(k);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    switch (glyph) {
      case Glyph.back:
        canvas.drawPath(
          Path()
            ..moveTo(14.5, 5)
            ..lineTo(7.5, 12)
            ..lineTo(14.5, 19),
          p,
        );
      case Glyph.close:
        canvas.drawLine(const Offset(6, 6), const Offset(18, 18), p);
        canvas.drawLine(const Offset(18, 6), const Offset(6, 18), p);
      case Glyph.needle:
        // A diagonal needle with its eye and a curl of thread.
        canvas.drawLine(const Offset(5, 19), const Offset(18, 6), p);
        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(18.6, 5.4),
            width: 3.4,
            height: 5.2,
          ).shift(Offset.zero),
          p..strokeWidth = 1.6,
        );
        p.strokeWidth = 1.6;
        canvas.drawPath(
          Path()
            ..moveTo(19.5, 7)
            ..quadraticBezierTo(22, 13, 15, 15)
            ..quadraticBezierTo(9, 17, 11, 21),
          p,
        );
      case Glyph.unpick:
        // Seam ripper: a fork with a ball tip.
        canvas.drawLine(const Offset(4, 20), const Offset(12, 12), p);
        canvas.drawPath(
          Path()
            ..moveTo(12, 12)
            ..lineTo(19, 5)
            ..moveTo(12, 12)
            ..quadraticBezierTo(17, 12, 19.5, 9.5),
          p,
        );
        canvas.drawCircle(const Offset(19.5, 9.5), 1.7, fill);
      case Glyph.turn:
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(12, 12.5), radius: 7),
          -math.pi * 0.95,
          math.pi * 1.55,
          false,
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(3.6, 6.5)
            ..lineTo(5.2, 11.2)
            ..lineTo(9.8, 9.2),
          p,
        );
      case Glyph.restart:
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(12, 12), radius: 7),
          -math.pi * 0.35,
          math.pi * 1.7,
          false,
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(18.5, 3.8)
            ..lineTo(18.4, 8.6)
            ..lineTo(13.7, 8.2),
          p,
        );
      case Glyph.spool:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5, 3.5, 14, 3),
            const Radius.circular(1.2),
          ),
          p,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5, 17.5, 14, 3),
            const Radius.circular(1.2),
          ),
          p,
        );
        for (var y = 9.0; y <= 15; y += 3) {
          canvas.drawLine(
            Offset(8, y),
            Offset(16, y + 0.8),
            p..strokeWidth = 1.6,
          );
        }
      case Glyph.ledger:
        p.strokeWidth = 2.0;
        canvas.drawPath(
          Path()
            ..moveTo(12, 6)
            ..quadraticBezierTo(8, 4, 3.5, 5)
            ..lineTo(3.5, 19)
            ..quadraticBezierTo(8, 18, 12, 20)
            ..quadraticBezierTo(16, 18, 20.5, 19)
            ..lineTo(20.5, 5)
            ..quadraticBezierTo(16, 4, 12, 6)
            ..lineTo(12, 20),
          p,
        );
      case Glyph.guide:
        // A paper pattern with a dashed cut line.
        p.strokeWidth = 2.0;
        canvas.drawPath(
          Path()
            ..moveTo(5, 3.5)
            ..lineTo(15, 3.5)
            ..lineTo(19, 7.5)
            ..lineTo(19, 20.5)
            ..lineTo(5, 20.5)
            ..close(),
          p,
        );
        p.strokeWidth = 1.6;
        for (var x = 8.0; x < 16; x += 3.2) {
          canvas.drawLine(Offset(x, 14), Offset(x + 1.6, 14), p);
        }
        canvas.drawLine(const Offset(8, 10), const Offset(13, 10), p);
      case Glyph.star:
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final r = i.isEven ? 9.5 : 4.2;
          final a = -math.pi / 2 + i * math.pi / 5;
          final o = Offset(12 + r * math.cos(a), 12.5 + r * math.sin(a));
          i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
        }
        path.close();
        canvas.drawPath(path, fill);
      case Glyph.lock:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5.5, 10.5, 13, 9.5),
            const Radius.circular(2),
          ),
          p,
        );
        canvas.drawArc(
          const Rect.fromLTWH(8.5, 4, 7, 11),
          math.pi,
          math.pi,
          false,
          p,
        );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}
