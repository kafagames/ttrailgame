// Generates lib/data/levels.dart: 48 solver-proven quilt blocks in five
// chapters. Run from the project root:  dart run tool/generate_levels.dart
import 'dart:io';

import 'package:thimble_trail/engine/board.dart';
import 'package:thimble_trail/engine/generator.dart';
import 'package:thimble_trail/engine/shapes.dart';
import 'package:thimble_trail/engine/solver.dart';

const names = [
  // First Stitches
  'Rail Fence', 'Four Patch', 'Shoofly', 'Hourglass', 'Bow Tie', 'Nine Patch',
  // Turning Corners
  'Churn Dash', 'Pinwheel', 'Log Cabin', 'Flying Geese', 'Garden Path',
  'Sawtooth Star', 'Monkey Wrench', 'Friendship Star', 'Jacob\'s Ladder',
  'Courthouse Steps',
  // Buttons
  'Button Box', 'Spool Block', 'Bear\'s Paw', 'Ohio Star', 'Weathervane',
  'Maple Leaf', 'Basket Weave', 'Corn and Beans', 'Spider Web',
  // Matching Seams
  'Winding Ways', 'Dutchman\'s Puzzle', 'Broken Dishes', 'Snail\'s Trail',
  'Storm at Sea', 'Lone Star', 'Kansas Troubles', 'Tumbling Blocks',
  'Wild Goose Chase', 'Windmill', 'Hens and Chicks', "Cat's Cradle",
  // The Heirloom
  'Grandmother\'s Fan',
  'Dresden Plate',
  'Carpenter\'s Wheel',
  'Delectable Mountains',
  'Orange Peel', 'Hole in the Barn Door', 'Bachelor\'s Puzzle',
  'Road to California', 'Morning Star', 'Feathered Star',
  'Double Wedding Ring',
];

typedef Plan = ({int chapter, GenSpec spec});

List<Plan> buildPlan() {
  final out = <Plan>[];
  void add(int ch, GenSpec s) => out.add((chapter: ch, spec: s));
  const r = PatchShape.rail, c = PatchShape.corner, sn = PatchShape.snip;
  const b = PatchShape.block, t = PatchShape.tee, st = PatchShape.step;

  // Chapter 1 — First Stitches (6): levels 1–2 are hand-made below.
  for (var i = 0; i < 4; i++) {
    add(
      0,
      GenSpec(
        width: 5,
        height: 5,
        shapes: const [r, sn],
        minPar: i < 2 ? 2 : 3,
        maxPar: 3,
        fabrics: 2,
        decoys: i < 2 ? 1 : 2,
        batting: 0.6,
        wander: 0.4,
        waypoints: i < 2 ? 0 : 1,
      ),
    );
  }
  // Chapter 2 — Turning Corners (10)
  for (var i = 0; i < 10; i++) {
    add(
      1,
      GenSpec(
        width: 6,
        height: 6,
        shapes: i < 4 ? const [r, c, sn] : const [r, c, sn, b],
        minPar: 3 + i ~/ 4,
        maxPar: 4 + i ~/ 4,
        fabrics: 3,
        decoys: 2,
        batting: 0.72,
        wander: 0.5,
        waypoints: 1,
      ),
    );
  }
  // Chapter 3 — Buttons (9)
  for (var i = 0; i < 9; i++) {
    add(
      2,
      GenSpec(
        width: i < 4 ? 6 : 7,
        height: i < 4 ? 6 : 7,
        shapes: i < 3 ? const [r, c, sn] : const [r, c, b, t],
        minPar: 4 + i ~/ 4,
        maxPar: 5 + i ~/ 4,
        fabrics: 3,
        decoys: 2,
        buttons: i < 4 ? 1 : 2,
        batting: 0.65,
        wander: 0.5,
      ),
    );
  }
  // Chapter 4 — Matching Seams (12)
  for (var i = 0; i < 12; i++) {
    add(
      3,
      GenSpec(
        width: i < 4 ? 6 : 7,
        height: i < 4 ? 6 : 7,
        shapes: i < 6 ? const [r, c, sn, b] : const [r, c, t, st],
        minPar: 4 + i ~/ 5,
        maxPar: 5 + i ~/ 5,
        fabrics: i < 8 ? 3 : 2,
        decoys: 2,
        seams: true,
        fixedPieces: i < 3 ? 0 : 1,
        batting: 0.72,
        wander: 0.6,
        waypoints: i < 6 ? 1 : 2,
      ),
    );
  }
  // Chapter 5 — The Heirloom (11), last one is the finale.
  for (var i = 0; i < 11; i++) {
    final finale = i == 10;
    add(
      4,
      GenSpec(
        width: finale ? 8 : (i < 5 ? 7 : 8),
        height: finale ? 8 : 7,
        shapes: const [r, c, b, t, st, sn],
        minPar: finale ? 7 : 5 + i ~/ 4,
        maxPar: finale ? 9 : 6 + i ~/ 4,
        fabrics: 3,
        decoys: finale ? 3 : 2,
        buttons: finale ? 2 : (i.isEven ? 1 : 0),
        seams: finale || i.isOdd,
        fixedPieces: 1,
        batting: 0.72,
        wander: 0.7,
        waypoints: finale ? 2 : 1 + i % 2,
        nodeBudget: 200000,
      ),
    );
  }
  return out;
}

