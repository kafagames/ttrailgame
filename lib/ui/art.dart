import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'package:flutter/services.dart';

import 'palette.dart';

/// Decoded images used by the painters. Loaded once at start-up.
class Art {
  static final List<ui.Image?> fabrics = List.filled(5, null);
  static ui.Image? muslin;
  static ui.Image? batting;
  static ui.Image? spool;
  static ui.Image? thimble;
  static ui.Image? button;

  static const _fabricNames = ['rose', 'sage', 'chambray', 'mustard', 'plum'];

  static Future<void> load() async {
    Future<ui.Image?> img(String name) async {
      try {
        final data = await rootBundle.load('assets/images/$name.png');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        return (await codec.getNextFrame()).image;
      } catch (_) {
        return null;
      }
    }

    for (var i = 0; i < 5; i++) {
      fabrics[i] = await img('fabric_${_fabricNames[i]}');
    }
    muslin = await img('muslin');
    batting = await img('batting');
    spool = await img('spool');
    thimble = await img('thimble');
    button = await img('button');
  }

  /// A paint that fills with a fabric print. [scale] is screen pixels per
  /// texture pixel; prints stay the same size whatever the board size.
  static Paint fabricPaint(
    int fabric, {
    double scale = 0.42,
    double alpha = 1,
  }) {
    final image = fabrics[fabric % 5];
    final p = Paint()..isAntiAlias = true;
    if (image == null) {
      p.color = Hue.fabrics[fabric % 5].withValues(alpha: alpha);
      return p;
    }
    p.shader = ui.ImageShader(
      image,
      ui.TileMode.repeated,
      ui.TileMode.repeated,
      Float64List.fromList([
        scale,
        0,
        0,
        0,
        0,
        scale,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        1,
      ]),
    );
    if (alpha < 1) {
      p.colorFilter = ui.ColorFilter.mode(
        Color.fromRGBO(255, 255, 255, alpha),
        ui.BlendMode.modulate,
      );
    }
    return p;
  }

  static Paint texturePaint(
    ui.Image? image,
    Color fallback, {
    double scale = 0.5,
  }) {
    final p = Paint()..isAntiAlias = true;
    if (image == null) return p..color = fallback;
    p.shader = ui.ImageShader(
      image,
      ui.TileMode.repeated,
      ui.TileMode.repeated,
      Float64List.fromList([
        scale,
        0,
        0,
        0,
        0,
        scale,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        1,
      ]),
    );
    return p;
  }

  /// Draws a sprite to fill [dst] keeping aspect.
  static void sprite(ui.Canvas c, ui.Image? image, Rect dst) {
    if (image == null) return;
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    c.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }
}
