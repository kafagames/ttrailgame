import 'package:flutter_test/flutter_test.dart';
import 'package:thimble_trail/engine/board.dart';
import 'package:thimble_trail/engine/shapes.dart';
import 'package:thimble_trail/engine/solver.dart';

Level lv(List<String> rows, List<TrayPiece> tray, {bool seams = false}) =>
    Level(
      id: 0,
      name: 't',
      chapter: 0,
      rows: rows,
      tray: tray,
      par: 0,
      seams: seams,
    );

const rose = Fabric.rose, sage = Fabric.sage;

void main() {
  group('shapes', () {
    test('distinct rotations', () {
      expect(PatchShape.snip.rotationCount, 2);
      expect(PatchShape.rail.rotationCount, 2);
      expect(PatchShape.corner.rotationCount, 4);
      expect(PatchShape.block.rotationCount, 1);
      expect(PatchShape.tee.rotationCount, 4);
      expect(PatchShape.step.rotationCount, 2);
    });

    test('rotations are normalised and keep size', () {
      for (final s in PatchShape.values) {
        for (var r = 0; r < s.rotationCount; r++) {
          final cells = s.cellsFor(r);
          expect(cells.length, s.size);
          expect(cells.map((c) => c.$1).reduce((a, b) => a < b ? a : b), 0);
          expect(cells.map((c) => c.$2).reduce((a, b) => a < b ? a : b), 0);
        }
      }
    });
  });

  group('board', () {
    test('rail joins spool to thimble', () {
      final b = Board(lv(['S...T'], const []));
      expect(b.isBound, isFalse);
      const rail = TrayPiece(PatchShape.rail, rose);
      expect(b.canPlace(rail, 0, 1, 0), isTrue);
      b.place(rail, 0, 1, 0);
      expect(b.isBound, isTrue);
      expect(b.trail().length, 5);
    });

    test('batting, edges and overlaps refuse placement', () {
      final b = Board(lv(['S.#...'], const []));
      const rail = TrayPiece(PatchShape.rail, rose);
      expect(b.check(rail, 0, 1, 0), PlaceProblem.covered);
      expect(b.check(rail, 0, 4, 0), PlaceProblem.offEdge);
      expect(b.check(rail, 1, 1, 0), PlaceProblem.offEdge);
      expect(b.check(rail, 0, 3, 0), isNull);
    });

    test('unpick restores squares and owners', () {
      final b = Board(lv(['S.....T'], const []));
      const snip = TrayPiece(PatchShape.snip, rose);
      b.place(snip, 0, 1, 0);
      b.place(snip, 0, 3, 0);
      final removed = b.unpickAt(b.index(1, 0));
      expect(removed?.x, 1);
      expect(b.owner[b.index(1, 0)], -1);
      expect(b.owner[b.index(3, 0)], 0);
      expect(b.placements.length, 1);
    });

    test('buttons must be covered and joined', () {
      final b = Board(lv(['S...T', '##o##'], const []));
      b.place(const TrayPiece(PatchShape.rail, rose), 0, 1, 0);
      expect(b.spoolComponent().contains(b.thimble), isTrue);
      expect(b.isBound, isFalse, reason: 'button still bare');
      b.unpickLast();
      b.place(const TrayPiece(PatchShape.tee, rose), 0, 1, 0);
      expect(b.isBound, isTrue);
    });

    test('pre-sewn squares count as trail', () {
      final b = Board(lv(['S..11..T'], const []));
      b.place(const TrayPiece(PatchShape.snip, sage), 0, 1, 0);
      expect(b.isBound, isFalse);
      b.place(const TrayPiece(PatchShape.snip, sage), 0, 5, 0);
      expect(b.isBound, isTrue);
    });

    test('matching seams forbid same fabric touching', () {
      final b = Board(lv(['S....T'], const [], seams: true));
      b.place(const TrayPiece(PatchShape.snip, rose), 0, 1, 0);
      expect(
        b.check(const TrayPiece(PatchShape.snip, rose), 0, 3, 0),
        PlaceProblem.seam,
      );
      expect(b.check(const TrayPiece(PatchShape.snip, sage), 0, 3, 0), isNull);
    });

    test('seams also apply against pre-sewn fabric', () {
      final b = Board(lv(['S.1.T'], const [], seams: true));
      expect(
        b.check(const TrayPiece(PatchShape.snip, rose), 0, 0, 0),
        PlaceProblem.covered,
      );
      final b2 = Board(lv(['S..1T'], const [], seams: true));
      expect(
        b2.check(const TrayPiece(PatchShape.snip, rose), 0, 1, 0),
        PlaceProblem.seam,
      );
      expect(b2.check(const TrayPiece(PatchShape.snip, sage), 0, 1, 0), isNull);
    });
  });

  group('stars', () {
    test('par rule', () {
      expect(starsFor(bound: false, used: 1, par: 3), 0);
      expect(starsFor(bound: true, used: 3, par: 3), 3);
      expect(starsFor(bound: true, used: 4, par: 3), 2);
      expect(starsFor(bound: true, used: 6, par: 3), 1);
    });
  });

  group('solver', () {
    test('finds the fewest patches, ignoring decoys', () {
      final level = lv(
        ['S.....T'],
        const [
          TrayPiece(PatchShape.snip, rose),
          TrayPiece(PatchShape.snip, sage),
          TrayPiece(PatchShape.rail, rose),
          TrayPiece(PatchShape.rail, sage),
          TrayPiece(PatchShape.block, rose),
        ],
      );
      final res = solveLevel(level);
      expect(res.length, 2);
      final b = Board(level);
      for (final m in res.moves!) {
        b.place(m.piece, m.rotation, m.x, m.y);
      }
      expect(b.isBound, isTrue);
    });

    test('reports no solution when the tray cannot reach', () {
      final res = solveLevel(
        lv(['S.....T'], const [TrayPiece(PatchShape.rail, rose)]),
      );
      expect(res.solved, isFalse);
    });

    test('solves from a partly sewn board', () {
      final level = lv(
        ['S.....T'],
        const [
          TrayPiece(PatchShape.rail, rose),
          TrayPiece(PatchShape.snip, sage),
        ],
      );
      final b = Board(level);
      b.place(const TrayPiece(PatchShape.rail, rose), 0, 1, 0);
      final res = Solver(b, const [TrayPiece(PatchShape.snip, sage)]).solve();
      expect(res.length, 1);
      expect(res.moves!.single.x, 4);
    });
  });
}
