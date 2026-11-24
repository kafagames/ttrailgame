import 'package:flutter/material.dart';

/// Every colour has one job. See docs/DESIGN_LANGUAGE.md.
class Hue {
  /// Unsewn muslin: page and empty squares.
  static const muslin = Color(0xFFF3EADB);

  /// Shaded plaster: quiet panels, sheet backgrounds.
  static const plaster = Color(0xFFE6DACA);

  /// Walnut ink: text, icons, stitches.
  static const walnut = Color(0xFF3B2F28);

  /// Faded thread: secondary text (4.6:1 on muslin).
  static const thread = Color(0xFF6E5E51);

  /// Brass: rewards only (stars, ribbons, thimble, par met).
  static const brass = Color(0xFFB8873A);
  static const brassDeep = Color(0xFF8A6224);

  /// Red thread: the one warning colour (refused placement, seam clash).
  static const redThread = Color(0xFFA2463E);

  /// Cutting mat under the board.
  static const mat = Color(0xFF55745F);
  static const matLine = Color(0xFF7E9A86);

  /// Rose bias binding around the hub quilt.
  static const binding = Color(0xFF9E5A55);

  /// Fabric base colours, for small marks where a print would be too busy.
  static const fabrics = [
    Color(0xFFC97B76), // rose
    Color(0xFF8FAE8B), // sage
    Color(0xFF6F8DAE), // chambray
    Color(0xFFD9A646), // mustard
    Color(0xFF8E6A8F), // plum
  ];
}

class Txt {
  static const family = 'JosefinSlab';

  static const display = TextStyle(
    fontFamily: family,
    fontSize: 34,
    height: 1.05,
    fontWeight: FontWeight.w700,
    color: Hue.walnut,
    letterSpacing: -0.4,
  );

  static const title = TextStyle(
    fontFamily: family,
    fontSize: 24,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: Hue.walnut,
  );

  static const label = TextStyle(
    fontFamily: family,
    fontSize: 17,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: Hue.walnut,
  );

  static const body = TextStyle(
    fontFamily: family,
    fontSize: 17,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: Hue.walnut,
  );

  static const small = TextStyle(
    fontFamily: family,
    fontSize: 14.5,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: Hue.thread,
  );
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: Txt.family,
    scaffoldBackgroundColor: Hue.muslin,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Hue.binding,
      surface: Hue.muslin,
      primary: Hue.walnut,
      onPrimary: Hue.muslin,
      secondary: Hue.brass,
      error: Hue.redThread,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Hue.walnut,
      selectionColor: Color(0x55B8873A),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Hue.muslin : Hue.thread,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Hue.mat : Hue.plaster,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Hue.thread),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}
