import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/sound.dart';
import '../services/store.dart';
import '../ui/glyphs.dart';
import '../ui/palette.dart';

bool reduceMotion(BuildContext context) =>
    Store.instance.reduceMotion || MediaQuery.of(context).disableAnimations;

/// Squash on press, settle on release.
class Press extends StatefulWidget {
  const Press({
    super.key,
    required this.child,
    required this.onTap,
    this.label,
    this.sfx = Sfx.tap,
  });
  final Widget child;
  final VoidCallback? onTap;
  final String? label;
  final Sfx sfx;

  @override
  State<Press> createState() => _PressState();
}

class _PressState extends State<Press> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                Sound.play(widget.sfx);
                Sound.tick();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.94 : 1,
          duration: Duration(milliseconds: _down ? 70 : 220),
          curve: _down ? Curves.easeOut : Curves.elasticOut,
          child: Opacity(opacity: enabled ? 1 : 0.45, child: widget.child),
        ),
      ),
    );
  }
}

/// The primary action: a sewn-in fabric label in walnut, muslin lettering.
class LabelTag extends StatelessWidget {
  const LabelTag({
    super.key,
    required this.text,
    this.sub,
    required this.onTap,
    this.leading,
  });
  final String text;
  final String? sub;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: onTap,
      label: sub == null ? text : '$text, $sub',
      child: CustomPaint(
        painter: _TagPainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 24, 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 14)],
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      style: Txt.title.copyWith(
                        color: Hue.muslin,
                        fontSize: 22,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sub != null)
                      Text(
                        sub!,
                        style: Txt.small.copyWith(
                          color: const Color(0xFFE2D3BE),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(4),
    );
    canvas.drawRRect(
      r.shift(const Offset(0, 5)),
      Paint()
        ..color = const Color(0x66301A0C)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawRRect(r, Paint()..color = Hue.walnut);
    final p = Paint()
      ..color = const Color(0x99E8D9C2)
      ..strokeWidth = 1.4;
    final inner = (Offset.zero & size).deflate(6);
    dashRect(canvas, inner, p, 5);
  }

  @override
  bool shouldRepaint(_TagPainter old) => false;
}

void dashRect(Canvas c, Rect r, Paint p, double d) {
  void line(Offset a, Offset b) {
    final len = (b - a).distance;
    if (len == 0) return;
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

/// Icon over a short label, no box. At least 48 dp tall and wide.
class QuietAction extends StatelessWidget {
  const QuietAction({
    super.key,
    required this.glyph,
    required this.label,
    required this.onTap,
    this.color = Hue.walnut,
    this.badge,
  });
  final Glyph glyph;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: onTap,
      label: badge == null ? label : '$label, $badge',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GlyphIcon(glyph, size: 26, color: color),
                  if (badge != null)
                    Positioned(
                      right: -12,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Hue.brass,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge!,
                          style: Txt.small.copyWith(
                            color: Hue.walnut,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: Txt.small.copyWith(color: color, fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A sheet of pattern paper with a stitched edge, for overlays.
class PatternSheet extends StatelessWidget {
  const PatternSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 26, 24, 22),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SheetPainter(),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _SheetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(6),
    );
    canvas.drawRRect(
      r.shift(const Offset(0, 8)),
      Paint()
        ..color = const Color(0x55301A0C)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawRRect(r, Paint()..color = const Color(0xFFFBF5EA));
    dashRect(
      canvas,
      (Offset.zero & size).deflate(9),
      Paint()
        ..color = Hue.thread.withValues(alpha: 0.4)
        ..strokeWidth = 1.2,
      5,
    );
  }

  @override
  bool shouldRepaint(_SheetPainter old) => false;
}

/// Header row used on the quieter screens: back glyph + title.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.onBack});
  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
      child: Row(
        children: [
          Press(
            label: 'Back',
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Center(child: GlyphIcon(Glyph.back, size: 26)),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: Txt.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fades and lifts a route in.
Route<T> softRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 320),
  reverseTransitionDuration: const Duration(milliseconds: 220),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (context, a, _, child) {
    if (reduceMotion(context)) return FadeTransition(opacity: a, child: child);
    final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: c,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(c),
        child: child,
      ),
    );
  },
);
