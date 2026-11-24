import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/chapters.dart';
import '../data/levels.dart';
import '../engine/board.dart';
import '../engine/solver.dart';
import '../services/ribbons.dart';
import '../services/sound.dart';
import '../services/store.dart';
import '../ui/glyphs.dart';
import '../ui/palette.dart';
import '../widgets/board_view.dart';
import '../widgets/stitch.dart';

class _TrayItem {
  _TrayItem(this.piece, [this.rotation = 0]);
  final TrayPiece piece;
  int rotation;
}

/// Result handed back to the hub when the player leaves.
class PlayOutcome {
  const PlayOutcome({this.wonLevel});
  final int? wonLevel;
}

class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    required this.level,
    this.daily = false,
    this.today,
  });
  final Level level;
  final bool daily;
  final DateTime? today;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with TickerProviderStateMixin {
  late Board _board;
  late List<_TrayItem> _tray;
  int? _selected;
  Ghost? _ghost;
  Placement? _hint;
  bool _usedHint = false;
  bool _won = false;
  String? _message;
  Timer? _messageTimer;
  bool _thinking = false;

  late final AnimationController _drop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );
  late final AnimationController _trail = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  Level get level => widget.level;
  Store get store => Store.instance;

  @override
  void initState() {
    super.initState();
    _reset();
    if (!widget.daily) {
      final first = allLevels.firstWhere((l) => l.chapter == level.chapter);
      if (first.id == level.id && !store.seenChapterNote(level.chapter)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _chapterNote());
      }
    }
  }

  void _reset() {
    _board = Board(level);
    _tray = [for (final p in level.tray) _TrayItem(p)];
    _selected = _tray.isEmpty ? null : 0;
    _ghost = null;
    _hint = null;
    _won = false;
    _trail.value = 0;
    _pulse.stop();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _drop.dispose();
    _trail.dispose();
    _pulse.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _say(String text) {
    _messageTimer?.cancel();
    setState(() => _message = text);
    _messageTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _message = null);
    });
  }

  // ---- placement --------------------------------------------------------

  /// Best placement covering [cell] for the selected patch. Tries every
  /// square of the patch as the one under the finger, middle squares first,
  /// so a tap "near enough" still lands.
  (Placement, PlaceProblem?)? _candidate((int, int) cell) {
    final s = _selected;
    if (s == null) return null;
    final item = _tray[s];
    final cells = item.piece.shape.cellsFor(item.rotation);
    final cx = cells.map((c) => c.$1).reduce((a, b) => a + b) / cells.length;
    final cy = cells.map((c) => c.$2).reduce((a, b) => a + b) / cells.length;
    final order = List.of(cells)
      ..sort((a, b) {
        final da = (a.$1 - cx).abs() + (a.$2 - cy).abs();
        final db = (b.$1 - cx).abs() + (b.$2 - cy).abs();
        return da.compareTo(db);
      });
    (Placement, PlaceProblem?)? first;
    for (final c in order) {
      final p = Placement(
        item.piece,
        item.rotation,
        cell.$1 - c.$1,
        cell.$2 - c.$2,
      );
      final problem = _board.check(p.piece, p.rotation, p.x, p.y);
      if (problem == null) return (p, null);
      first ??= (p, problem);
    }
    return first;
  }

  void _aim((int, int)? cell) {
    if (_won) return;
    if (cell == null ||
        _selected == null ||
        _board.owner[_board.index(cell.$1, cell.$2)] >= 0) {
      if (_ghost != null) setState(() => _ghost = null);
      return;
    }
    final c = _candidate(cell);
    setState(() => _ghost = c == null ? null : Ghost(c.$1, c.$2 == null));
  }

  void _commit((int, int) cell) {
    if (_won) return;
    final i = _board.index(cell.$1, cell.$2);
    if (_board.owner[i] >= 0) {
      _unpickAt(i);
      return;
    }
    if (_selected == null) {
      if (_tray.isEmpty) {
        _say('Every patch is down. Tap a patch on the quilt to unpick it.');
      } else {
        _say('Pick a patch from the tray first.');
      }
      return;
    }
    final c = _candidate(cell);
    if (c == null) return;
    final (p, problem) = c;
    if (problem != null) {
      Sound.play(Sfx.nope);
      Sound.bump();
      if (!reduceMotion(context)) _shake.forward(from: 0);
      _say(switch (problem) {
        PlaceProblem.seam =>
          'Matching seams: same fabrics can\'t touch side by side.',
        PlaceProblem.offEdge => 'That patch would hang off the quilt.',
        PlaceProblem.covered => 'No room for that patch there. Try turning it.',
      });
      return;
    }
    _board.place(p.piece, p.rotation, p.x, p.y);
    _tray.removeAt(_selected!);
    _selected = _tray.isEmpty ? null : math.min(_selected!, _tray.length - 1);
    if (_hint != null &&
        (_hint!.x != p.x || _hint!.y != p.y || _hint!.piece != p.piece)) {
      // Player went their own way; the hint no longer applies.
    }
    _hint = null;
    _pulse.stop();
    Sound.play(Sfx.place);
    Sound.tick();
    if (reduceMotion(context)) {
      _drop.value = 1;
    } else {
      _drop.forward(from: 0);
    }
    setState(() {
      _ghost = null;
      _message = null;
    });
    if (_board.isBound) {
      _win();
    } else if (_tray.isEmpty) {
      _say(
        'Every patch is down but the trail is open. Unpick one and try another way.',
      );
    }
  }

  void _unpickAt(int i) {
    final p = _board.unpickAt(i);
    if (p == null) return;
    _tray.add(_TrayItem(p.piece, p.rotation));
    _selected = _tray.length - 1;
    Sound.play(Sfx.unpick);
    Sound.tick();
    setState(() {
      _hint = null;
      _ghost = null;
    });
  }

  void _unpickLast() {
    if (_board.placements.isEmpty || _won) return;
    final p = _board.placements.last;
    final (x, y) = p.cells.first;
    _unpickAt(_board.index(x, y));
  }

  void _turn() {
    final s = _selected;
    if (s == null || _won) return;
    setState(() {
      _tray[s].rotation =
          (_tray[s].rotation + 1) % _tray[s].piece.shape.rotationCount;
      _hint = null;
    });
    Sound.play(Sfx.turn);
    Sound.tick();
  }

  void _select(int index) {
    if (_won) return;
    if (_selected == index) {
      _turn();
      return;
    }
    Sound.play(Sfx.pick);
    Sound.tick();
    setState(() {
      _selected = index;
      _hint = null;
    });
  }

  void _restart() {
    Sound.play(Sfx.unpick);
    setState(_reset);
  }

  // ---- hints ------------------------------------------------------------

  Future<void> _askHint() async {
    if (_won || _thinking) return;
    if (store.hints <= 0) {
      _say('No hints left. Ribbons and the Pattern of the Day each give one.');
      Sound.play(Sfx.nope);
      return;
    }
    setState(() => _thinking = true);
    final res = await compute(_solveFrom, (
      level,
      List<Placement>.of(_board.placements),
      [for (final t in _tray) t.piece],
    ));
    if (!mounted) return;
    setState(() => _thinking = false);
    final moves = res;
    if (moves == null || moves.isEmpty) {
      _say('This layout can\'t close. Unpick a patch and look again.');
      Sound.play(Sfx.nope);
      return;
    }
    await store.spendHint();
    if (!mounted) return;
    final first = moves.first;
    final idx = _tray.indexWhere((t) => t.piece == first.piece);
    setState(() {
      _usedHint = true;
      _hint = first;
      if (idx >= 0) {
        _selected = idx;
        _tray[idx].rotation = first.rotation;
      }
    });
    Sound.play(Sfx.hint);
    if (!reduceMotion(context)) _pulse.repeat();
    _say(
      'Lay the ${first.piece.fabric.label.toLowerCase()} ${first.piece.shape.label} patch on the brass outline.',
    );
  }

  // ---- winning ----------------------------------------------------------

  Future<void> _win() async {
    setState(() => _won = true);
    Sound.play(Sfx.bound);
    Sound.thud();
    if (reduceMotion(context)) {
      _trail.value = 1;
    } else {
      await _trail.forward(from: 0);
    }
    if (!mounted) return;
    final used = _board.placements.length;
    final stars = starsFor(bound: true, used: used, par: level.par);
    List<Ribbon> ribbons;
    var streak = 0;
    if (widget.daily) {
      final today = widget.today ?? DateTime.now();
      ribbons = await store.recordDaily(today, used);
      streak = store.streak(today);
    } else {
      ribbons = await store.recordWin(
        levelId: level.id,
        stars: stars,
        patches: used,
        usedHint: _usedHint,
      );
    }
    if (!mounted) return;
    for (var i = 0; i < ribbons.length; i++) {
      Future.delayed(
        Duration(milliseconds: 1400 + i * 300),
        () => Sound.play(Sfx.ribbon),
      );
    }
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x66301A0C),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, _, _) => _ResultSheet(
        level: level,
        daily: widget.daily,
        stars: stars,
        used: used,
        ribbons: ribbons,
        streak: streak,
        onNext: _nextLevel,
        onAgain: () {
          Navigator.of(context).pop();
          _restart();
        },
        onQuilt: () {
          Navigator.of(context).pop();
          Navigator.of(
            context,
          ).pop(PlayOutcome(wonLevel: widget.daily ? null : level.id));
        },
      ),
      transitionBuilder: (context, a, _, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: c,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(c),
            child: child,
          ),
        );
      },
    );
  }

  Level? get _next {
    if (widget.daily) return null;
    final i = allLevels.indexWhere((l) => l.id == level.id);
    return i + 1 < allLevels.length ? allLevels[i + 1] : null;
  }

  void _nextLevel() {
    final n = _next;
    Navigator.of(context).pop();
    if (n == null) return;
    Navigator.of(context).pushReplacement(softRoute(PlayScreen(level: n)));
  }

  // ---- pause ------------------------------------------------------------

  Future<void> _leave() async {
    if (_board.placements.isEmpty || _won) {
      Navigator.of(context).pop(const PlayOutcome());
      return;
    }
    final choice = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Keep sewing',
      barrierColor: const Color(0x55301A0C),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, _, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Material(
              type: MaterialType.transparency,
              child: PatternSheet(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Set your work down?', style: Txt.title),
                    const SizedBox(height: 6),
                    Text(
                      'Patches on the table are not kept if you leave.',
                      style: Txt.body,
                    ),
                    const SizedBox(height: 20),
                    LabelTag(
                      text: 'Keep sewing',
                      onTap: () => Navigator.of(context).pop('stay'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        QuietAction(
                          glyph: Glyph.restart,
                          label: 'Start over',
                          onTap: () => Navigator.of(context).pop('restart'),
                        ),
                        const SizedBox(width: 12),
                        QuietAction(
                          glyph: Glyph.back,
                          label: 'Back to the quilt',
                          onTap: () => Navigator.of(context).pop('leave'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    );
    if (!mounted) return;
    if (choice == 'restart') _restart();
    if (choice == 'leave') Navigator.of(context).pop(const PlayOutcome());
  }

  Future<void> _chapterNote() async {
    final ch = chapters[level.chapter];
    await store.markChapterNote(level.chapter);
    if (!mounted) return;
    Sound.play(Sfx.ribbon);
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Begin',
      barrierColor: const Color(0x55301A0C),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Material(
              type: MaterialType.transparency,
              child: PatternSheet(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chapter ${level.chapter + 1}', style: Txt.small),
                    Text(ch.name, style: Txt.display.copyWith(fontSize: 30)),
                    const SizedBox(height: 10),
                    Text(ch.note, style: Txt.body),
                    const SizedBox(height: 20),
                    LabelTag(
                      text: 'Begin',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    );
  }

  // ---- build ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final buttonsJoined = _board.buttons.isEmpty
        ? 0
        : _board.buttons.where(_board.spoolComponent().contains).length;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/table_${store.tableCover}.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _header(),
                _rules(buttonsJoined),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _drop,
                        _trail,
                        _pulse,
                        _shake,
                      ]),
                      builder: (context, _) {
                        final dx =
                            math.sin(_shake.value * math.pi * 6) *
                            7 *
                            (1 - _shake.value);
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: BoardView(
                            board: _board,
                            ghost: _ghost,
                            hint: _hint,
                            hintPulse: _pulse.value,
                            drop: Curves.easeOutBack.transform(_drop.value),
                            trail: _trail.value,
                            onAim: _aim,
                            onCommit: _commit,
                            semanticsLabel: _boardLabel(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                _messageLine(),
                _trayCloth(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _boardLabel() {
    final buf = StringBuffer('Quilt ${level.width} by ${level.height}. ');
    buf.write(_board.isBound ? 'Bound. ' : 'Trail open. ');
    buf.write('${_board.placements.length} patches sewn.');
    return buf.toString();
  }

  Widget _header() {
    final title = widget.daily ? 'Pattern of the Day' : level.name;
    final sub = widget.daily
        ? Store.dayKey(widget.today ?? DateTime.now())
        : 'Block ${level.id} of ${allLevels.length} · ${chapters[level.chapter].name}';
    return Container(
      color: Hue.muslin.withValues(alpha: 0.94),
      padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
      child: Row(
        children: [
          Press(
            label: 'Leave this block',
            onTap: _leave,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Center(child: GlyphIcon(Glyph.back, size: 26)),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Txt.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sub,
                  style: Txt.small,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: store,
            builder: (context, _) => QuietAction(
              glyph: Glyph.needle,
              label: _thinking ? 'Looking…' : 'Hint',
              badge: '${store.hints}',
              onTap: _won ? null : _askHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rules(int buttonsJoined) {
    final used = _board.placements.length;
    final chips = <Widget>[
      _Chip(text: 'Par ${level.par}', strong: true),
      _Chip(text: 'Sewn $used', warn: used > level.par),
      if (level.seams) const _Chip(text: 'Matching seams'),
      if (_board.buttons.isNotEmpty)
        _Chip(text: 'Buttons $buttonsJoined/${_board.buttons.length}'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Wrap(spacing: 8, runSpacing: 6, children: chips),
    );
  }

  Widget _messageLine() {
    return SizedBox(
      height: 44,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _message == null
            ? const SizedBox.shrink()
            : Padding(
                key: ValueKey(_message),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Hue.muslin.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _message!,
                    style: Txt.small.copyWith(color: Hue.walnut),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _trayCloth() {
    return CustomPaint(
      painter: _TrayClothPainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 104,
              child: _tray.isEmpty
                  ? Center(child: Text('The tray is empty.', style: Txt.small))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: _tray.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, i) => _trayPiece(i),
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final a in <Widget>[
                  QuietAction(
                    glyph: Glyph.turn,
                    label: 'Turn',
                    onTap: _selected == null || _won ? null : _turn,
                  ),
                  QuietAction(
                    glyph: Glyph.unpick,
                    label: 'Unpick last',
                    onTap: _board.placements.isEmpty || _won
                        ? null
                        : _unpickLast,
                  ),
                  QuietAction(
                    glyph: Glyph.restart,
                    label: 'Start over',
                    onTap: _board.placements.isEmpty || _won ? null : _restart,
                  ),
                ])
                  Expanded(child: a),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _trayPiece(int i) {
    final item = _tray[i];
    final sel = i == _selected;
    final cells = item.piece.shape.cellsFor(item.rotation);
    // One scale for every patch so sizes compare truthfully.
    final wCells = cells.fold<int>(0, (m, c) => math.max(m, c.$1)) + 1;
    const cell = 24.0;
    return Press(
      label:
          '${item.piece.fabric.label} ${item.piece.shape.label} patch'
          '${sel ? ', selected, tap to turn' : ''}',
      sfx: Sfx.pick,
      onTap: () => _select(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: math.max(84.0, wCells * cell + 24),
        padding: EdgeInsets.only(bottom: sel ? 14 : 4),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedRotation(
              turns: 0,
              duration: const Duration(milliseconds: 150),
              child: PatchSwatch(
                piece: item.piece,
                rotation: item.rotation,
                cell: cell,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              width: sel ? 44 : 0,
              decoration: BoxDecoration(
                color: Hue.brass,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Placement>? _solveFrom((Level, List<Placement>, List<TrayPiece>) args) {
  final (level, placed, tray) = args;
  final b = Board(level);
  for (final p in placed) {
    b.place(p.piece, p.rotation, p.x, p.y);
  }
  final res = Solver(b, tray, nodeBudget: 250000).solve();
  return res.moves;
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.strong = false, this.warn = false});
  final String text;
  final bool strong;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: strong ? Hue.walnut : Hue.muslin.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: Txt.small.copyWith(
          color: strong ? Hue.muslin : (warn ? Hue.redThread : Hue.walnut),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TrayClothPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height + 40);
    canvas.drawRect(
      r.shift(const Offset(0, -4)),
      Paint()
        ..color = const Color(0x44301A0C)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRect(r, Paint()..color = Hue.muslin);
    final p = Paint()
      ..color = Hue.thread.withValues(alpha: 0.5)
      ..strokeWidth = 1.3;
    for (var x = 6.0; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, 6), Offset(x + 6, 6), p);
    }
  }

  @override
  bool shouldRepaint(_TrayClothPainter old) => false;
}

class _ResultSheet extends StatefulWidget {
  const _ResultSheet({
    required this.level,
    required this.daily,
    required this.stars,
    required this.used,
    required this.ribbons,
    required this.streak,
    required this.onNext,
    required this.onAgain,
    required this.onQuilt,
  });

  final Level level;
  final bool daily;
  final int stars;
  final int used;
  final List<Ribbon> ribbons;
  final int streak;
  final VoidCallback onNext;
  final VoidCallback onAgain;
  final VoidCallback onQuilt;

  @override
  State<_ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<_ResultSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.daily) {
      for (var i = 0; i < widget.stars; i++) {
        Future.delayed(Duration(milliseconds: 350 + i * 260), () {
          if (mounted) Sound.play(Sfx.star);
        });
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (reduceMotion(context)) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.level;
    final isLast = !widget.daily && l.id == allLevels.last.id;
    final nextExists = !widget.daily && !isLast;
    final patches = widget.used == 1 ? '1 patch' : '${widget.used} patches';
    final parLine = widget.used <= l.par
        ? 'Sewn with $patches. Right on par.'
        : 'Sewn with $patches. Par is ${l.par}.';
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Material(
            type: MaterialType.transparency,
            child: PatternSheet(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.daily ? 'Today\'s pattern is bound' : 'Quilt bound',
                    style: Txt.small,
                  ),
                  Text(
                    widget.daily ? 'Pattern of the Day' : l.name,
                    style: Txt.display.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 14),
                  if (!widget.daily)
                    AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) => Row(
                        children: [
                          for (var i = 0; i < 3; i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _starAt(i),
                            ),
                        ],
                      ),
                    ),
                  if (widget.daily)
                    Text(
                      'Streak: ${widget.streak} ${widget.streak == 1 ? 'day' : 'days'} · +1 hint',
                      style: Txt.label.copyWith(color: Hue.brassDeep),
                    ),
                  const SizedBox(height: 10),
                  Text(parLine, style: Txt.body),
                  if (isLast) ...[
                    const SizedBox(height: 6),
                    Text(
                      'That was the last block. The heirloom quilt is finished.',
                      style: Txt.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                  for (final r in widget.ribbons) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const GlyphIcon(Glyph.star, size: 20, color: Hue.brass),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ribbon: ${r.name} · +1 hint',
                            style: Txt.label.copyWith(color: Hue.brassDeep),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (nextExists)
                    LabelTag(
                      text: 'Next block',
                      sub: allLevels[allLevels.indexOf(l) + 1].name,
                      onTap: widget.onNext,
                    )
                  else
                    LabelTag(text: 'Back to the quilt', onTap: widget.onQuilt),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (nextExists)
                        QuietAction(
                          glyph: Glyph.back,
                          label: 'The quilt',
                          onTap: widget.onQuilt,
                        ),
                      if (!widget.daily)
                        QuietAction(
                          glyph: Glyph.restart,
                          label: 'Sew again',
                          onTap: widget.onAgain,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _starAt(int i) {
    final start = 0.2 + i * 0.22;
    final t = ((_c.value - start) / 0.3).clamp(0.0, 1.0);
    final earned = i < widget.stars;
    final k = earned ? Curves.elasticOut.transform(t) : 1.0;
    return Semantics(
      label: earned ? 'Star earned' : 'Star not earned',
      child: Transform.scale(
        scale: earned ? 0.4 + 0.6 * k : 1,
        child: GlyphIcon(
          Glyph.star,
          size: 40,
          color: earned && t > 0 ? Hue.brass : Hue.plaster,
        ),
      ),
    );
  }
}
