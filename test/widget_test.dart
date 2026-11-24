import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thimble_trail/data/levels.dart';
import 'package:thimble_trail/main.dart';
import 'package:thimble_trail/screens/guide.dart';
import 'package:thimble_trail/screens/hub.dart';
import 'package:thimble_trail/screens/play.dart';
import 'package:thimble_trail/screens/privacy.dart';
import 'package:thimble_trail/screens/quiet_room.dart';
import 'package:thimble_trail/services/sound.dart';
import 'package:thimble_trail/services/store.dart';
import 'package:thimble_trail/widgets/board_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps frames for [d] without waiting for looping animations to settle.
Future<void> pumpFor(WidgetTester t, Duration d) async {
  final end = d.inMilliseconds;
  for (var ms = 0; ms < end; ms += 16) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

Future<void> setPhone(WidgetTester t) async {
  t.view.physicalSize = const Size(1080, 2340);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

/// Taps square (x, y) of the board on screen.
Future<void> tapCell(WidgetTester t, int x, int y) async {
  final board = t.widget<BoardView>(find.byType(BoardView)).board;
  final paint = find
      .descendant(
        of: find.byType(BoardView),
        matching: find.byType(CustomPaint),
      )
      .first;
  final box = t.getRect(paint);
  const margin = 12.0;
  final cell = (box.width - margin * 2) / board.width;
  await t.tapAt(
    box.topLeft + Offset(margin + (x + 0.5) * cell, margin + (y + 0.5) * cell),
  );
  await t.pump();
}

Future<void> loadFonts() async {
  final loader = FontLoader('JosefinSlab');
  for (final w in ['Regular', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/JosefinSlab-$w.ttf'));
  }
  await loader.load();
}

void main() {
  setUpAll(loadFonts);
  setUp(() async {
    Sound.enabled = false;
    SharedPreferences.setMockInitialValues({'set_reduce_motion': true});
    await Store.load();
  });

  testWidgets('hub shows the quilt and the next block', (t) async {
    await setPhone(t);
    await t.pumpWidget(
      ThimbleTrailApp(home: HubScreen(today: DateTime(2026, 11, 12))),
    );
    await pumpFor(t, const Duration(milliseconds: 300));
    expect(find.text('Thimble Trail'), findsOneWidget);
    expect(find.text('Sew block 1'), findsOneWidget);
    expect(find.text('Chapter 1 · First Stitches'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Block 1, Rail Fence, ready to sew')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Block 2, not yet open')),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('sew block 1 from the hub and see it bound', (t) async {
    await setPhone(t);
    await t.pumpWidget(
      ThimbleTrailApp(home: HubScreen(today: DateTime(2026, 11, 12))),
    );
    await pumpFor(t, const Duration(milliseconds: 200));
    await t.tap(find.text('Sew block 1'));
    await pumpFor(t, const Duration(milliseconds: 500));
    // First block of a chapter shows its note once.
    expect(find.text('First Stitches'), findsWidgets);
    await t.tap(find.text('Begin'));
    await pumpFor(t, const Duration(milliseconds: 400));
    expect(find.byType(PlayScreen), findsOneWidget);
    expect(find.text('Par 1'), findsOneWidget);

    await tapCell(t, 2, 2);
    await pumpFor(t, const Duration(milliseconds: 600));
    expect(find.text('Quilt bound'), findsOneWidget);
    expect(find.text('Sewn with 1 patch. Right on par.'), findsOneWidget);
    expect(Store.instance.stars(1), 3);
    expect(Store.instance.isUnlocked(2), isTrue);

    await t.tap(find.text('The quilt'));
    await pumpFor(t, const Duration(milliseconds: 600));
    expect(find.byType(HubScreen), findsOneWidget);
    expect(find.text('Sew block 2'), findsOneWidget);
    expect(t.takeException(), isNull);
    await pumpFor(t, const Duration(seconds: 2));
  });

  testWidgets('refused placement explains itself, unpick returns the patch', (
    t,
  ) async {
    await setPhone(t);
    await Store.instance.markChapterNote(0);
    await t.pumpWidget(ThimbleTrailApp(home: PlayScreen(level: allLevels[1])));
    await pumpFor(t, const Duration(milliseconds: 300));
    // Batting square at the top-left corner.
    await tapCell(t, 0, 0);
    await pumpFor(t, const Duration(milliseconds: 100));
    expect(find.textContaining(RegExp('[Tt]hat patch')), findsOneWidget);

    // Lay the first rail on the top row, then unpick it.
    await tapCell(t, 2, 1);
    await pumpFor(t, const Duration(milliseconds: 300));
    expect(find.text('Sewn 1'), findsOneWidget);
    await tapCell(t, 2, 1);
    await pumpFor(t, const Duration(milliseconds: 300));
    expect(find.text('Sewn 0'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('quiet room, guide and promise screens open', (t) async {
    await setPhone(t);
    await t.pumpWidget(const ThimbleTrailApp(home: QuietRoomScreen()));
    await pumpFor(t, const Duration(milliseconds: 200));
    expect(find.text('Music box'), findsOneWidget);
    await t.tap(find.text('Our promise'));
    await pumpFor(t, const Duration(milliseconds: 500));
    expect(find.byType(PrivacyScreen), findsOneWidget);
    expect(
      find.text('We collect no data, and you never need an account.'),
      findsOneWidget,
    );

    await t.pumpWidget(ThimbleTrailApp(key: UniqueKey(), home: const GuideScreen()));
    await pumpFor(t, const Duration(milliseconds: 200));
    expect(find.text('How to sew'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('reset asks first', (t) async {
    await setPhone(t);
    await Store.instance.recordWin(
      levelId: 1,
      stars: 3,
      patches: 1,
      usedHint: false,
    );
    await t.pumpWidget(const ThimbleTrailApp(home: QuietRoomScreen()));
    await pumpFor(t, const Duration(milliseconds: 200));
    await t.tap(find.text('Unpick everything'));
    await pumpFor(t, const Duration(milliseconds: 300));
    await t.tap(find.text('Keep my quilt'));
    await pumpFor(t, const Duration(milliseconds: 300));
    expect(Store.instance.stars(1), 3);
    await t.tap(find.text('Unpick everything'));
    await pumpFor(t, const Duration(milliseconds: 300));
    await t.tap(find.text('Yes, unpick everything'));
    await pumpFor(t, const Duration(milliseconds: 300));
    expect(Store.instance.stars(1), 0);
  });
}
