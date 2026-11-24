import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/chapters.dart';
import '../data/levels.dart';
import '../engine/board.dart';
import '../engine/generator.dart';
import '../services/sound.dart';
import '../services/store.dart';
import '../ui/glyphs.dart';
import '../ui/palette.dart';
import '../widgets/quilt.dart';
import '../widgets/stitch.dart';
import 'guide.dart';
import 'ledger.dart';
import 'play.dart';
import 'quiet_room.dart';

/// The workroom: the heirloom quilt hangs on the wall and grows a block for
/// every level won.
class HubScreen extends StatefulWidget {
  const HubScreen({super.key, this.today});

  /// Overrides the clock (tests).
  final DateTime? today;

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final AnimationController _fresh = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 1,
  );
  int? _freshId;
  int? _focusChapter;
  bool _cutting = false;

  Store get store => Store.instance;
  DateTime get today => widget.today ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!reduceMotion(context)) _pulse.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _fresh.dispose();
    super.dispose();
  }

  Future<void> _play(Level level) async {
    if (!store.isUnlocked(level.id)) {
      Sound.play(Sfx.nope);
      Sound.bump();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          _note('Sew block ${level.id - 1} first to open this one.'),
        );
      return;
    }
    final out = await Navigator.of(
      context,
    ).push<PlayOutcome>(softRoute(PlayScreen(level: level)));
    if (!mounted) return;
    final won = out?.wonLevel;
    setState(() {
      _freshId = won;
      if (won != null) _focusChapter = null;
    });
    if (won != null) {
      Sound.play(Sfx.place);
      if (reduceMotion(context)) {
        _fresh.value = 1;
      } else {
        _fresh.forward(from: 0);
      }
    }
  }

  Future<void> _daily() async {
    if (_cutting) return;
    setState(() => _cutting = true);
    final day = DateTime(today.year, today.month, today.day);
    final level = await compute(dailyLevel, day);
    if (!mounted) return;
    setState(() => _cutting = false);
    await Navigator.of(
      context,
    ).push(softRoute(PlayScreen(level: level, daily: true, today: day)));
    if (mounted) setState(() {});
  }

  SnackBar _note(String text) => SnackBar(
    content: Text(text, style: Txt.label.copyWith(color: Hue.muslin)),
    backgroundColor: Hue.walnut,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth, h = box.maxHeight;
          // Where the painted peg rail lands once the wall art is cover-fitted.
          final scale = math.max(w / 1080, h / 1920);
          final railY = (h - 1920 * scale) / 2 + (0.105 * 1920 + 26) * scale;
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset('assets/images/wall.png', fit: BoxFit.cover),
              ),
              ListenableBuilder(
                listenable: store,
                builder: (context, _) => _content(w, h, railY),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _content(double w, double h, double railY) {
    final pad = MediaQuery.of(context).padding;
    final next = allLevels.firstWhere((l) => l.id == store.nextLevelId);
    final chapterIdx = _focusChapter ?? next.chapter;
    final ch = chapters[chapterIdx];
    final inChapter = allLevels.where((l) => l.chapter == chapterIdx).toList();
    final sewn = inChapter.where((l) => store.stars(l.id) > 0).length;
    const columns = 6;
    final rows = (allLevels.length / columns).ceil();
    final quiltTop = railY + 4;
    // Leave room below for the chapter line and actions.
    final below = 210.0 + pad.bottom;
    final byW = (math.min(w, 460) - 40 - 14) / columns;
    final byH = (h - quiltTop - below - 14) / rows;
    final block = math.max(34.0, math.min(byW, byH)).floorToDouble();
    final allDone = store.blocksSewn == allLevels.length;
    final streak = store.streak(today);
    final dailyDone = store.dailyDoneToday(today);

    return Stack(
      children: [
        // Title above the rail.
        Positioned(
          left: 20,
          right: 20,
          top: pad.top + 6,
          height: math.max(28, railY - pad.top - 14),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    'Thimble Trail',
                    style: Txt.display.copyWith(fontSize: 30),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '${store.blocksSewn}/${allLevels.length} blocks',
                    style: Txt.small.copyWith(fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
        // The quilt, hanging from the rail by two tabs.
        Positioned(
          top: quiltTop,
          left: 0,
          right: 0,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([_pulse, _fresh]),
                  builder: (context, _) => HeirloomQuilt(
                    levels: allLevels,
                    blockSize: block,
                    columns: columns,
                    stateOf: (id) => store.stars(id) > 0
                        ? BlockState.sewn
                        : store.isUnlocked(id)
                        ? BlockState.open
                        : BlockState.locked,
                    starsOf: store.stars,
                    onTap: (l) {
                      setState(() => _focusChapter = l.chapter);
                      _play(l);
                    },
                    fresh: _freshId,
                    freshT: _fresh.value,
                    pulse: Curves.easeInOut.transform(_pulse.value),
                  ),
                ),
                for (final fx in [0.18, 0.82])
                  Positioned(
                    top: -14,
                    left: (block * columns + 14) * fx - 9,
                    child: Container(
                      width: 18,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Hue.binding,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Chapter line + actions on the wainscot.
        Positioned(
          left: 0,
          right: 0,
          bottom: pad.bottom + 10,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      decoration: BoxDecoration(
                        color: Hue.muslin.withValues(alpha: 0.93),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Chapter ${chapterIdx + 1} · ${ch.name}',
                              style: Txt.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$sewn of ${inChapter.length} sewn',
                            style: Txt.small,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    LabelTag(
                      leading: Image.asset(
                        'assets/images/spool.png',
                        width: 40,
                        height: 40,
                      ),
                      text: allDone
                          ? 'Polish a block'
                          : store.stars(next.id) == 0
                          ? 'Sew block ${next.id}'
                          : 'Re-sew block ${next.id}',
                      sub: next.name,
                      onTap: () => _play(next),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Hue.muslin.withValues(alpha: 0.93),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          for (final a in <Widget>[
                            QuietAction(
                              glyph: Glyph.star,
                              color: dailyDone ? Hue.thread : Hue.brassDeep,
                              label: _cutting
                                  ? 'Cutting…'
                                  : dailyDone
                                  ? 'Daily done'
                                  : 'Daily pattern',
                              badge: streak > 0 ? '$streak' : null,
                              onTap: _daily,
                            ),
                            QuietAction(
                              glyph: Glyph.ledger,
                              label: 'Ledger',
                              onTap: () => Navigator.of(
                                context,
                              ).push(softRoute(const LedgerScreen())),
                            ),
                            QuietAction(
                              glyph: Glyph.guide,
                              label: 'How to sew',
                              onTap: () => Navigator.of(
                                context,
                              ).push(softRoute(const GuideScreen())),
                            ),
                            QuietAction(
                              glyph: Glyph.spool,
                              label: 'Quiet room',
                              onTap: () async {
                                await Navigator.of(
                                  context,
                                ).push(softRoute(const QuietRoomScreen()));
                                if (mounted) setState(() {});
                              },
                            ),
                          ])
                            Expanded(child: a),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
