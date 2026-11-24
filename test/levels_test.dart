import 'package:flutter_test/flutter_test.dart';
import 'package:thimble_trail/data/chapters.dart';
import 'package:thimble_trail/data/levels.dart';
import 'package:thimble_trail/engine/board.dart';
import 'package:thimble_trail/engine/generator.dart';
import 'package:thimble_trail/engine/solver.dart';

void main() {
  test('48 blocks in five chapters, ids in order, names unique', () {
    expect(allLevels.length, 48);
    for (var i = 0; i < allLevels.length; i++) {
      expect(allLevels[i].id, i + 1);
    }
    expect(allLevels.map((l) => l.name).toSet().length, 48);
    final sizes = [
      for (var c = 0; c < chapters.length; c++)
        allLevels.where((l) => l.chapter == c).length,
    ];
    expect(sizes, [6, 10, 9, 12, 11]);
  });

  test('every grid is well formed', () {
    for (final l in allLevels) {
      expect(
        l.rows.every((r) => r.length == l.width),
        isTrue,
        reason: 'level ${l.id}',
      );
      final all = l.rows.join();
      expect('S'.allMatches(all).length, 1, reason: 'level ${l.id} spool');
      expect('T'.allMatches(all).length, 1, reason: 'level ${l.id} thimble');
      expect(
        RegExp(r'^[.#STo1-5]+$').hasMatch(all),
        isTrue,
        reason: 'level ${l.id}',
      );
      expect(l.tray.length, greaterThanOrEqualTo(l.par));
    }
  });

  test('chapter rules appear where the chapters say', () {
    for (final l in allLevels) {
      final hasButtons = l.rows.join().contains('o');
      if (l.chapter < 2) expect(hasButtons, isFalse, reason: 'level ${l.id}');
      if (l.chapter < 3) expect(l.seams, isFalse, reason: 'level ${l.id}');
      if (l.chapter == 2) expect(hasButtons, isTrue, reason: 'level ${l.id}');
      if (l.chapter == 3) expect(l.seams, isTrue, reason: 'level ${l.id}');
    }
  });

  test('every par is the true minimum (solver-proved)', () {
    for (final l in allLevels) {
      final res = solveLevel(l);
      expect(res.solved, isTrue, reason: 'level ${l.id} unsolvable');
      expect(res.length, l.par, reason: 'level ${l.id} par');
      // Replaying the solution really binds the quilt.
      final b = Board(l);
      for (final m in res.moves!) {
        expect(b.canPlace(m.piece, m.rotation, m.x, m.y), isTrue);
        b.place(m.piece, m.rotation, m.x, m.y);
      }
      expect(b.isBound, isTrue, reason: 'level ${l.id}');
    }
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('difficulty climbs across chapters', () {
    double avg(int c) {
      final ls = allLevels.where((l) => l.chapter == c).toList();
      return ls.fold<int>(0, (a, l) => a + l.par) / ls.length;
    }

    expect(avg(0), lessThan(avg(2)));
    expect(avg(1), lessThan(avg(4)));
    expect(allLevels.last.par, greaterThanOrEqualTo(allLevels.first.par + 3));
    final last = allLevels.last;
    expect(last.width * last.height, greaterThanOrEqualTo(56));
  });

  test('daily pattern is stable per date and solvable at par', () {
    final day = DateTime(2026, 11, 12);
    final a = dailyLevel(day);
    final b = dailyLevel(day);
    expect(a.rows, b.rows);
    expect(a.tray.toString(), b.tray.toString());
    expect(solveLevel(a).length, a.par);
    final other = dailyLevel(DateTime(2026, 11, 13));
    expect(
      other.rows.join() == a.rows.join() &&
          other.tray.toString() == a.tray.toString(),
      isFalse,
    );
  });

  test('a month of dailies all solve at their par', () {
    for (var d = 1; d <= 30; d++) {
      final l = dailyLevel(DateTime(2026, 12, d));
      expect(solveLevel(l).length, l.par, reason: 'day $d');
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
