import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui/palette.dart';
import '../widgets/stitch.dart';
import 'hub.dart';

/// Threading the needle: a running stitch draws across the logo, the title
/// settles, then the workroom fades in. Tap to skip.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  );
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (reduceMotion(context)) {
        _c.value = 1;
        Future.delayed(const Duration(milliseconds: 600), _go);
      } else {
        _c.forward().whenComplete(
          () => Future.delayed(const Duration(milliseconds: 350), _go),
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final a in ['wall', 'logo', 'spool', 'table_maple']) {
      precacheImage(AssetImage('assets/images/$a.png'), context);
    }
  }

  void _go() {
    if (_gone || !mounted) return;
    _gone = true;
    Navigator.of(context).pushReplacement(softRoute(const HubScreen()));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _go,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/wall.png', fit: BoxFit.cover),
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final logoIn = Curves.easeOutCubic.transform(
                  (_c.value / 0.4).clamp(0, 1),
                );
                final titleIn = Curves.easeOutCubic.transform(
                  ((_c.value - 0.45) / 0.35).clamp(0, 1),
                );
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: logoIn,
                          child: Transform.translate(
                            offset: Offset(0, (1 - logoIn) * 16),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 210,
                              height: 210,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 240,
                          height: 18,
                          child: CustomPaint(painter: _StitchLine(_c.value)),
                        ),
                        const SizedBox(height: 16),
                        Opacity(
                          opacity: titleIn,
                          child: Column(
                            children: [
                              Text(
                                'Thimble Trail',
                                style: Txt.display.copyWith(fontSize: 40),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Stitch a trail from spool to thimble',
                                style: Txt.small.copyWith(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StitchLine extends CustomPainter {
  _StitchLine(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final reach = (t / 0.8).clamp(0.0, 1.0) * size.width;
    final p = Paint()
      ..color = Hue.walnut
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    for (var x = 0.0; x < reach; x += 14) {
      final wave = math.sin(x / size.width * math.pi * 2) * 3;
      canvas.drawLine(
        Offset(x, y + wave),
        Offset(math.min(reach, x + 8), y + wave),
        p,
      );
    }
    if (reach < size.width && reach > 0) {
      // The needle leading the thread.
      final n = Paint()
        ..color = const Color(0xFF9A928A)
        ..strokeWidth = 2;
      canvas.drawLine(Offset(reach, y - 6), Offset(reach + 18, y - 10), n);
    }
  }

  @override
  bool shouldRepaint(_StitchLine old) => old.t != t;
}
