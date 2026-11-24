import 'package:flutter/material.dart';

import '../data/chapters.dart';
import '../services/sound.dart';
import '../services/store.dart';
import '../ui/palette.dart';
import '../widgets/stitch.dart';
import 'privacy.dart';

/// Sound, motion and table cover choices; privacy; reset.
class QuietRoomScreen extends StatelessWidget {
  const QuietRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Store.instance;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) => Column(
            children: [
              const ScreenHeader(title: 'Quiet room'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: [
                    _toggle(
                      'Sound effects',
                      'Pins, thread and chimes',
                      store.sound,
                      store.setSound,
                    ),
                    _toggle(
                      'Music box',
                      'A slow tune while you sew',
                      store.music,
                      (v) async {
                        await store.setMusic(v);
                        await Sound.syncMusic();
                      },
                    ),
                    _toggle(
                      'Vibration',
                      'A light tap as patches land',
                      store.haptics,
                      store.setHaptics,
                    ),
                    _toggle(
                      'Reduce motion',
                      'Calmer animations everywhere',
                      store.reduceMotion,
                      store.setReduceMotion,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Table cover',
                      style: Txt.title.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Earn stars to open new covers for the cutting table.',
                      style: Txt.small,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                        clipBehavior: Clip.none,
                        itemCount: tableCovers.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) =>
                            _cover(context, tableCovers[i]),
                      ),
                    ),
                    const SizedBox(height: 26),
                    _link(
                      context,
                      'Our promise',
                      'What this game keeps, and where',
                      () => Navigator.of(
                        context,
                      ).push(softRoute(const PrivacyScreen())),
                    ),
                    _link(
                      context,
                      'Unpick everything',
                      'Clear stars, ribbons, streak and hints',
                      () => _confirmReset(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggle(
    String title,
    String sub,
    bool value,
    Future<void> Function(bool) set,
  ) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Txt.label),
                  Text(sub, style: Txt.small),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (v) {
                Sound.tick();
                set(v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover(BuildContext context, TableCover c) {
    final store = Store.instance;
    final open = store.totalStars >= c.stars;
    final chosen = store.tableCover == c.id;
    return Press(
      label: open
          ? '${c.name}${chosen ? ', in use' : ''}'
          : '${c.name}, opens at ${c.stars} stars',
      onTap: open ? () => store.setTableCover(c.id) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: DecorationImage(
                image: AssetImage('assets/images/table_${c.id}.png'),
                fit: BoxFit.cover,
              ),
              boxShadow: chosen
                  ? const [BoxShadow(color: Hue.brass, spreadRadius: 3)]
                  : const [
                      BoxShadow(
                        color: Color(0x33301A0C),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
            ),
          ),
          const SizedBox(height: 6),
          Text(c.name, style: Txt.small.copyWith(color: Hue.walnut)),
          Text(
            open ? (chosen ? 'In use' : 'Ready') : '${c.stars} stars',
            style: Txt.small.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _link(
    BuildContext context,
    String title,
    String sub,
    VoidCallback onTap,
  ) {
    return Press(
      label: title,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Txt.label),
                  Text(sub, style: Txt.small),
                ],
              ),
            ),
            const Text('›', style: TextStyle(fontSize: 26, color: Hue.thread)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: PatternSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Unpick everything?', style: Txt.title),
              const SizedBox(height: 8),
              Text(
                'Every sewn block, star, ribbon, streak and hint on this device will be cleared. This cannot be undone.',
                style: Txt.body,
              ),
              const SizedBox(height: 18),
              LabelTag(
                text: 'Keep my quilt',
                onTap: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(height: 8),
              Press(
                label: 'Yes, unpick everything',
                onTap: () => Navigator.of(context).pop(true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 4,
                  ),
                  child: Text(
                    'Yes, unpick everything',
                    style: Txt.label.copyWith(color: Hue.redThread),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (yes == true) {
      await Store.instance.resetProgress();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'The quilt is back to plain muslin.',
              style: Txt.label.copyWith(color: Hue.muslin),
            ),
            backgroundColor: Hue.walnut,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
