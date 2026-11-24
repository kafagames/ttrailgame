import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/chapters.dart';
import '../data/levels.dart';
import 'ribbons.dart';

/// Everything the game remembers, on this device only.
class Store extends ChangeNotifier {
  Store._(this._p);

  static late Store instance;
  final SharedPreferences _p;

  static Future<Store> load() async {
    final p = await SharedPreferences.getInstance();
    instance = Store._(p);
    return instance;
  }

  // ---- progress ---------------------------------------------------------

  Map<int, int> get _stars {
    final raw = _p.getString('stars');
    if (raw == null) return {};
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return m.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  int stars(int levelId) => _stars[levelId] ?? 0;

  int get totalStars => _stars.values.fold(0, (a, b) => a + b);

  int get blocksSewn => _stars.values.where((s) => s > 0).length;

  int get perfectBlocks => _stars.values.where((s) => s >= 3).length;

  bool isUnlocked(int levelId) => levelId <= 1 || stars(levelId - 1) > 0;

  /// The next block to sew: the first unlocked one without stars, else the
  /// first not yet at three stars, else the last.
  int get nextLevelId {
    for (final l in allLevels) {
      if (isUnlocked(l.id) && stars(l.id) == 0) return l.id;
    }
    for (final l in allLevels) {
      if (stars(l.id) < 3) return l.id;
    }
    return allLevels.last.id;
  }

  /// Records a win. Returns ribbons newly earned.
  Future<List<Ribbon>> recordWin({
    required int levelId,
    required int stars,
    required int patches,
    required bool usedHint,
  }) async {
    final s = _stars;
    if ((s[levelId] ?? 0) < stars) s[levelId] = stars;
    await _p.setString('stars', jsonEncode(s.map((k, v) => MapEntry('$k', v))));
    await _bump('stat_bound');
    await _p.setInt('stat_sewn', statSewn + patches);
    notifyListeners();
    return _checkRibbons();
  }

  // ---- daily ------------------------------------------------------------

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String? get dailyLast => _p.getString('daily_last');
  int get dailyDone => _p.getInt('daily_done') ?? 0;
  int get bestStreak => _p.getInt('best_streak') ?? 0;

  /// Current streak, counting today or yesterday as still alive.
  int streak(DateTime today) {
    final last = dailyLast;
    if (last == null) return 0;
    final t = dayKey(today);
    final y = dayKey(today.subtract(const Duration(days: 1)));
    if (last != t && last != y) return 0;
    return _p.getInt('streak') ?? 0;
  }

  bool dailyDoneToday(DateTime today) => dailyLast == dayKey(today);

  Future<List<Ribbon>> recordDaily(DateTime today, int patches) async {
    if (dailyDoneToday(today)) return const [];
    final current = streak(today);
    final next = current + 1;
    await _p.setInt('streak', next);
    if (next > bestStreak) await _p.setInt('best_streak', next);
    await _p.setString('daily_last', dayKey(today));
    await _bump('daily_done');
    await _p.setInt('stat_sewn', statSewn + patches);
    await addHints(1);
    notifyListeners();
    return _checkRibbons();
  }

  // ---- hints ------------------------------------------------------------

  int get hints => _p.getInt('hints') ?? 3;

  Future<void> addHints(int n) async {
    await _p.setInt('hints', hints + n);
    notifyListeners();
  }

  Future<bool> spendHint() async {
    if (hints <= 0) return false;
    await _p.setInt('hints', hints - 1);
    await _bump('stat_hints');
    notifyListeners();
    return true;
  }

  // ---- stats ------------------------------------------------------------

  int get statSewn => _p.getInt('stat_sewn') ?? 0;
  int get statBound => _p.getInt('stat_bound') ?? 0;
  int get statHints => _p.getInt('stat_hints') ?? 0;

  Future<void> _bump(String key) => _p.setInt(key, (_p.getInt(key) ?? 0) + 1);

  // ---- ribbons ----------------------------------------------------------

  Set<String> get ribbons => (_p.getStringList('ribbons') ?? const []).toSet();

  Future<List<Ribbon>> _checkRibbons() async {
    final have = ribbons;
    final earned = <Ribbon>[];
    for (final r in allRibbons) {
      if (have.contains(r.id)) continue;
      if (r.test(this)) {
        have.add(r.id);
        earned.add(r);
      }
    }
    if (earned.isNotEmpty) {
      await _p.setStringList('ribbons', have.toList());
      await addHints(earned.length);
    }
    return earned;
  }

  bool chapterComplete(int chapter) => allLevels
      .where((l) => l.chapter == chapter)
      .every((l) => stars(l.id) > 0);

  // ---- one-time notes ---------------------------------------------------

  bool seenChapterNote(int chapter) => _p.getBool('note_ch$chapter') ?? false;
  Future<void> markChapterNote(int chapter) =>
      _p.setBool('note_ch$chapter', true);

  // ---- settings ---------------------------------------------------------

  bool get sound => _p.getBool('set_sound') ?? true;
  bool get music => _p.getBool('set_music') ?? true;
  bool get haptics => _p.getBool('set_haptics') ?? true;
  bool get reduceMotion => _p.getBool('set_reduce_motion') ?? false;

  Future<void> setSound(bool v) => _set('set_sound', v);
  Future<void> setMusic(bool v) => _set('set_music', v);
  Future<void> setHaptics(bool v) => _set('set_haptics', v);
  Future<void> setReduceMotion(bool v) => _set('set_reduce_motion', v);

  Future<void> _set(String k, bool v) async {
    await _p.setBool(k, v);
    notifyListeners();
  }

  String get tableCover {
    final t = _p.getString('table') ?? 'maple';
    final cover = tableCovers.where((c) => c.id == t).firstOrNull;
    if (cover == null || totalStars < cover.stars) return 'maple';
    return t;
  }

  Future<void> setTableCover(String id) async {
    await _p.setString('table', id);
    notifyListeners();
  }

  /// Wipes every saved thing (settings stay).
  Future<void> resetProgress() async {
    for (final k in _p.getKeys().toList()) {
      if (k.startsWith('set_')) continue;
      await _p.remove(k);
    }
    notifyListeners();
  }
}
