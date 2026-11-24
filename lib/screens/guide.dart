import 'package:flutter/material.dart';

import '../engine/board.dart';
import '../engine/shapes.dart';
import '../services/sound.dart';
import '../services/store.dart';
import '../ui/palette.dart';
import '../widgets/board_view.dart';
import '../widgets/stitch.dart';

/// How to sew: a tiny quilt to try, then the three rules with examples.
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  static const _demo = Level(
    id: 0,
    name: 'Practice',
    chapter: 0,
    rows: ['#####', 'S...T', '#####'],
    tray: [TrayPiece(PatchShape.rail, Fabric.rose)],
    par: 1,
  );

  final Board _board = Board(_demo);
  Ghost? _ghost;
  int _rotation = 1; // starts upright so the player has to turn it

  void _aim((int, int)? c) {
    if (c == null || _board.isBound) {
      setState(() => _ghost = null);
      return;
    }
    const piece = TrayPiece(PatchShape.rail, Fabric.rose);
    setState(
      () => _ghost = Ghost(
        _bestAt(c, piece),
        _board.canPlace(
          piece,
          _rotation,
          _bestAt(c, piece).x,
          _bestAt(c, piece).y,
        ),
      ),
    );
  }

  Placement _bestAt((int, int) c, TrayPiece piece) {
    final cells = piece.shape.cellsFor(_rotation);
    final mid = cells[cells.length ~/ 2];
    return Placement(piece, _rotation, c.$1 - mid.$1, c.$2 - mid.$2);
  }

  void _commit((int, int) c) {
    final i = _board.index(c.$1, c.$2);
    if (_board.owner[i] >= 0) {
      _board.unpickAt(i);
      Sound.play(Sfx.unpick);
      setState(() {});
      return;
    }
    if (_board.placements.isNotEmpty) return;
    const piece = TrayPiece(PatchShape.rail, Fabric.rose);
    final p = _bestAt(c, piece);
    if (!_board.canPlace(piece, p.rotation, p.x, p.y)) {
      Sound.play(Sfx.nope);
      return;
    }
    _board.place(piece, p.rotation, p.x, p.y);
    Sound.play(_board.isBound ? Sfx.bound : Sfx.place);
    setState(() => _ghost = null);
  }

  @override
  Widget build(BuildContext context) {
    final bound = _board.isBound;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'How to sew'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Text(
                    'Join the spool to the thimble with fabric patches.',
                    style: Txt.body,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 150,
                    child: BoardView(
                      board: _board,
                      ghost: _ghost,
                      onAim: _aim,
                      onCommit: _commit,
                      trail: bound ? 1 : 0,
                      semanticsLabel:
                          'Practice quilt, ${bound ? 'bound' : 'trail open'}',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Press(
                        label: 'Rail patch, tap to turn',
                        sfx: Sfx.turn,
                        onTap: _board.placements.isEmpty
                            ? () => setState(
                                () => _rotation = (_rotation + 1) % 2,
                              )
                            : null,
                        child: SizedBox(
                          width: 92,
                          height: 92,
                          child: Center(
                            child: PatchSwatch(
                              piece: const TrayPiece(
                                PatchShape.rail,
                                Fabric.rose,
                              ),
                              rotation: _rotation,
                              cell: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          bound
                              ? 'Bound. Tap the patch to unpick it again.'
                              : _rotation == 1
                              ? 'Tap the patch to turn it, then tap the gap on the quilt.'
                              : 'Now tap the gap. Drag to see where it lands.',
                          style: Txt.label.copyWith(
                            color: bound ? Hue.brassDeep : Hue.walnut,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _rule(
                    'Fewer patches, more stars',
                    'Every block has a par: the fewest patches that can bind it. Bind at par for three stars, one over for two. The tray often holds spare patches you do not need.',
                  ),
                  _rule(
                    'Unpick freely',
                    'Tap any patch you laid to put it back in the tray. Unpicking and starting over never cost anything.',
                  ),
                  _rule(
                    'Buttons',
                    'From chapter three, buttons must be covered by fabric and joined to the same trail.',
                  ),
                  _example(
                    const Level(
                      id: 0,
                      name: 'Buttons',
                      chapter: 0,
                      rows: ['S...T', '##o##'],
                      tray: [],
                      par: 0,
                    ),
                  ),
                  _rule(
                    'Matching seams',
                    'On some quilts, two patches of the same fabric may never share an edge. The red thread shows a clash.',
                  ),
                  _rule(
                    'Hints',
                    'A hint outlines one patch of a best route. You start with three; ribbons and each Pattern of the Day give one more.',
                  ),
                  _rule(
                    'Pattern of the Day',
                    'A fresh quilt cut from today\'s date, the same for everyone, playable offline. Sew one each day to keep your streak.',
                  ),
                  const SizedBox(height: 8),
                  Text('Hints left: ${Store.instance.hints}', style: Txt.small),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rule(String title, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Txt.title.copyWith(fontSize: 20)),
        const SizedBox(height: 4),
        Text(text, style: Txt.body),
      ],
    ),
  );

  Widget _example(Level l) {
    final b = Board(l);
    b.place(const TrayPiece(PatchShape.tee, Fabric.sage), 0, 1, 0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: SizedBox(
        height: 110,
        child: ExcludeSemantics(child: BoardView(board: b, trail: 1)),
      ),
    );
  }
}
