import 'package:flutter_test/flutter_test.dart';
import 'package:thimble_trail/data/levels.dart';
import 'package:thimble_trail/services/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Store store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await Store.load();
  });

  test('fresh start: block 1 open, 3 hints, defaults on', () {
    expect(store.isUnlocked(1), isTrue);
    expect(store.isUnlocked(2), isFalse);
    expect(store.nextLevelId, 1);
    expect(store.hints, 3);
    expect(store.sound && store.music && store.haptics, isTrue);
    expect(store.reduceMotion, isFalse);
    expect(store.tableCover, 'maple');
  });

  test('wins unlock the next block and keep the best stars', () async {
    final ribbons = await store.recordWin(
      levelId: 1,
      stars: 2,
      patches: 2,
      usedHint: false,
    );
    expect(ribbons.map((r) => r.id), contains('first'));
    expect(store.hints, 4, reason: 'ribbon gives a hint');
    expect(store.isUnlocked(2), isTrue);
    expect(store.nextLevelId, 2);
    await store.recordWin(levelId: 1, stars: 1, patches: 3, usedHint: false);
    expect(store.stars(1), 2);
    await store.recordWin(levelId: 1, stars: 3, patches: 1, usedHint: false);
    expect(store.stars(1), 3);
    expect(store.statBound, 3);
    expect(store.statSewn, 6);
  });

  test('chapter ribbon when a chapter is finished', () async {
    final ch0 = allLevels.where((l) => l.chapter == 0).toList();
    var got = <String>[];
    for (final l in ch0) {
      got = (await store.recordWin(
        levelId: l.id,
        stars: 3,
        patches: l.par,
        usedHint: false,
      )).map((r) => r.id).toList();
    }
    expect(got, contains('chapter0'));
    expect(store.chapterComplete(0), isTrue);
    expect(store.chapterComplete(1), isFalse);
  });

  test('daily streak counts consecutive days and breaks on a gap', () async {
    final d1 = DateTime(2026, 11, 10);
    await store.recordDaily(d1, 3);
    expect(store.streak(d1), 1);
    expect(store.dailyDoneToday(d1), isTrue);
    // Same day again changes nothing.
    await store.recordDaily(d1, 3);
    expect(store.dailyDone, 1);
    final d2 = DateTime(2026, 11, 11);
    expect(store.streak(d2), 1, reason: 'yesterday still counts');
    await store.recordDaily(d2, 3);
    expect(store.streak(d2), 2);
    final d4 = DateTime(2026, 11, 13);
    expect(store.streak(d4), 0, reason: 'a missed day breaks it');
    await store.recordDaily(d4, 3);
    expect(store.streak(d4), 1);
    expect(store.bestStreak, 2);
  });

  test('hints spend down to zero', () async {
    expect(await store.spendHint(), isTrue);
    expect(await store.spendHint(), isTrue);
    expect(await store.spendHint(), isTrue);
    expect(await store.spendHint(), isFalse);
    expect(store.statHints, 3);
  });

  test('locked table covers fall back to maple', () async {
    await store.setTableCover('indigo');
    expect(store.tableCover, 'maple');
  });

  test('reset clears progress but keeps settings', () async {
    await store.setSound(false);
    await store.recordWin(levelId: 1, stars: 3, patches: 1, usedHint: false);
    await store.resetProgress();
    expect(store.stars(1), 0);
    expect(store.ribbons, isEmpty);
    expect(store.hints, 3);
    expect(store.sound, isFalse);
  });
}