const handMade = [
  Level(
    id: 1,
    name: 'Rail Fence',
    chapter: 0,
    rows: ['#####', '#####', 'S...T', '#####', '#####'],
    tray: [TrayPiece(PatchShape.rail, Fabric.rose)],
    par: 1,
  ),
  Level(
    id: 2,
    name: 'Four Patch',
    chapter: 0,
    rows: ['#####', 'S...#', '#.#.#', '#.#.T', '#####'],
    tray: [
      TrayPiece(PatchShape.rail, Fabric.sage),
      TrayPiece(PatchShape.rail, Fabric.rose),
      TrayPiece(PatchShape.snip, Fabric.sage),
    ],
    par: 2,
  ),
];

String lit(Level l) {
  final rows = l.rows.map((r) => "      '$r',").join('\n');
  final tray = l.tray
      .map(
        (p) =>
            '      TrayPiece(PatchShape.${p.shape.name}, Fabric.${p.fabric.name}),',
      )
      .join('\n');
  final esc = l.name.replaceAll("'", "\\'");
  return '''  Level(
    id: ${l.id},
    name: '$esc',
    chapter: ${l.chapter},
    par: ${l.par},${l.seams ? '\n    seams: true,' : ''}
    rows: [
$rows
    ],
    tray: [
$tray
    ],
  ),''';
}

void main() {
  final levels = <Level>[...handMade];
  final plan = buildPlan();
  var id = handMade.length + 1;
  for (final p in plan) {
    final sw = Stopwatch()..start();
    Level? lv;
    for (var salt = 0; lv == null && salt < 40; salt++) {
      final relax = salt ~/ 10;
      final s = p.spec;
      final spec = GenSpec(
        width: s.width,
        height: s.height,
        shapes: s.shapes,
        minPar: s.minPar - relax,
        maxPar: s.maxPar + relax,
        fabrics: s.fabrics,
        decoys: s.decoys,
        buttons: s.buttons,
        fixedPieces: s.fixedPieces,
        seams: s.seams,
        batting: s.batting,
        wander: s.wander,
        waypoints: relax > 2 ? 0 : s.waypoints,
        nodeBudget: s.nodeBudget,
      );
      lv = LevelGenerator(id * 7919 + salt * 104729).generate(
        spec,
        id: id,
        name: names[id - 1],
        chapter: p.chapter,
        attempts: 12,
      );
    }
    for (var salt = 0; lv == null && salt < 30; salt++) {
      // Fallback: same size and shapes, simpler rules.
      final s = p.spec;
      lv = LevelGenerator(id * 31337 + salt).generate(
        GenSpec(
          width: s.width,
          height: s.height,
          shapes: s.shapes,
          minPar: s.minPar - 1 - salt ~/ 10,
          maxPar: s.maxPar + 1,
          fabrics: s.fabrics,
          decoys: s.decoys,
          seams: s.seams,
          batting: s.batting,
          wander: s.wander,
          waypoints: 1,
          nodeBudget: s.nodeBudget,
        ),
        id: id,
        name: names[id - 1],
        chapter: p.chapter,
        attempts: 12,
      );
    }
    if (lv == null) {
      stderr.writeln('FAILED level $id');
      exit(1);
    }
    final check = solveLevel(lv);
    stdout.writeln(
      'level $id ch${p.chapter} ${lv.width}x${lv.height} '
      'par ${lv.par} tray ${lv.tray.length} nodes ${check.nodes} '
      '(${sw.elapsedMilliseconds} ms)',
    );
    levels.add(lv);
    id++;
  }
  for (final l in handMade) {
    final res = solveLevel(l);
    if (res.length != l.par) {
      stderr.writeln('hand level ${l.id} par ${res.length} != ${l.par}');
      exit(1);
    }
  }
  final buf = StringBuffer()
    ..writeln(
      '// GENERATED by tool/generate_levels.dart — do not edit by hand.',
    )
    ..writeln(
      '// Every par below is the solver-proven minimum; see test/levels_test.dart.',
    )
    ..writeln("import '../engine/board.dart';")
    ..writeln("import '../engine/shapes.dart';")
    ..writeln()
    ..writeln('const allLevels = <Level>[');
  for (final l in levels) {
    buf.writeln(lit(l));
  }
  buf.writeln('];');
  File('lib/data/levels.dart').writeAsStringSync(buf.toString());
  stdout.writeln('wrote ${levels.length} levels');
}
